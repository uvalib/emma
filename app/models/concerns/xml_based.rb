# app/models/concerns/xml_based.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'nokogiri'

# Manipulate file formats containing one or more XML files.
#
module XmlBased

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # Metadata may be retrieved either by index or as a method call.
  #
  # E.g. :title is available as either `metadata[:title]` or `metadata.title`.
  #
  # @return [OpenStruct]
  #
  def metadata
    @metadata ||=
      OpenStruct.new(
        retrieve_metadata.transform_values { |v|
          v.is_a?(Array) && v.uniq || v
        }
      )
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Gather all metadata values.
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def retrieve_metadata
    raise "#{self.class}: #{__method__} not defined"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # parse_metadata
  #
  # @param [Nokogiri::XML::Element, Nokogiri::XML::Nodeset] section
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def parse_metadata(section)
    __debug_parse(section)
    result = {}
    section = section.elements if section.respond_to?(:elements)
    section.each do |element|
      __debug_parse(section, element)
      key, value = parse_meta(element) || parse_element(element)
      (result[key] ||= []) << value if value.present?
    end
    result
  end

  # parse_elements
  #
  # @param [Nokogiri::XML::Element, Nokogiri::XML::Nodeset] section
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def parse_elements(section)
    __debug_parse(section)
    result = {}
    section = section.elements if section.respond_to?(:elements)
    section.each do |element|
      __debug_parse(section, element)
      key, value = parse_element(element)
      (result[key] ||= []) << value if value.present?
    end
    result
  end

  # Extract information from a single element.
  #
  # @param [Nokogiri::XML::Element] element
  #
  # @return [Array<(Symbol,String)>]
  # @return [Array<(Symbol,nil)>]
  #
  def parse_element(element)
    return unless element.element?
    name, value = get_properties(element)
    attrs = get_attributes(element)
    # noinspection RubyCaseWithoutElseBlockInspection
    case (key = make_key(name))
      when :author, :creator, :contributor
        key = role_type(attrs[:role]) || key
      when :identifier
        scheme = attrs[:scheme]&.downcase
        value  = "#{scheme}:#{value}" if scheme
      when :date
        case attrs[:event]
          when 'publication' then key = :publication_date
          when 'conversion'  then key = :produced_date
          else                    # no change
        end
    end
    return key, value
  end

  # parse_metas
  #
  # @param [Nokogiri::XML::Element, Nokogiri::XML::Nodeset] section
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def parse_metas(section)
    __debug_parse(section)
    result = {}
    section = section.elements if section.respond_to?(:elements)
    section.each do |element|
      __debug_parse(section, element)
      key, value = parse_meta(element)
      (result[key] ||= []) << value if value.present?
    end
    result
  end

  # Extract information from a single <meta> element.
  #
  # @param [Nokogiri::XML::Element]
  #
  # @return [Array<(Symbol,String)>]
  # @return [Array<(Symbol,nil)>]
  # @return [nil]
  #
  def parse_meta(elem)
    return unless elem.respond_to?(:name) && (elem.name == 'meta')
    attrs = get_attributes(elem)
    key   = make_key(attrs[:property] || attrs[:name])
    value = attrs[:content]  || attrs[:value] || elem.content
    value = value.to_s.strip.presence
    return key, value
  end

  # Return element values as a hash.
  #
  # @param [Nokogiri::XML::Element]
  #
  # @return [Array<(String,String)>]
  # @return [Array<(String,nil)>]
  #
  def get_properties(elem)
    name  = elem.respond_to?(:name) ? elem.name : elem.class.name
    value = (elem.content.to_s.strip if elem.respond_to?(:content))
    return name, value.presence
  end

  # Return element attributes as a hash.
  #
  # @param [Nokogiri::XML::Element]
  #
  # @return [Hash{Symbol=>String}]
  #
  def get_attributes(elem)
    return {} unless elem.respond_to?(:attribute_nodes)
    elem.attribute_nodes.map { |node|
      k = node.node_name.to_sym
      v = (node.value.to_s.strip if node.respond_to?(:value))
      [k, v] if v.present?
    }.compact.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Transform an element name (or the equivalent attribute from a <meta>) into
  # a #metadata key.
  #
  # @param [String] name
  #
  # @return [Symbol]
  #
  def make_key(name)
    name.to_s.strip
      .sub(/^[^:]+:/, '')                     # Strip leading scheme if present
      .sub(/^.*\.([^.]+)$/, '\1')             # Simplify compound term.
      .sub(/^(.)/) { $1.downcase }            # Make first letter lowercase.
      .underscore                             # Transform camelcase.
      .tap { |k| k << 's' if k == 'format' }  # Avoid confusion with #format.
      .to_sym
  end

  # role_type
  #
  # @param [String] relator_code
  #
  # @return [Symbol]
  # @return [nil]
  #
  # @see https://www.loc.gov/marc/relators/relacode.html
  # @see https://www.loc.gov/marc/relators/relaterm.html
  #
  def role_type(relator_code)
    # noinspection RubyCaseWithoutElseBlockInspection
    case relator_code&.to_sym
      when :ctb # Contributor
        :contributor
      when :edt # Editor
      when :edc # Editor of a compilation
      when :edm # Editor of a moving image work
      when :flm # Film editor
        :editor
      when :adp # Adapter
      when :arc # Architect
      when :aus # Author of screenplay
      when :aut # Author
      when :cmp # Composer
      when :cre # Creator
      when :dis # Dissertant
      when :drt # Director
        :author
    end
  end

  # ===========================================================================
  # :section: Debugging
  # ===========================================================================

  protected

  DEBUGGING_PARSE = true

  if !DEBUGGING_PARSE

    # The debugging method is neutralized unless #DEBUGGING_PARSE is *true*.
    def __debug_parse(*); end

  else

    include Emma::Debug

    public

    # Display console output.
    #
    # @param [Array] args
    #
    # @return [nil]
    #
    # @see #get_attributes
    # @see #get_properties
    #
    # == Variations
    #
    # @overload __debug_parse(element)
    #   @param [Nokogiri::XML::Element] element
    #
    # @overload __debug_parse(element, inner)
    #   @param [Nokogiri::XML::Element] element
    #   @param [Nokogiri::XML::Element] inner
    #
    # @overload __debug_parse(method, element)
    #   @param [Symbol]                 method
    #   @param [Nokogiri::XML::Element] element
    #
    # @overload __debug_parse(method, element, inner)
    #   @param [Symbol]                 method
    #   @param [Nokogiri::XML::Element] element
    #   @param [Nokogiri::XML::Element] inner
    #
    def __debug_parse(*args)
      opt     = args.extract_options!
      method  = args.first.is_a?(Symbol) ? args.shift : calling_method
      element = args.shift
      inner   = args.shift
      __debug_line(*args, opt) do
        parts = [method, filename]
        if element
          name =
            if element.respond_to?(:name)
              element.name.inspect
            else
              element.class.name.demodulize
            end
          parts << "element #{name}"
        end
        if inner
          attrs = get_attributes(inner)
          if inner.respond_to?(:name) && (inner.name == 'meta')
            name  = attrs[:property] || attrs[:name]
            value = attrs[:content]  || attrs[:value] || inner.content
          else
            name, value = get_properties(inner)
          end
          parts << "name #{name.inspect}"
          parts << "value #{value.inspect}"
          parts << "attrs #{attrs.inspect}"
        end
        parts.compact
      end
    end

  end

end

__loading_end(__FILE__)
