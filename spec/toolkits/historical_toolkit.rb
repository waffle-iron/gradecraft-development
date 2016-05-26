RSpec.shared_examples "a historical model" do |fixture, updated_attributes|
  let(:model) { build fixture }

  describe "versioning", versioning: true do
    before { model.save }

    it "is enabled for a #{fixture}" do
      expect(PaperTrail).to be_enabled
      expect(model).to be_versioned
    end

    it "creates a version when the #{fixture} is created" do
      expect(model.versions.count).to eq 1
    end
  end

  describe "#has_history?", versioning: true do
    it "returns false if there is no history" do
      expect(model).to_not have_history
    end

    it "returns true if there is history" do
      model.save
      expect(model).to have_history
    end
  end

  describe "#history", versioning: true do
    let(:user) { create :user }

    before do
      PaperTrail.whodunnit = user.id
      model.save
    end

    subject { model.history }

    it "only contains the one event" do
      expect(subject.length).to eq 1
    end

    context "the changeset for the #{fixture}" do
      subject { model.history.first.changeset }

      it "includes a created at date" do
        expect(subject.keys).to include("created_at")
      end

      it "includes the class name" do
        expect(subject).to include({ "object" => described_class.name })
      end

      it "includes the event" do
        expect(subject).to include({ "event" => "create" })
      end

      it "includes the actor id" do
        expect(subject).to include({ "actor_id" => user.id.to_s })
      end

      it "includes the timestamp of when the changeset occured" do
        expect(subject).to include({ "recorded_at" => model.versions.last.created_at })
      end
    end

    context "with an updated changeset" do
      let!(:changes) { model.previous_changes }
      subject { model.history }

      before { model.update_attributes updated_attributes }

      it "contains the updated event" do
        expect(subject.length).to eq 2
      end

      context "the changeset for the #{fixture}" do
        subject { model.history.first.changeset }

        it "returns the changesets for an updated #{fixture}" do
          updated_attributes.each do |key, value|
            change = changes[key].nil? ? nil : changes[key].last
            expect(subject).to include({ key.to_s => [change, value] })
          end
        end

        it "includes the class name" do
          expect(subject).to include({ "object" => described_class.name })
        end

        it "includes the event" do
          expect(subject).to include({ "event" => "update" })
        end

        it "includes the actor id" do
          expect(subject).to include({ "actor_id" => user.id.to_s })
        end

        it "includes the timestamp of when the changeset occured" do
          expect(subject).to include({ "recorded_at" => model.versions.last.created_at })
        end
      end
    end

    it "orders the changesets so the newest changes are at the top" do
      model.update_attributes updated_attributes
      expect(model.history.length).to eq 2
      expect(model.history.first.changeset["event"]).to eq "update"
      expect(model.history.last.changeset["event"]).to eq "create"
    end
  end

  describe "#historical_merge", versioning: true do
    let(:another_model) { build fixture }

    it "merges history with 2 histories for 2 creation events" do
      model.save
      another_model.save

      history = model.historical_merge(another_model).history

      expect(history.length).to eq 2
      expect(history.first.changeset["id"].last).to eq another_model.id
      expect(history.last.changeset["id"].last).to eq model.id
    end
  end

  describe "#historical_collection_merge", versioning: true do
    let(:historical_collection) { [build(fixture), build(fixture)] }

    it "merges history for all the historical models in the collection" do
      model.save
      historical_collection.each(&:save)

      history = model.historical_collection_merge(historical_collection).history

      expect(history.length).to eq 3
    end
  end

  describe "#squish_history!", versioning: true do
    let(:updated_at) { 2.days.from_now }

    before do
      model.save
      model.update_attributes updated_attributes
      model.update_attribute :updated_at, updated_at
    end

    it "deletes the previous version" do
      expect(model.versions.count).to eq 3
      model.squish_history!
      expect(model.versions.count).to eq 2
    end

    it "merges with the previous object changes" do
      model.squish_history!
      changes = model.reload.versions.last.changeset
      expect(changes["updated_at"].last).to eq updated_at
    end

    it "merges with the previous object" do
      model.squish_history!
      object = PaperTrail.serializer.load(model.reload.versions.last.object)
      expect(object["updated_at"]).to eq updated_at
      expect(object.keys).to include *updated_attributes.stringify_keys.keys
    end

    it "does not merge if the previous timestamp is greater than the limit" do
      expect { model.reload.squish_history!(1) }.to_not \
        change { PaperTrail::Version.count }
    end

    it "does not merge if the item id is not the same" do
      model.versions.last.update_attribute :item_id, 1234
      expect { model.reload.squish_history! }.to_not \
        change { PaperTrail::Version.count }
    end

    it "does not merge if the item type is not the same" do
      model.versions.last.update_attribute :item_type, :blah
      expect { model.reload.squish_history! }.to_not \
        change { PaperTrail::Version.count }
    end

    it "does not merge if the item event is not the same" do
      model.versions.last.update_attribute :event, :blah
      expect { model.reload.squish_history! }.to_not \
        change { PaperTrail::Version.count }
    end

    it "does not merge if the responsible party is not the same" do
      model.versions.last.update_attribute :whodunnit, "blah"
      expect { model.reload.squish_history! }.to_not \
        change { PaperTrail::Version.count }
    end
  end
end
