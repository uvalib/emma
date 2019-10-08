# test/test_helper/system_tests/bookshare.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'api/common'

# Support for testing Bookshare API compliance.
#
module TestHelper::SystemTests::Bookshare

  include TestHelper::SystemTests::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The web page containing Bookshare API documentation.
  #
  # @type [String]
  #
  APIDOC_URL = 'https://apidocs.bookshare.org/reference/index.html'

  # A mapping of documentation element ID to request method name.
  #
  # @type [Hash{String=>String}]
  #
  API_REQUEST_METHODS =
    ApiService.api_methods.map { |method, properties|
      element_id = properties[:reference_id]
      [element_id.to_s, method.to_s] if element_id.present?
    }.compact.to_h.deep_freeze

  # A partial mapping of documentation element ID to a base API record or type
  # name.  (Most record class names are already suitable for automatic
  # translation and are not listed here.)
  #
  # @type [Hash{String=>String}]
  #
  API_RECORD_TYPES = {
    studentstatus:          'StudentStatus',
    content_warning_values: 'ContentWarning',
    myaccount_preferences:  'MyAccountPreferences',
    myaccount_summary:      'MyAccountSummary',
  }.map { |k, v| [k.to_s, v.to_s] }.to_h.deep_freeze

  # A translation of Api#ENUMERATIONS.
  #
  # @type [Hash{String=>Array<String>}]
  #
  API_ENUMERATIONS =
    Api::ENUMERATIONS.map { |name, properties|
      [name.to_s, (properties[:values]&.sort || [])]
    }.to_h.deep_freeze

  # Translate an implementation field type into a specification field type.
  #
  # This is mostly for cases where the type in the implementation record class
  # is more restrictive than the documented field type.
  #
  # @type [Hash{String=>String}]
  #
  API_TYPE_MAPPING = {
    AllowsType:           'String',
    DisabilityType:       'String',
    FormatType:           'String',
    IsoDuration:          'String',
    PeriodicalFormatType: 'String',
    SiteType:             'String',
  }.map { |k, v| [k.to_s, v.to_s] }.to_h.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Acquires the contents of Bookshare API documentation to be used across
  # all tests in including test case class.
  #
  # @param [String, nil] url          Default: #APIDOC_URL
  #
  # @return [Capybara::Session]
  #
  # noinspection RubyClassVariableUsageInspection
  def bookshare_apidoc(url = nil)
    @@bookshare_apidoc ||=
      Capybara::Session.new(:selenium).tap do |session|
        session.visit(url || APIDOC_URL)
      end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get a validated ApiService instance.
  #
  # @return [ApiService]
  #
  def api
    # noinspection RubyYardReturnMatch
    @api ||= validate_api_methods && ApiService.instance
  end

  # Get the underscore form of the given request from the Bookshare API
  # documentation page.
  #
  # @param [String] element_id
  #
  # @return [String]
  # @return [nil]
  #
  def api_request_method(element_id)
    id = element_id.to_s
    # noinspection RubyYardReturnMatch
    API_REQUEST_METHODS[id] || id.delete_prefix('_').underscore if id.present?
  end

  # record_fields
  #
  # @param [Capybara::Node::Element] node
  #
  # @return [Array<Hash>]
  #
  def api_request_parameters(node)
    tables = node.find_all('table') rescue nil
    table =
      tables&.find { |t|
        header = t.find_all('thead th') rescue nil
        header&.first&.text == 'Type'
      }
    rows = (table&.find_all('tbody tr') rescue nil) || []
    # noinspection RubyYardReturnMatch
    rows.map { |row|
      parts = row.find_all('p') rescue []
      kind, name, desc, type, default =
        parts.map { |p| p.text.to_s.sub(/\s+/, ' ').strip }
      name_parts = name.split(' ').reject { |v| v == 'optional' }
      {}.tap do |entry|
        entry[:kind]       = kind.presence || 'MISSING'
        entry[:name]       = name_parts.shift
        entry[:required]   = name_parts.present?
        entry[:desc]       = desc.presence&.inspect || 'none'
        entry[:type]       = record_field_type(type).dup
        entry[:collection] = !!entry[:type].delete_prefix!('Array ')
        entry[:default]    = default.presence || '-'
        entry[:path]       = (kind == 'Path')
      end
    }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Verify that each documentation reference ID is associated with only one
  # ApiService method.  If any duplicates are found, #assert will be raised.
  #
  # @return [TrueClass]
  #
  def validate_api_methods
    reference = {}
    duplicate = {}
    ApiService.api_methods.each do |method, properties|
      if (ref_id = properties[:reference_id].to_s).blank?
        next
      elsif (existing_method = reference[ref_id])
        duplicate[ref_id] ||= [existing_method]
        duplicate[ref_id] << method
      else
        reference[ref_id] = method
      end
    end
    assert duplicate.blank?, ->() {
      duplicate.map { |element_id, methods|
        "#{element_id}: #{methods.join(', ')}"
      }.unshift('Same :reference_id for two or more API methods:').join("\n")
    }
    true
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the class which implements the named method.
  #
  # @param [Symbol] m
  #
  # @return [Method]
  # @return [nil]
  #
  def method_class(m)
    ApiService.instance.method(m.to_sym)
  end

  # method_params
  #
  # @param [Symbol] m
  #
  # @return [Array<Hash>]
  # @return [nil]
  #
  def method_params(m)
    return unless (m = method_class(m))
    # noinspection RubyYardReturnMatch
    m.parameters.map do |pair|
      status, name = pair
      name ||=
        case status
          when :rest    then '*'
          when :keyrest then '**'
          else               '???'
        end
      status =
        case status
          when :req     then 'required_arg'
          when :rest    then 'other_args'
          when :key     then 'opt'
          when :keyreq  then 'required_opt'
          when :keyrest then 'other_opts'
          else               status.to_s
        end
      {
        name:     name.to_s,
        status:   status,
        path:     status == 'required_opt',
        required: status.include?('required')
      }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the underscore form of the given identifier from the Bookshare API
  # documentation page.
  #
  # @param [String, Symbol, Class, nil] element_id
  #
  # @return [String]
  # @return [nil]
  #
  def record_type(element_id)
    id = element_id.to_s.delete_prefix('_').underscore
    API_RECORD_TYPES[id] || id.camelize if id.present?
  end

  # Get the documented type of the given field name translated to the Ruby
  # value.
  #
  # @param [String]      type
  # @param [String, nil] default      Default: "MISSING".
  #
  # @return [String]
  # @return [nil]                     If *type* is blank and *default* is nil.
  #
  def record_field_type(type, default = 'MISSING')
    case (type = type.to_s.strip)
      when ''
        default
      when 'string', 'integer', 'boolean'
        type.camelize
      when /^(integer|boolean).*/
        $1.camelize
      when /(^string)/
        parts = type.sub($1, '').tr('(),', ' ').squish
        case parts
          when ''     then 'String'
          when 'date' then 'IsoDate'
          when 'year' then 'IsoYear'
          else             type
        end
      when /(^enum)/
        parts = type.sub($1, '').tr('(),', ' ').squish
        found = parts = parts.presence&.split(' ')&.sort
        found &&=
          %w(AllowsType).find { |k| (parts - API_ENUMERATIONS[k]).blank? } ||
          API_ENUMERATIONS.find { |k, values| break k if parts == values }
        found || type
      when /(array$)/, /(array\(multi\)$)/
        parts = type.sub($1, '').tr('<>,', ' ').squish
        type  = record_field_type(parts, 'String')
        "Array #{type}"
      else
        type = record_type(type)
        type = "Api::#{type}" unless API_ENUMERATIONS.key?(type)
        type
    end
  end

  # record_fields
  #
  # @param [Capybara::Node::Element] node
  #
  # @return [Array<Hash>]
  #
  def record_fields(node)
    rows = node.find_all('tbody tr') rescue []
    rows.map { |row|
      parts = row.find_all('p') rescue []
      name, desc, type = parts.map { |p| p.text.to_s.sub(/\s+/, ' ').strip }
      next unless name.present?
      desc, type = [nil, desc] if type.nil?
      name_parts = name.split(' ').reject { |v| v == 'optional' }
      {}.tap do |entry|
        entry[:name]       = name_parts.shift
        entry[:required]   = name_parts.join(', ') if name_parts.present?
        entry[:desc]       = desc.presence&.inspect || 'none'
        entry[:type]       = record_field_type(type).dup
        entry[:collection] = !!entry[:type].delete_prefix!('Array ')
      end
    }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the class which implements the named quantity.
  #
  # @param [String, Symbol, Class, nil] name
  #
  # @return [Class]
  # @return [nil]
  #
  def model_class(name)
    name = name.to_s.delete_prefix('_').underscore.camelize
    return if name.blank?
    # noinspection RubyYardReturnMatch
    ("Api::#{name}".constantize rescue nil) ||
      ("Api#{name}".constantize rescue nil)
  end

  # Get the comparable name of the given Ruby type.
  #
  # @param [String, Symbol, Class, Proc, nil] type
  #
  # @return [String]
  #
  def model_field_type(type)
    type = type.call rescue '?' if type.is_a?(Proc)
    name = type.to_s
    if name.blank?
      '-'
    elsif type.ancestors.include?(Axiom::Types::Type)
      name.delete_prefix('Axiom::Types::')
    elsif type.ancestors.include?(ScalarType)
      name.delete_prefix('Api::')
    else
      name
    end
  end

  # model_fields
  #
  # @param [String, Symbol, Class] type
  #
  # @return [Array<Hash>]
  #
  def model_fields(type)
    name  = model_class(type)
    model = name&.new('{}')
    fields = {}
    fields = model.field_definitions if model.respond_to?(:field_definitions)
    fields.map do |field|
      type = model_field_type(field[:type])
      field.merge(type: type)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce a listing of failures.
  #
  # @param [String, nil] header       Generate an initial line.
  # @param [Hash, Array] missing
  # @param [Hash, Array] problems
  #
  # @return [String]
  # @return [nil]
  #
  def failure_list(header, missing, problems)
    result = []
    result << missing_list(missing,  header) if missing.present?
    result << problem_list(problems, header) if problems.present?
    return if result.blank?
    result.unshift('Bookshare API Compliance Issues')
    result.join("\n\n") << "\n"
  end

  # Produce a table of missing items.
  #
  # @param [Hash, Array]     missing
  # @param [String, nil]     header
  # @param [Integer, String] indent
  # @param [Integer]         width
  #
  # @return [String]
  #
  def missing_list(missing, header = nil, indent: nil, width: nil)
    missing  = missing.to_h unless missing.is_a?(Hash)
    header &&= "Missing #{header}:"
    indent   = ' ' * indent if indent.is_a?(Integer)
    width  ||= missing.keys.sort_by(&:size).last.size
    format   = "#{indent}*** %-#{width}s\t#{APIDOC_URL}#%s"
    show_section(header, output: false) {
      missing.map { |item, id| sprintf(format, item, id) }
    }.join("\n")
  end

  # Produce a table of problematic items.
  #
  # @param [Hash, Array] problems
  # @param [String, nil] header
  # @param [Hash]        opt          Passed to #show_subsection
  #
  # @return [String]
  #
  def problem_list(problems, header = nil, **opt)
    problems = problems.to_h unless problems.is_a?(Hash)
    header &&= "Problem #{header}:"
    ss_opt   = opt.merge(output: false)
    ss_opt[:width] ||=
      problems.values.flat_map(&:keys).sort_by(&:size).last.size
    show_section(header, output: false) {
      problems.map { |item, problem| show_subsection(item, problem, **ss_opt) }
    }.join("\n")
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Display API documentation request parameters when debugging.
  #
  # @param [Array<Hash>] fields
  # @param [String, nil] method
  # @param [Hash]        opt          Passed to #show_subsection
  #
  # @return [void]
  #
  def show_request_params(fields, method = nil, **opt)
    header = method && "\n\nREQUEST: #{method}"
    show_section(header) do
      ss_opt = opt.reverse_merge(separator: ' ').merge(output: false)
      fields.map do |field|
        show_subsection(field[:name], **ss_opt) do
          type = field[:type]
          type = "Array[#{type}]" if field[:collection]
          {
            Kind:        field[:kind],
            Required:    field[:required] || 'optional',
            Description: field[:desc],
            Type:        type,
            Default:     field[:default],
          }
        end
      end
    end
  end

  # Display API request method parameters when debugging.
  #
  # @param [Array<Hash>] fields
  # @param [String, nil] method
  # @param [Hash]        opt          Passed to #show_subsection
  #
  # @return [void]
  #
  def show_method_params(fields, method = nil, **opt)
    header = method && "\n\nMETHOD: #{method}"
    show_section(header) do
      ss_opt = opt.reverse_merge(separator: ' ').merge(output: false)
      fields.map do |field|
        show_subsection('PARAM', field, **ss_opt)
      end
    end
  end

  # Display API documentation record fields when debugging.
  #
  # @param [Array<Hash>] fields
  # @param [String, nil] record_type
  # @param [Hash]        opt          Passed to #show_subsection
  #
  # @return [void]
  #
  def show_record_fields(fields, record_type = nil, **opt)
    header = record_type && "\n\nRECORD: #{record_type}"
    show_section(header) do
      ss_opt = opt.reverse_merge(separator: ' ').merge(output: false)
      fields.map do |field|
        header = field[:name]
        header += " (#{field[:required]})" if field[:required]
        show_subsection(header, **ss_opt) do
          type = field[:type]
          type = "Array[#{type}]" if field[:collection]
          {
            Description: field[:desc],
            Type:        type,
          }
        end
      end
    end
  end

  # Display API implementation record fields when debugging.
  #
  # @param [Array<Hash>] fields
  # @param [String, nil] record_type
  # @param [Hash]        opt          Passed to #show_subsection
  #
  # @return [void]
  #
  def show_model_fields(fields, record_type = nil, **opt)
    header = record_type && "MODEL: #{model_class(record_type)}"
    show_subsection(header, **opt) do
      fields.map do |field|
        name = field[:name]
        type = field[:type]
        type = "Array[#{type}]" if field[:collection]
        [name, type]
      end
    end
  end

  # Display API implementation record problems when debugging.
  #
  # @param [Hash] fields
  # @param [Hash] opt                 Passed to #show_subsection
  #
  # @return [void]
  #
  def show_problem_fields(fields, **opt)
    show_subsection('PROBLEMS:', fields, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # show_section
  #
  # @param [String]             header
  # @param [Array<String>, nil] lines
  # @param [Boolean]            output
  #
  # @return [Array<String>]
  #
  def show_section(header, lines = nil, output: true)
    lines = Array.wrap(lines)
    lines += Array.wrap(yield) if block_given?
    lines.flatten!
    if lines.present?
      lines.unshift(header)  if header
      show(lines.join("\n")) if output
    end
    lines
  end

  # show_subsection
  #
  # @param [String]          header
  # @param [Hash, nil]       parts
  # @param [Integer, String] indent
  # @param [Integer]         width
  # @param [String]          separator
  # @param [Boolean]         output
  #
  # @return [Array<String>]
  #
  def show_subsection(
    header,
    parts = nil,
    indent:    3,
    width:     nil,
    separator: "\t",
    output:    true
  )
    parts  = parts.to_h if parts.is_a?(Array)
    added  = (yield if block_given?)
    added  = added.to_h if added.is_a?(Array)
    parts  = parts && added && parts.merge(added) || parts || added || {}
    indent = ' ' * indent if indent.is_a?(Integer)
    lines  = []
    if header
      lines << "\n#{indent}#{header}" if header
      indent *= 2
    end
    if parts.present?
      width ||= parts.keys.sort_by(&:size).last.size
      format  = "#{indent}%-#{width}s#{separator}%s"
      lines  += parts.map { |label, value| sprintf(format, label, value) }
    end
    show(lines.join("\n")) if output
    lines
  end

end
