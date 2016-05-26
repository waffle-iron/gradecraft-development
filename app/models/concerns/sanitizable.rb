require "sanitize"

module Sanitizable
  extend ActiveSupport::Concern

  class_methods do
    def clean_html(attributes=[])
      attributes = [attributes].flatten
      attributes.each do |attribute|
        clean_html_before_save attribute
      end
    end

    def clean_html_before_save(attribute)
      before_save do
        self.send("#{attribute}=", Sanitize.clean(self.send(attribute),
          Sanitize::Config::RELAXED))
      end
    end
  end
end
