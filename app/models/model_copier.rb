class ModelCopier
  attr_reader :original, :copied

  def initialize(model)
    @original = model
  end

  def copy(options={})
    @copied = original.dup
    attributes = options.delete(:attributes) {{}}
    copied.copy_attributes attributes
    handle_options options.delete(:options) {{}}
    copy_associations options.delete(:associations) {[]}, attributes
    copied
  end

  private

  def copy_associations(associations, attributes)
    ModelAssociationCopier.new(original, copied).copy([associations].flatten, attributes)
  end

  def handle_options(options)
    prepend_attributes options.delete(:prepend) {{}}
    run_overrides options.delete(:overrides) {{}}
  end

  def prepend_attributes(attributes)
    attributes.each_pair do |attribute, text|
      copied.send(attribute).prepend text
    end
  end

  def run_overrides(overrides)
    overrides.each { |override| override.call copied }
  end

  class ModelAssociationCopier
    attr_reader :original, :copied

    def initialize(original, copied)
      @original = original
      @copied = copied
    end

    def copy(associations, attributes)
      copied.save unless original.new_record?
      associations.each { |association| copy_association(association, attributes) }
    end

    def copy_association(association, attributes)
      if association.is_a? Hash
        add_association_with_attributes association, attributes
      else
        add_association association, attributes
      end
    end

    def add_association_with_attributes(association, attributes)
      parsed = AssociationAttributeParser.new(association).parse(copied)
      add_association parsed.association, attributes.merge(parsed.attributes)
    end

    def add_association(association, attributes)
      copied.send(association).send "<<", original.send(association).map { |child| child.copy(attributes) }
    end
  end

  class AssociationAttributeParser
    attr_reader :association
    attr_reader :attributes

    def initialize(association)
      @association = association
    end

    def parse(target)
      split_attributes_from_association
      @association = association.keys.first
      assign_values_to_attributes target
      self
    end

    def split_attributes_from_association
      # association is specified as { association: { attributes }} and this
      # splits out the attributes
      @attributes = association.values.inject({}) { |hash, element| hash.merge!(element) }
    end

    def assign_values_to_attributes(target)
      attributes.each_pair do |attribute, value|
        attributes[attribute] = target.send(value) if value.is_a? Symbol
      end
    end
  end
end
