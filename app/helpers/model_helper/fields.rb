# app/helpers/model_helper/fields.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting manipulation of Model instance fields.
#
module ModelHelper::Fields

  include ModelHelper::Links

  include Emma::Json
  include Emma::Unicode

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Field value used to explicitly indicate missing data.
  #
  # @type [String]
  #
  EMPTY_VALUE = EN_DASH

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Field/value pairs.
  #
  # If *pairs* is not provided (as a parameter or through a block) then
  # `item#field_names` is used.  If no block is provided and *pairs* is present
  # then this function simply returns *pairs* as-is.
  #
  # @param [Model, Hash, *] item
  # @param [Hash, nil]      pairs
  #
  # @return [Hash]
  #
  # @yield [item] To supply additional field/value pairs based on *item*.
  # @yieldparam  [Model] item         The supplied *item* parameter.
  # @yieldreturn [Hash]               Result will be merged into *pairs*.
  #
  def field_values(item, pairs = nil)
    if block_given?
      yield(item).reverse_merge(pairs || {})
    elsif pairs.present?
      # noinspection RubyMismatchedReturnType
      pairs
    elsif item.is_a?(ApplicationRecord)
      # Convert :file_data and :emma_data into hashes and move to the end.
      data, pairs = partition_hash(item.fields, :file_data, :emma_data)
      data.each_pair { |k, v| pairs[k] = json_parse(v) }
    elsif item.is_a?(Api::Record)
      item.field_names.map { |f| [f.to_s.titleize.to_sym, f] }.to_h
    elsif item.is_a?(Hash)
      item
    else
      {}
    end
  end

  # field_pairs
  #
  # @param [Model, Hash, nil]    item
  # @param [String, Symbol, nil] model        Default: `params[:controller]`.
  # @param [String, Symbol, nil] action       Default: `params[:action]`.
  # @param [Hash, nil]           pairs        Except for #render_pair options.
  # @param [Proc]                block        Passed to #field_values.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RubyMismatchedParameterType
  #++
  def field_pairs(item, model: nil, action: nil, pairs: nil, **, &block)
    model  = Model.for(model || item) || params[:controller]&.to_sym
    action = (action || params[:action])&.to_sym
    # noinspection RubyNilAnalysis
    field_values(item, pairs, &block).map { |k, v|
      field, value, config = k, v, nil
      if v.is_a?(Symbol)
        field = v
      elsif k.is_a?(Symbol) && v.is_a?(Hash)
        value, config = [k, v]
      end
      next unless value.present? || value.is_a?(FalseClass)
      if field.is_a?(Symbol)
        config ||= Field.configuration_for(field, model, action)
      else
        config ||= Field.configuration_for_label(field, model, action)
        field    = config[:field] if config&.dig(:field)&.is_a?(Symbol)
      end
      prop  = config&.dup || {}
      prop[:field] ||= (field if field.is_a?(Symbol))
      prop[:label] ||= (k     if k.is_a?(String))
      prop[:value]   = value
      [field, prop]
    }.compact.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # EMMA data field prefixes with trailing underscore for #model_html_id.
  #
  # @type [Array<String>]
  #
  FIELD_PREFIX =
    DataHelper::EMMA_DATA_FIELDS.map { |field|
      field.to_s.sub(/_.*$/, '_')
    }.uniq.deep_freeze

  # Suffixes indicating field names to be preserved in #model_html_id.
  #
  # @type [Array<String>]
  #
  RESERVED_SUFFIX = %w(_data _date).freeze

  # Create a base for .field-* and .value-* classes.
  #
  # @param [Symbol, String, nil] base   Default: 'None'.
  #
  # @return [String]
  #
  def model_html_id(base)
    name = base.to_s.strip
    unless name.end_with?(*RESERVED_SUFFIX)
      FIELD_PREFIX.find { |prefix| name.delete_prefix!(prefix) }
    end
    name = 'None' if name.blank?
    html_id(name, camelize: true)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Match a major section title in a table-of-contents listing.
  #
  # @type [Regexp]
  #
  #--
  # noinspection SpellCheckingInspection
  #++
  SECTION_TITLE_RE = /^(PART|[CDILMVX]+\.?|[cdilmvx]+\.|\d+\.|v\.) +(.*)/

  # For use with String#scan to step through quote/attribute pairs.
  #
  # @type [Regexp]
  #
  BLURB_RE = /([^\n]*?[[:punct:]]) *-- *([^\n]+?\.\s+|[^\n]+\s*)/

  # Reformat descriptions which are structured in a way that one would find
  # in MARC metadata.
  #
  # @param [String] text
  #
  # @return [Array<String>]
  #
  # == Usage Notes
  # Descriptions like this don't currently seem to appear very often in search
  # results.  Even for those that do, they may not adhere to the expected
  # layout of information, and this method may not be that beneficial in those
  # cases.
  #
  def format_description(text)
    # Look for signs of structure, otherwise just treat as unstructured.
    case text
      when /"";/                     then double_quotes_to_sections(text)
      when /\.--v\. */               then double_dash_to_sections(text)
      when /; *PART */i              then # Seen in some IA records.
      when /:;/                      then # Observed in one unusual case.
      when /[[:punct:]] *--.* +-- +/ then # Blurbs/quotes with attribution.
      when / +-- +.* +-- +/          then # Table-of-contents title list.
      when /(;[^;]+){4,}/            then # Many sections indicated.
      else                                return format_multiline(text)
    end
    q_section = nil
    text.split(/ *; */).flat_map { |part|
      next if (part = part.strip).blank?
      case part
        when /^""(.*)""$/
          # == Rare type of table-of-contents listing entry
          line = $1.to_s
          if line.match(SECTION_TITLE_RE)
            gap       = ("\n" unless q_section)
            q_section = $1.to_s
            [gap, "#{q_section} #{$2}", "\n"].compact
          else
            q_section = nil
            line.match?(/^\d+ +/) ? line : "#{BLACK_CIRCLE}#{EN_SPACE}#{line}"
          end

        when / +-- +.* +-- +/
          # === Table-of-contents listing
          section = nil
          part.split(/ +-- +/).flat_map { |line|
            if line.match(SECTION_TITLE_RE)
              gap     = ("\n" unless section)
              section = $1.to_s.delete_suffix('.')
              [gap, "#{section}. #{$2}", "\n"].compact
            else
              section = nil
              "#{BLACK_CIRCLE}#{EN_SPACE}#{line}"
            end
          }.tap { |toc| toc << "\n" unless toc.last == "\n" }

        when /[[:punct:]] *--/
          # === Blurbs/quotes with attribution
          part.scan(BLURB_RE).flat_map do |paragraph, attribution|
            attribution.remove!(/[.\s]+$/)
            ["#{paragraph} #{EM_DASH}#{attribution}.", "\n"]
          end

        when /^v[^.]*\. *\d/
          # === Apparent table-of-contents volume title
          [part]

        else
          # === Plain text section
          part = "#{part}." unless part.match?(/[[:punct:]]$/)
          [part, "\n"]
      end
    }.compact.map { |line|
      line.gsub(/---/, EM_DASH).gsub(/--/,  EN_DASH)
    }
  end

  # Seen in some IA records.
  #
  # @param [String]
  #
  # @return [String]
  #
  def double_quotes_to_sections(text)
    text.to_s.gsub(/"" ""|""""/, '""; ""')
  end

  # Seen in some IA records.
  #
  # @param [String]
  #
  # @return [String]
  #
  def double_dash_to_sections(text)
    text.to_s.dup.tap do |result|
      result.sub!( /(\S) +(v[^.\s]*\.) */,     '\1 -- \2 ')
      result.gsub!(/(\S) *-- *(v[^.\s]*\.) */, '\1; \2 ')
    end
  end

  # Transform a string with newlines/semicolons into an array of lines.
  #
  # @param [String] text
  #
  # @return [Array<String>]
  #
  def format_multiline(text)
    Array.wrap(text).flat_map { |s| s.to_s.split(/ *[;\n] */) }.compact_blank!
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  VALID_LANGUAGE   = 'Provided value: %s' # TODO: I18n
  INVALID_LANGUAGE = 'The underlying data contains this value ' \
                     'instead of a valid ISO 639 language code.'

  # Wrap invalid language values in a <span>.
  #
  # @param [*, Array<*>] value
  # @param [Boolean]     code         If *true* display the ISO 639 code.
  #
  # @return [*, Array<*>]
  #
  def mark_invalid_languages(value, code: false)
    if value.is_a?(Array)
      return value.map { |v| send(__method__, v, code: code) }
    end
    lang = IsoLanguage.find(value)
    return value if code ? (value == lang&.alpha3) : lang
    if lang
      opt   = { title: (VALID_LANGUAGE % value.inspect) }
      value = code ? lang.alpha3 : lang.english_name
    else
      opt   = { title: (INVALID_LANGUAGE % value.inspect), class: 'invalid' }
    end
    html_span(value, opt)
  end

  # Wrap invalid identifier values in a <span>.
  #
  # @param [*, Array<*>] value
  #
  # @return [*, Array<*>]
  #
  def mark_invalid_identifiers(value)
    return value.map { |v| send(__method__, v) } if value.is_a?(Array)
    type, id_part = value.split(':', 2)
    if id_part.nil? # No type prefix.
      value
    elsif (identifier = PublicationIdentifier.create(id_part, type))&.valid?
      identifier.to_s
    else
      tip = "This is not a valid #{type.upcase} identifier." # TODO: I18n
      html_span(value, class: 'invalid', title: tip)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
