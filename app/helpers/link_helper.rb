require "uri"

module LinkHelper
  def external_link_to(name = nil, options = nil, html_options = nil, &block)
    if block_given?
      options = { "target" => "_blank" }.merge(options || {}) if external_link? name
    else
      html_options = { "target" => "_blank" }.merge(html_options || {}) if external_link? options
    end

    link_to name, options, html_options, &block
  end

  def external_link?(uri)
    UriInspector.new(uri).external?
  end

  def sanitize_external_links(content)
    sanitize content, scrubber: InternalLinkScrubber.new
  end

  def omission_link_to(name = nil, options = nil, html_options = nil, &block)
    omission_options = (block_given? ? options : html_options) || {}
    limit = omission_options.delete(:limit) { 50 }
    indicator = omission_options.delete(:indicator) { "..." }

    content = block_given? ? capture(&block) : name
    original_content = content.html_safe
    content = "#{content[0..(limit - indicator.length)]}#{indicator}" if content.length > limit

    if block_given?
      block = lambda { content } if block_given?
      options = { "title" => original_content }.merge(options || {})
    else
      name = content
      html_options = { "title" => original_content }.merge(html_options || {})
    end

    link_to name, options, html_options, &block
  end

  class InternalLinkScrubber < Rails::Html::PermitScrubber
    def scrub(node)
      return super unless (node.type == Nokogiri::XML::Node::ELEMENT_NODE) &&
        (node.name == "a")
      node.set_attribute("target", "_blank") if UriInspector.new(node["href"]).external?
    end
  end

  class UriInspector
    attr_reader :uri

    def initialize(uri)
      @uri = uri
    end

    def external?
      return false if self.uri.blank?
      uri = URI(self.uri)
      !uri.relative? && !uri.host.end_with?("gradecraft.com") &&
        !uri.host.end_with?("localhost")
    rescue URI::InvalidURIError
      false
    end
  end
end
