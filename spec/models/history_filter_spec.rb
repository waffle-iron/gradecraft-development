require "ostruct"
require "./app/models/history_filter"

describe HistoryFilter do
  it "initializes with the changeset passed in" do
    history = [double(:history_item, changeset: [{ "event" => "blah" }, { "event" => "bleh" }, {}])]
    expect(described_class.new(history).history).to eq history
  end

  describe "#empty_changeset?" do
    it "is not empty if none of the values are arrays which represent changes" do
      history = [double(:history_item, changeset: [{ "change" => ["before", "after"] }])]
      expect(described_class.new(history).empty_changeset?(history.first.changeset.first)).to eq false
    end

    it "is empty if none of the values are arrays which represent changes" do
      history = [double(:history_item, changeset: [{ "event" => "blah" }])]
      expect(described_class.new(history).empty_changeset?(history.first.changeset.first)).to eq true
    end
  end

  describe "#exclude" do
    it "filters a changeset by event type" do
      history = [OpenStruct.new(changeset: { "event" => "blah", "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: { "event" => "bleh", "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: {})]
      result = described_class.new(history).exclude("event" => "blah").changesets
      expect(result).to eq [{ "event" => "bleh", "change" => ["before", "after"] }]
    end

    it "filters a changeset by object" do
      history = [OpenStruct.new(changeset: { "event" => "blah", "object" => "Grade",
                                             "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: { "event" => "bleh", "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: {})]
      result = described_class.new(history).exclude("object" => "Grade").changesets
      expect(result).to eq [{ "event" => "bleh", "change" => ["before", "after"] }]
    end

    it "filters a changeset via a block" do
      history = [OpenStruct.new(changeset: { "event" => "blah", "object" => "Grade",
                                             "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: { "event" => "bleh", "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: {})]
      result = described_class.new(history).exclude { |item|
        item.changeset["object"] == "Grade"
      }.changesets
      expect(result).to eq [{ "event" => "bleh", "change" => ["before", "after"] }]
    end
  end

  describe "#include" do
    it "includes a changeset by event type" do
      history = [OpenStruct.new(changeset: { "event" => "blah", "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: { "event" => "bleh", "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: {})]
      result = described_class.new(history).include("event" => "blah").changesets
      expect(result).to eq [{ "event" => "blah", "change" => ["before", "after"] }]
    end

    it "includes a changeset by object" do
      history = [OpenStruct.new(changeset: { "event" => "blah", "object" => "Grade",
                                             "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: { "event" => "bleh", "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: {})]
      result = described_class.new(history).include("object" => "Grade").changesets
      expect(result).to eq [{ "event" => "blah", "object" => "Grade",
                              "change" => ["before", "after"] }]
    end

    it "filters a changeset via a block" do
      history = [OpenStruct.new(changeset: { "event" => "blah", "object" => "Grade",
                                             "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: { "event" => "bleh", "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: {})]
      result = described_class.new(history).include { |item|
        item.changeset["object"] == "Grade"
      }.changesets
      expect(result).to eq [{ "event" => "blah", "object" => "Grade",
                              "change" => ["before", "after"] }]
    end
  end

  describe "#merge" do
    it "merges the changeset from one object to another" do
      history = [OpenStruct.new(version: OpenStruct.new(
                                          item_type: "FromObjectType",
                                          transaction_id: 123),
                                changeset: { "event" => "create",
                                             "object" => "FromObject",
                                             "attribute1" => [nil, "blah"]}),
                 OpenStruct.new(version: OpenStruct.new(
                                          item_type: "ToObjectType",
                                          transaction_id: 123),
                                changeset: { "event" => "create",
                                             "object" => "ToObject",
                                             "attribute2" => [nil, "http://example.org"]})
      ]
      result = described_class.new(history).merge("FromObjectType" => "ToObjectType")
        .changesets
      expect(result).to eq [{ "event" => "create",
                              "object" => "ToObject",
                              "attribute2" => [nil, "http://example.org"],
                              "attribute1" => [nil, "blah"]}]
    end

    it "does not merge if the destination does not exist" do
      history = [OpenStruct.new(version: OpenStruct.new(
                                          item_type: "FromObjectType",
                                          transaction_id: 123),
                                changeset: { "event" => "create",
                                             "object" => "FromObject",
                                             "attribute1" => [nil, "blah"]})
      ]
      result = described_class.new(history).merge("FromObjectType" => "ToObjectType")
        .changesets
      expect(result).to be_empty
    end

    it "does not merge if the transaction ids do not match" do
      history = [OpenStruct.new(version: OpenStruct.new(
                                            item_type: "From",
                                            transaction_id: 123),
                                changeset: {}),
                 OpenStruct.new(version: OpenStruct.new(
                                          item_type: "To",
                                          transaction_id: 456),
                                changeset: {})
      ]
      result = described_class.new(history).merge("From" => "To").changesets
      expect(result).to be_empty
    end
  end

  describe "#remove" do
    it "filters a changeset by the changes" do
      history = [OpenStruct.new(changeset: { "attr" => ["value1", "value2"],
                                             "attr2" => ["value3", "value4"] })]
      result = described_class.new(history).remove("name" => "attr2").changesets
      expect(result).to eq [{ "attr" => ["value1", "value2"] }]
    end

    it "removes the whole changeset if it's empty after the removal" do
      history = [OpenStruct.new(changeset: { "attr" => ["value1", "value2"] }),
                 OpenStruct.new(changeset: { "attr2" => ["value3", "value4"] })]
      result = described_class.new(history).remove("name" => "attr2").changesets
      expect(result).to eq [{ "attr" => ["value1", "value2"] }]
    end
  end

  describe "#rename" do
    it "changes the object value in the changeset" do
      history = [OpenStruct.new(changeset: { "event" => "blah", "object" => "Grade",
                                             "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: { "event" => "bleh", "change" => ["before", "after"] }),
                 OpenStruct.new(changeset: {})]
      result = described_class.new(history).rename("Grade" => "BLAH").changesets
      expect(result.first["object"]).to eq "BLAH"
    end
  end

  describe "#transform" do
    it "manipulates a single history item" do
      history = [OpenStruct.new(changeset: { "event" => "create",
                                             "object" => "SubmissionFile",
                                             "filename" => [nil, "blah"]
      })]
      result = described_class.new(history).transform do |history_item|
        history_item.changeset["event"] = "upload"
      end.changesets
      expect(result.first["event"]).to eq "upload"
    end
  end
end
