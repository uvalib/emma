# app/models/api_migrate.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API data migration.
#
# @see "en.emma.api_migrate"
#
class ApiMigrate

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # API migration configuration entries.
  #
  # To ensure idempotent translations, for each new value, that value is
  # included at the start of the list of old item pattern matches.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  CONFIGURATION_ENTRY =
    I18n.t('emma.api_migrate').map { |name, entries|
      next if name.start_with?('_')
      entries =
        entries.map { |field, entry|
          next if field.start_with?('_')
          translations = entry[:translate].presence
          translations &&=
            translations.map { |new_item, old_item_patterns|
              next if old_item_patterns.nil?
              patterns = [new_item.to_s, *old_item_patterns].compact.uniq
              [new_item, patterns]
            }.compact.to_h.presence
          entry = entry.merge(translate: translations).compact
          [field, entry] if entry.present?
        }.compact.to_h
      [name, entries] if entries.present?
    }.compact.to_h.deep_freeze

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

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The sequence of possible field transformations.
    #
    # @type [Array<Symbol>]
    #
    # @see "en.emma.api_migrate._template"
    #
    TRANSFORMATION_STEPS = %i[
      pre_translate
      translate
      post_translate
      normalize
      new_min_max
    ].freeze

    # Transform EMMA data fields.
    #
    # @param [Model, Hash]  record
    # @param [Symbol]       column    Default: :emma_data.
    # @param [Hash]         config
    # @param [Hash]         opt       Passed to #report_changes.
    #
    # @return [Model, Hash]           Possibly modified *record*.
    #
    def transform!(record, column: nil, config: {}, **opt)
      column  ||= data_columns.first || :emma_data
      emma_data = record.try(column) || record[column]
      return record if emma_data.blank? || (emma_data == '{}')

      opt.slice!(:report, :log)
      was_hash  = emma_data.is_a?(Hash)
      emma_data = parse_data(emma_data)
      original  = (emma_data.deep_dup if opt.present?)
      emma_data.transform_values! { |value| remove_blank(value) }
      emma_data.compact_blank!

      # Apply transformations for each field listed in the configuration.
      config.each_pair do |field, edit|

        # Remove field if directed (unless the actual intent is to rename it).
        new_field = edit[:new_name].presence
        emma_data.delete(field) if edit[:delete_field] && !new_field
        next unless emma_data.include?(field)

        # Apply the configured transformations.
        value = emma_data[field]
        TRANSFORMATION_STEPS.each do |step|
          next if (change = edit[step]).blank?
          value = send(step, value, change, field: field, emma_data: emma_data)
        end

        # Change name or update field data.
        emma_data.delete(field)  if new_field || value.blank?
        field = new_field.to_sym if new_field
        emma_data[field] = value if value.present?
      end

      # Log changes made to the data field value(s).
      report_changes(column, original, emma_data, **opt) if opt.present?

      # Replace the data in the target record column.
      record[column] = was_hash ? emma_data : emma_data.to_json
      record
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Transform the value before #translate by applying each requested method.
    #
    # @param [*]         value
    # @param [Array]     meths
    # @param [Symbol]    field
    # @param [Hash, nil] emma_data
    #
    # @return [*]
    #
    def pre_translate(value, meths, field:, emma_data: nil, **)
      apply(value, meths, field: field, emma_data: emma_data) if value.present?
    end

    # Translate values.
    #
    # @param [*]      value
    # @param [Hash]   translations
    #
    # @return [*]
    #
    def translate(value, translations, **)
      return value if value.blank? || translations.blank?
      is_array = value.is_a?(Array)
      value    = to_array(value) unless is_array
      value.map! do |item|
        translations.find do |new_item, old_item_patterns|
          found =
            old_item_patterns.any? do |pattern|
              pattern.is_a?(Regexp) ? (item =~ pattern) : (item == pattern)
            end
          break new_item.to_s if found
        end || item
      end
      value.uniq!
      is_array ? value : from_array(value)
    end

    # Transform the value after #translate by applying each requested method.
    #
    # @param [*]         value
    # @param [Array]     meths
    # @param [Symbol]    field
    # @param [Hash, nil] emma_data
    #
    # @return [*]
    #
    def post_translate(value, meths, field:, emma_data: nil, **)
      apply(value, meths, field: field, emma_data: emma_data) if value.present?
    end

    # Transform the value by applying each requested method.
    #
    # @param [*]      value
    # @param [Array]  meths
    # @param [Symbol] field
    #
    # @return [*]
    #
    def normalize(value, meths, field:, **)
      apply(value, meths, field: field) if value.present?
    end

    # Change cardinality (single to array or array to single) based on the
    # specified range of values.
    #
    # @param [*]            value
    # @param [Array, Range] range
    # @param [Symbol]       field
    #
    # @return [*]
    #
    def new_min_max(value, range, field:, **)
      return value if value.blank? || range.blank?
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

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Transform the value by applying each requested method.
    #
    # @param [*]         value
    # @param [Array]     meths
    # @param [Symbol]    field
    # @param [Hash, nil] emma_data
    #
    # @return [*]
    #
    def apply(value, meths, field:, emma_data: nil, **)
      Array.wrap(meths).each do |meth|
        if !respond_to?(meth)
          Log.warn("ApiMigrate: #{field}: invalid method #{meth.inspect}")
        elsif method(meth).arity.abs > 1
          value = send(meth, value, emma_data)
        else
          value = send(meth, value)
        end
      end
      value
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
    # @param [Symbol]       column
    # @param [Hash]         original
    # @param [Hash]         current
    # @param [Hash, nil]    report
    # @param [Boolean, nil] log
    #
    # @return [void]
    #
    def report_changes(column, original, current, report: nil, log: nil, **)
      changes = {}
      original.each_pair do |k, v|
        next if v == (now = current[k])
        changes[k] = [now, v]
      end
      current.each_pair do |k, v|
        next if changes.include?(k) || (v == (was = original[k]))
        changes[k] = [v, was]
      end
      if report
        report = report[:changes] ||= {}
        report = report[column]   ||= {}
        changes.each_pair do |k, values|
          report[k] = { now: values.first, was: values.last }
        end
      end
      if log
        $stderr.puts("\n#{column.inspect}")
        if changes.blank?
          $stderr.puts('NO CHANGES')
        else
          col = $stderr.tty? ? [79, 25, 25] : [120, 35, 35]
          $stderr.puts(divider = '-' * col[0])
          changes.each_pair do |k, values|
            field = [k, *values].map!(&:inspect)
            $stderr.puts("--- %-#{col[1]}s NOW: %-#{col[2]}s WAS: %s" % field)
          end
          $stderr.puts(divider)
        end
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
        value.map { |v| normalize_creator(v) }.compact.uniq
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
        value.flat_map { |v| normalize_identifier(v) }.compact.uniq
      else
        values = value.split(Api::Shared::IdentifierMethods::ID_SEPARATOR)
        values.map { |v| PublicationIdentifier.cast(v)&.to_s }.compact.uniq
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

    # Split values on '.', ',', and ';'.
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>]
    #
    def normalize_text_list(value)
      Array.wrap(value).join("\n").split(/ *[.,;\n] */).compact_blank!
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

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

    # EMMA data fields that have, do, or will contain remediation comments.
    #
    # @type [Array<Symbol>]
    #
    COMMENT_FIELDS =
      %i[emma_lastRemediationNote rem_remediationComments rem_comments].freeze

    # Complete :rem_remediation translation by moving untranslated items to
    # :rem_comments.
    #
    # @param [Array<String>, String] value
    # @param [Hash]                  emma_data
    #
    # @return [Array<String>, String, nil]
    #
    # == Implementation Notes
    # In order to avoid requiring that the API field migrations be done in a
    # specific sequence, this method will favor the pre-migrated field names
    # if they are present.
    #
    def preserve_remediation_comments(value, emma_data)
      array = value.is_a?(Array)
      value = Array.wrap(value)
      if (other = value - RemediatedAspects.values).present?
        f = COMMENT_FIELDS.find { |f| emma_data[f] } || COMMENT_FIELDS.last
        emma_data[f] = [*emma_data[f], *other].compact_blank.uniq.join("\n")
        value -= other
      end
      array ? value : value.first
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
  attr_reader :log

  # Generate a hash reporting on the changes for each record.
  #
  # @type [Hash, nil]
  #
  attr_reader :report

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Symbol, String, Integer, Float, nil] key        Default: latest.
  # @param [Boolean, Hash]                       report
  # @param [Boolean]                             log
  # @param [Boolean]                             no_raise
  #
  def initialize(key = nil, report: nil, log: nil, no_raise: false, **)
    @report = report.is_a?(Hash) ? report : ({} unless false?(report))
    @log    = log.present?
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
  # @param [Boolean] update           If *true*, the database is updated.
  # @param [*]       range            For #get_relation.
  # @param [Hash]    opt              Passed to #transform!.
  #
  # @return [Array{Hash}]             New record values.
  #
  def run!(update: false, range: nil, **opt)
    Log.info { '*** ApiMigrate DRY-RUN ***' } unless update
    opt[:column] = data_columns  unless opt.key?(:column)
    opt[:config] = configuration unless opt.key?(:config)
    opt[:report] = @report       unless opt.key?(:report)
    opt[:log]    = @log          unless opt.key?(:log)
    records = get_relation(range).map { |rec| transform!(rec.fields, **opt) }
    record_class.upsert_all(records) if update
    records
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
    # noinspection RubyMismatchedReturnType
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

  # ===========================================================================
  # :section: ApiMigrate::ClassMethods overrides
  # ===========================================================================

  public

  # Transform fields.
  #
  # @param [Model, Hash]           record
  # @param [Symbol, Array<Symbol>] column
  # @param [Hash]                  opt      Passed to super
  #
  # @option opt [Hash, nil]    :report      Add modified field value(s).
  # @option opt [Boolean, nil] :log         Log modified field value(s).
  #
  # @return [Model, Hash]             Possibly modified *record*.
  #
  def transform!(record, column:, **opt)
    log, rpt = opt.values_at(:log, :report)
    if rpt
      rpt[:table]  ||= record_class.name.tableize
      rpt[:record] ||= {}
      opt[:report] = rpt = rpt[:record][record[:id]] ||= {}
    end
    $stderr.puts "\n*** Upload #{record[:id]} ***" if log
    cols = Array.wrap(column).each { |col| super(record, column: col, **opt) }
    flds = (record.slice(*cols).compact if rpt || log)
    flds.each { |fld, dat| $stderr.puts "\n#{fld.inspect} =\n#{dat}" } if log
    rpt[:results] = flds.transform_values { |v| safe_json_parse(v) }   if rpt
    record
  end

end

__loading_end(__FILE__)
