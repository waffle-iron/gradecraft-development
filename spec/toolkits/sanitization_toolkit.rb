RSpec.shared_examples "a model that needs sanitization" do |attribute|
  describe "relaxed html sanitization" do
    describe "##{attribute}" do
      def get(attribute)
        subject.send attribute
      end

      def set(attribute, value)
        subject.send "#{attribute}=", value
      end

      it "html-escapes entities" do
        set attribute, "Hello & Goodbye"
        subject.save
        expect(get attribute).to eq "Hello &amp; Goodbye"
      end
    end
  end
end
