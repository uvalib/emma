# app/models/api_migrate.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API data migration.
#
class ApiMigrate

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # API migration configuration entries.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  CONFIGURATION_ENTRY = I18n.t('emma.api_migrate').deep_freeze

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  module ClassMethods

    include Emma::Json

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Default target record class.
    #
    # @return [Class<ApplicationRecord>]
    #
    def record_class
      not_implemented 'to be overridden by the including class/module'
    end

    # Record column(s) holding EMMA data.
    #
    # @return [Array<Symbol>]
    #
    def data_columns
      record_class.field_names.select { |f| f.match?('emma_data') }
    end

    # get_relation
    #
    # @param [Integer, Array<Integer>, String, Hash, nil] range
    #
    # @return [ActiveRecord::Relation]
    #
    def get_relation(range = nil)
      case range
        when String, Hash          then record_class.where(range)
        when Numeric, Array, Range then record_class.where(id: range)
        else                            record_class.all
      end.order(:id)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # API migration name (#CONFIGURATION_ENTRY key).
    #
    # @param [Symbol, String, Integer, Float, nil] key
    #
    # @return [Symbol, nil]
    #
    def migration_name(key)
      case key
        when Integer then "0.0.#{key}"
        when Numeric then '0.%0.1f' % key
        else              key.to_s
      end.tr('.', '_').to_sym.presence
    end

    # API migration configured field transformations.
    #
    # @param [Symbol, String, Integer, Float, nil] key  Default: latest
    #
    # @type [Hash{Symbol=>Hash}]
    #
    def configuration(key = nil)
      name = migration_name(key)
      name && CONFIGURATION_ENTRY[name] || {}
    end

    # Transform EMMA data fields.
    #
    # @param [Model, Hash]  record
    # @param [Symbol]       column    Default: :emma_data.
    # @param [Hash]         config
    # @param [Boolean]      report
    #
    # @return [Model, Hash]           Possibly modified *record*.
    #
    def transform!(record, column: nil, config: {}, report: false, **)
      column  ||= data_columns.first
      emma_data = record.try(column) || record[column]
      return record if emma_data.blank? || (emma_data == '{}')

      was_hash  = emma_data.is_a?(Hash)
      emma_data = parse_data(emma_data)
      original  = (emma_data.deep_dup if report)
      emma_data.transform_values! { |value| remove_blank(value) }
      emma_data.compact_blank!

      # Apply transformations for each field listed in the configuration.
      config.each_pair do |field, edit|

        # Remove field (unless the actual intent is to rename it).
        new_field = edit[:new_name].presence
        emma_data.delete(field) if edit[:delete_field] && !new_field
        next unless emma_data.include?(field)

        # Apply the configured transformations.
        value = emma_data[field]
        value = apply(  value, field, edit[:prepare])     if edit[:prepare]
        value = mutate( value, field, edit[:new_values])  if edit[:new_values]
        value = apply(  value, field, edit[:normalize])   if edit[:normalize]
        value = reshape(value, field, edit[:new_min_max]) if edit[:new_min_max]

        # Change name or update field data.
        emma_data.delete(field)  if new_field || value.blank?
        field = new_field.to_sym if new_field
        emma_data[field] = value if value.present?
      end

      # Log changes made to the data field value(s).
      # noinspection RubyMismatchedParameterType
      report_changes(original, emma_data, column) if report

      # Replace the data in the target record column.
      record[column] = was_hash ? emma_data : emma_data.to_json
      record
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Transform the value by applying each requested method.
    #
    # @param [*]      value
    # @param [Symbol] field
    # @param [Array]  meths
    #
    # @return [*]
    #
    def apply(value, field, meths)
      Array.wrap(meths).each do |meth|
        if respond_to?(meth)
          value = send(meth, value)
        else
          Log.warn("ApiMigrate: #{field}: #{meth}: invalid")
        end
      end
      value
    end

    # Translate values.
    #
    # @param [*]      value
    # @param [Symbol] _field
    # @param [Hash]   changes
    #
    # @return [*]
    #
    def mutate(value, _field, changes)
      return value if changes.blank?
      is_array = value.is_a?(Array)
      value    = to_array(value) unless is_array
      value.map! do |item|
        changes.find do |new_item, old_item_patterns|
          found =
            Array.wrap(old_item_patterns).any? do |pattern|
              pattern.is_a?(Regexp) ? (item =~ pattern) : (item == pattern)
            end
          break new_item.to_s if found
        end || item
      end
      is_array ? value : from_array(value)
    end

    # Change cardinality (single to array or array to single) based on the
    # specified range of values.
    #
    # @param [*]            value
    # @param [Symbol]       field
    # @param [Array, Range] range
    #
    # @return [*]
    #
    def reshape(value, field, range)
      return value if range.blank?
      new_min = range.first || 0
      new_max = range.last  || 999_999_999
      if new_min > new_max
        Log.warn("ApiMigrate: #{field}: new_min_max: #{new_min} > #{new_max}")
      elsif new_max == 1
        from_array(value)
      elsif (new_min > 1) || (new_max > 1)
        to_array(value)
      else
        value
      end
    end

    # Transform a multi-item value into a single-item value.
    #
    # @param [Array, *] value
    # @param [String]   separator
    #
    # @return [*]
    #
    def from_array(value, separator = "\n")
      return value unless value.is_a?(Array)
      value.all? { |v| v.is_a?(String) } ? value.join(separator) : value.first
    end

    # Transform a single-item value into an array of items.
    #
    # @param [*]      value
    # @param [String] separator
    #
    # @return [Array]
    #
    def to_array(value, separator = "\n")
      return value if value.is_a?(Array)
      value.is_a?(String) ? value.split(separator) : Array.wrap(value)
    end

    # report_changes
    #
    # @param [Hash]   original
    # @param [Hash]   current
    # @param [Symbol] record_field
    #
    # @return [void]
    #
    def report_changes(original, current, record_field = nil)
      changes = {}
      original.each_pair do |k, v|
        next if v == (now = current[k])
        changes[k] = [v, now]
      end
      current.each_pair do |k, v|
        next if changes.include?(k) || (v == (was = original[k]))
        changes[k] = [was, v]
      end
      $stderr.puts "\n#{record_field.inspect}" if record_field
      if changes.blank?
        $stderr.puts 'NO CHANGES'
      else
        divider = '-' * 72
        $stderr.puts divider
        changes.each_pair do |k, values|
          values.prepend(k).map!(&:inspect)
          $stderr.puts '--- %-25s | WAS: %s | NOW: %s' % values
        end
        $stderr.puts divider
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Transform JSON EMMA data.
    #
    # If an :emma_data field won't parse it could be because one or more data
    # fields contains an unescaped double-quote, making the entry invalid JSON.
    #
    # This method attempts to correct that by protecting all of the valid
    # instances of unescaped double-quotes and escaping any double-quotes
    # remaining in the string before reapplying #json_parse.
    #
    # @param [String] data
    #
    # @return [Hash]
    #
    #--
    # noinspection RubyMismatchedReturnType
    #++
    def parse_data(data)
      json_parse(data, no_raise: false) || {}
    rescue
      # noinspection RubyUnusedLocalVariable
      patterns = {
        (char = "\001")    => { value: '{"',   regex: /\A{"/ },
        (char = char.succ) => { value: '":["', regex: /":\["/ },
        (char = char.succ) => { value: '"],"', regex: /"\],"/ },
        (char = char.succ) => { value: '":"',  regex: /":"/ },
        (char = char.succ) => { value: '","',  regex: /","/ },
        (char = char.succ) => { value: '"}',   regex: /"}\z/ },
      }
      data = data.strip
      patterns.each_pair { |marker, entry| data.gsub!(entry[:regex], marker) }
      data.gsub!(/([^\\])"/, '\1\\"')
      patterns.each_pair { |marker, entry| data.gsub!(marker, entry[:value]) }
      json_parse(data) || {}
    end

    # Remove blank values.
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>, String, nil]
    #
    def remove_blank(value)
      if value.is_a?(Array)
        value.map { |v| remove_blank(v) }.compact.presence
      else
        value unless value.blank? || (value == ModelHelper::EMPTY_VALUE)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Bogus :dc_creator values found via
    # "https://emma.lib.virginia.edu/data/counts".
    #
    # @type [Array<String,Regexp>]
    #
    BOGUS_CREATOR = [
      /Adobe\s*InDesign/i,
      /Adobe\s*Acrobat/i,
      /Quark\s*XPress/i,
      /OfficeJet/i
    ].deep_freeze

    # Remove bogus :dc_creator values which are probably due to file metadata
    # extraction where the "creator" is actually the creator of the PDF or
    # Word document as opposed to the creator of the source creative work.
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>, String]
    #
    def normalize_creator(value)
      if value.is_a?(Array)
        value.map { |v| normalize_creator(v) }.compact
      else
        BOGUS_CREATOR.find do |match|
          return if match.is_a?(Regexp) ? (value =~ match) : (value == match)
        end || value
      end
    end

    # normalize_identifier
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>]
    #
    def normalize_identifier(value)
      if value.is_a?(Array)
        value.flat_map { |v| normalize_identifier(v) }.compact
      else
        values = value.split(Api::Shared::IdentifierMethods::ID_SEPARATOR)
        values.map { |v| PublicationIdentifier.cast(v)&.to_s }.compact
      end
    end

    # normalize_day
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>, String, nil]
    #
    def normalize_day(value)
      if value.is_a?(Array)
        value.map { |v| normalize_day(v) }.compact
      else
        value.to_s if (value = IsoDay.new(value)).valid?
      end
    end

    # normalize_datetime
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>, String, nil]
    #
    def normalize_datetime(value)
      if value.is_a?(Array)
        value.map { |v| normalize_datetime(v) }.compact
      else
        value.to_s if (value = IsoDate.new(value)).valid?
      end
    end

    # Reduce an array of quality values to the single highest value.
    #
    # @param [Array<String>, String] value
    #
    # @return [String, nil]
    #
    # == Usage Notes
    # This is expected to operate on already-translated field values.
    #
    # == Implementation Notes
    # The source enumeration is expected to be ordered from lowest to highest
    # quality.
    #
    def summarize_quality(value)
      # noinspection RubyMismatchedReturnType
      return value unless value.is_a?(Array)
      TextQuality.values.reverse.find { |v| value.include?(v) }
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
    end

  end

  include ClassMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Associated "en.emma.api_migrate" key.
  #
  # @type [Symbol]
  #
  attr_reader :name

  # Produce additional log output for debugging.
  #
  # @type [Boolean]
  #
  attr_reader :report

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Symbol, String, Integer, Float, nil] key    Default: latest.
  # @param [Boolean]                             report
  # @param [Boolean]                             no_raise
  #
  def initialize(key = nil, report: nil, no_raise: false, **)
    @report = report.present?
    @name   = key ? migration_name(key) : CONFIGURATION_ENTRY.keys.last
    error   =
      if !@name
        "invalid configuration name #{key.inspect}"
      elsif !CONFIGURATION_ENTRY.include?(@name)
        "invalid configuration #{@name.inspect}"
      elsif CONFIGURATION_ENTRY[@name].blank?
        "empty configuration #{@name.inspect}"
      end
    if (error &&= "ApiMigrate: #{error}")
      Log.warn(error)
      raise error unless no_raise
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Run the data migrations.
  #
  # @param [Boolean] update           If *false*, the database is not updated.
  # @param [*]       range            For #get_relation.
  # @param [Hash]    opt              Passed to #transform!.
  #
  # @return [void]
  #
  def run!(update: false, range: nil, **opt) # TODO: update: true
    records = get_relation(range).map { |rec| transform!(rec.fields, **opt) }
    record_class.upsert_all(records) if update
  end

  # ===========================================================================
  # :section: ApiMigrate::ClassMethods overrides
  # ===========================================================================

  public

  # Default target record class.
  #
  # @return [Class<ApplicationRecord>]
  #
  def record_class
    Upload
  end

  # ===========================================================================
  # :section: ApiMigrate::ClassMethods overrides
  # ===========================================================================

  public

  # API migration name (#CONFIGURATION_ENTRY key).
  #
  # @param [Symbol, String, Integer, Float, nil] key  Default: `#name`.
  #
  # @return [Symbol, nil]
  #
  def migration_name(key = nil)
    key ? super(key) : name
  end

  # API migration configured field transformations.
  #
  # @param [Symbol, String, Integer, Float, nil] key  Default: `#name`.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  def configuration(key = nil)
    key ? super(key) : CONFIGURATION_ENTRY[name]
  end

  # Transform fields.
  #
  # @param [Model, Hash]           record
  # @param [Symbol, Array<Symbol>] column   Default: `#data_columns`
  # @param [Hash, nil]             config   Default: `#configuration`.
  # @param [Boolean]               report   Default: `#report`
  #
  # @return [Model, Hash]             Possibly modified *record*.
  #
  def transform!(record, column: nil, config: nil, report: nil, **)
    cfg  = config || configuration
    log  = report.nil? ? @report : report
    $stderr.puts "\n*** Upload #{record[:id]} ***" if log
    cols = column ? Array.wrap(column) : data_columns
    cols.each { |col| super(record, column: col, config: cfg, report: log) }
    if log
      cols.each do |col|
        data = record[col]
        $stderr.puts "\n#{col.inspect} =\n#{data}" if data.present?
      end
    end
    record
  end

end

__loading_end(__FILE__)
