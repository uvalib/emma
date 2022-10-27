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
  # To ensure idempotent translations, for each new value, the value itself is
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

  #--
  # noinspection RubyTooManyMethodsInspection
  #++
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
    def transform!(record, column: nil, config: configuration, **opt)
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
    # @param [Any]       value
    # @param [Array]     meths
    # @param [Symbol]    field
    # @param [Hash, nil] emma_data
    #
    # @return [Any]
    #
    def pre_translate(value, meths, field:, emma_data: nil, **)
      apply(value, meths, field: field, emma_data: emma_data) if value.present?
    end

    # Translate values.
    #
    # @param [Any]     value
    # @param [Hash]    translations
    # @param [Boolean] unique         If *false*, do not prune results.
    #
    # @return [Any]
    #
    def translate(value, translations, unique: true, **)
      return value if value.blank? || translations.blank?
      is_array = value.is_a?(Array)
      value    = is_array ? value.dup : to_array(value)
      value.map! do |item|
        translations.find do |new_item, old_item_patterns|
          found =
            old_item_patterns.any? do |pattern|
              pattern.is_a?(Regexp) ? (item =~ pattern) : (item == pattern)
            end
          break new_item.to_s if found
        end || item
      end
      value.uniq! if unique
      is_array ? value : from_array(value)
    end

    # Transform the value after #translate by applying each requested method.
    #
    # @param [Any]       value
    # @param [Array]     meths
    # @param [Symbol]    field
    # @param [Hash, nil] emma_data
    #
    # @return [Any]
    #
    def post_translate(value, meths, field:, emma_data: nil, **)
      apply(value, meths, field: field, emma_data: emma_data) if value.present?
    end

    # Transform the value by applying each requested method.
    #
    # @param [Any]    value
    # @param [Array]  meths
    # @param [Symbol] field
    #
    # @return [Any]
    #
    def normalize(value, meths, field:, **)
      apply(value, meths, field: field) if value.present?
    end

    # Change cardinality (single to array or array to single) based on the
    # specified range of values.
    #
    # @param [Any]          value
    # @param [Array, Range] range
    # @param [Symbol]       field
    #
    # @return [Any]
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
    # @param [Any]       value
    # @param [Array]     meths
    # @param [Symbol]    field
    # @param [Hash, nil] emma_data
    #
    # @return [Any]
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
    # @param [Any]    value
    # @param [String] separator
    #
    # @return [Any]                   The *value* itself if it was not an Array
    #
    def from_array(value, separator = "\n")
      return value unless value.is_a?(Array)
      value.all? { |v| v.is_a?(String) } ? value.join(separator) : value.first
    end

    # Transform a single-item value into an array of items.
    #
    # @param [Any]    value
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
        __output("\n#{column.inspect}")
        if changes.blank?
          __output('NO CHANGES')
        else
          col = $stderr.tty? ? [79, 25, 25] : [120, 35, 35]
          __output(divider = '-' * col[0])
          changes.each_pair do |k, values|
            field = [k, *values].map!(&:inspect)
            __output("--- %-#{col[1]}s NOW: %-#{col[2]}s WAS: %s" % field)
          end
          __output(divider)
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
    # Strings are conditioned by replacing HTML entities with Unicode
    # characters and by replacing Unicode characters with ASCII characters
    # where possible.
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>, String, Any]    Nil for an empty array.
    #
    def remove_blank(value)
      value = value.map { |v| remove_blank(v) }.compact if value.is_a?(Array)
      value = CGI.unescapeHTML(value.strip).scrub       if value.is_a?(String)
      value unless value.blank? || (value == BaseDecorator::EMPTY_VALUE)
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
      /Adobe\s*Acrobat/i,
      /Adobe\s*Illustrator/i,
      /Adobe\s*InDesign/i,
      /Office\s*Jet/i,
      /Quark\s*XPress/i,
    ].deep_freeze

    # Remove bogus :dc_creator values which are probably due to file metadata
    # extraction where the "creator" is actually the creator of the PDF or
    # Word document as opposed to the creator of the source creative work.
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>, String]
    #
    #--
    # noinspection RubyMismatchedReturnType
    #++
    def normalize_creator(value)
      if value.is_a?(Array)
        value.flat_map { |v| normalize_creator(v) }.compact.uniq
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
      PublicationIdentifier.objects(value).compact.map(&:to_s).uniq
    end

    # normalize_day
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>, String, nil]
    #
    def normalize_day(value)
      if value.is_a?(Array)
        # noinspection RubyMismatchedReturnType
        value.flat_map { |v| normalize_day(v) }.compact
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
        # noinspection RubyMismatchedReturnType
        value.flat_map { |v| normalize_datetime(v) }.compact
      else
        value.to_s if (value = IsoDate.new(value)).valid?
      end
    end

    # normalize_metadata_source
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>]
    #
    def normalize_metadata_source(value)
      if value.is_a?(Array)
        # noinspection RubyMismatchedReturnType
        value.flat_map { |v| normalize_metadata_source(v) }.uniq
      else
        values = normalize_text_list(value)
        # noinspection SpellCheckingInspection
        values.map { |v| v.gsub('Vanderbitl', 'Vanderbilt') }
      end
    end

    # Split values on '.', ',', and ';'.
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>]
    #
    def normalize_text_list(value)
      value = Array.wrap(value).join("\n") unless value.is_a?(String)
      value.split(/(?<=\w)\.(?=\s|\z)|[,;|\t\n]/).map(&:strip).compact_blank!
    end

    # normalize_coverage
    #
    # @param [Array<String>, String] value
    #
    # @return [Array<String>, String]
    #
    def normalize_coverage(value)
      coverage = from_array(value)
      coverage = '(NONE)' if coverage&.match?(%r{^(NA|N/A|none)[[:punct:]]*$}i)
      value = value.is_a?(Array) ? [coverage] : coverage if coverage
      value
    end

    # Ensure that a field designated as 'boolean' is not persisted as a String.
    #
    # @param [Array, Any, nil] value
    #
    # @return [Array<Boolean>, Boolean, nil]
    #
    def normalize_boolean(value)
      return              if value.nil?
      return true?(value) unless value.is_a?(Array)
      # noinspection RubyNilAnalysis
      value.flat_map { |v| normalize_boolean(v) }
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
        add_values(emma_data, COMMENT_FIELDS, other, single: true)
        value -= other
      end
      array ? value : value.first
    end

    # FormatFeature translations
    #
    # @type [Hash]
    #
    FORMAT_FEATURE_MIGRATION = {
      emma_formatFeature: {
        translate:
          FormatFeature.values.map { |k|
            v = k.sub(/\d+/, '_\0').underscore.gsub('_', ' *')
            v = /(?<=\W)#{v}(\W|\z)/i
            [k.to_sym, Array.wrap(v)]
          }.to_h
      }
    }.deep_freeze

    # Process :emma_lastRemediationNote by adding to :emma_formatFeature any
    # values which can be detected.  The original value is returned.
    #
    # @param [String] value
    # @param [Hash]   emma_data
    #
    # @return [String]
    #
    def extract_format_feature(value, emma_data)
      add_translations(emma_data, value, FORMAT_FEATURE_MIGRATION)
      value
    end

    # RemediatedAspects translations
    #
    # @type [Hash]
    #
    REMEDIATION_MIGRATION =
      CONFIGURATION_ENTRY.dig(:'0_0_5', :rem_remediation, :translate)

    # EMMA data fields that have, do, or will contain remediation comments.
    #
    # @type [Array<Symbol>]
    #
    ASPECT_FIELDS = %i[rem_remediation rem_remediatedAspects].freeze

    # Process :emma_lastRemediationNote by adding to :rem_remediatedAspects any
    # values which can be detected.  The original value is returned.
    #
    # @param [String] value
    # @param [Hash]   emma_data
    #
    # @return [String]
    #
    # == Implementation Notes
    # In order to avoid requiring that the API field migrations be done in a
    # specific sequence, this method will favor the pre-migrated field names
    # if they are present.
    #
    def extract_remediated_aspects(value, emma_data)
      add_translations(emma_data, value, REMEDIATION_MIGRATION, ASPECT_FIELDS)
      value
    end

    # Set a default :rem_coverage if none was provided unless :rem_status has
    # a value (in which case, this is deferred until the post-translate step
    # for :rem_status).  The new value is returned.
    #
    # @param [Array<String>, String] value
    # @param [Hash]                  emma_data
    #
    # @return [Array<String>, String]
    #
    # @see #derive_default_coverage
    #
    def set_default_coverage(value, emma_data)
      default = emma_data[:rem_status].blank?
      default &&= default_coverage(value, emma_data)
      value = value.is_a?(Array) ? [default] : default if default
      value
    end

    # Based on :rem_status (and :rem_complete) add a :rem_coverage comment if
    # none exists.  The original value is returned.
    #
    # @param [String] value
    # @param [Hash]   emma_data
    #
    # @return [String]
    #
    # @see #set_default_coverage
    #
    def derive_default_coverage(value, emma_data)
      default = default_coverage(emma_data[:rem_coverage], emma_data)
      emma_data[:rem_coverage] = default if default
      value
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # If the current :rem_coverage is missing or is an automatically-generated
    # value, return a default value based on :rem_status and :rem_complete.
    #
    # @param [Array<String>, String] current    Current :rem_coverage value.
    # @param [Hash]                  emma_data
    #
    # @return [String, nil]
    #
    def default_coverage(current, emma_data)
      current = from_array(current)
      return unless current.blank? || current.match?(/^\([A-Z]+\)$/)
      default =
        case
          when emma_data[:rem_status] == 'notRemediated' then 'NONE'
          when true?(emma_data[:rem_complete])           then 'ALL'
          else                                                'UNKNOWN'
        end
      '(%s)' % default # TODO: I18n
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Find terms within *value* and add them to the indicated data field.
    #
    # @param [Hash]                       emma_data
    # @param [String]                     value
    # @param [Hash]                       patterns
    # @param [Array<Symbol>, Symbol, nil] fields
    #
    # @return [void]
    #
    def add_translations(emma_data, value, patterns, fields = nil)
      return if value.blank?
      field    = fields && find_field(emma_data, fields) || patterns.keys.last
      patterns = patterns[field]      if patterns.key?(field)
      patterns = patterns[:translate] if patterns.key?(:translate)
      phrases  = normalize_text_list(value)
      terms    = translate(phrases, patterns, unique: false)
      add_values(emma_data, field, (terms - phrases))
    end

    # Add one or more values to the indicated data field.
    #
    # @param [Hash]                  emma_data
    # @param [Symbol, Array<Symbol>] fields
    # @param [String, Array<String>] values
    # @param [Boolean]               unique
    # @param [Boolean, nil]          single
    #
    # @return [Any]                   New value of `emma_data[field]`.
    #
    def add_values(emma_data, fields, values, unique: true, single: nil)
      field   = find_field(emma_data, fields) or return
      current = emma_data[field]
      return current                             if values.blank?
      single  = current && !current.is_a?(Array) if single.nil?
      changed = [*current, *values].compact_blank!
      changed.uniq!                              if unique
      changed = changed.join("\n")               if single
      emma_data[field] = changed
    end

    # To avoid requiring that the API field migrations be performed in a
    # specific order, this method supports the ability to arrange potential
    # target fields so that pre-migrated fields will be favored if they are
    # present.
    #
    # If none are present, the last (or only) supplied field name is returned.
    #
    # @param [Hash]                       emma_data
    # @param [Array<Symbol>, Symbol, nil] fields
    #
    # @return [Symbol, nil]
    #
    def find_field(emma_data, fields)
      if fields.is_a?(Array)
        # noinspection RubyNilAnalysis
        fields.find { |f| emma_data[f] } || fields.last
      else
        fields&.to_sym
      end
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
    # noinspection RubyMismatchedVariableType
    @name   = key ? migration_name(key) : CONFIGURATION_ENTRY.keys.last
    # noinspection RubyMismatchedArgumentType
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
  # @param [Any]     range            For #get_relation.
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
    key ? super : name
  end

  # API migration configured field transformations.
  #
  # @param [Symbol, String, Integer, Float, nil] key  Default: `#name`.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  def configuration(key = nil)
    key ? super : CONFIGURATION_ENTRY[name]
  end

  # ===========================================================================
  # :section: ApiMigrate::ClassMethods overrides
  # ===========================================================================

  public

  # Transform fields.
  #
  # @param [Model, Hash]           record
  # @param [Symbol, Array<Symbol>] column
  # @param [Hash]                  opt
  #
  # @option opt [Hash, nil]    :report      Add modified field value(s).
  # @option opt [Boolean, nil] :log         Log modified field value(s).
  #
  # @return [Model, Hash]             Possibly modified *record*.
  #
  def transform!(record, column:, **opt)
    log, rpt = opt.values_at(:log, :report)
    if rpt
      # noinspection RubyNilAnalysis
      rpt[:table]  ||= record_class.name.tableize
      rpt[:record] ||= {}
      opt[:report] = rpt = rpt[:record][record[:id]] ||= {}
    end
    __output "\n*** Upload #{record[:id]} ***" if log
    cols = Array.wrap(column).each { |col| super(record, column: col, **opt) }
    flds = (record.slice(*cols).compact if rpt || log)
    flds.each { |fld, dat| __output "\n#{fld.inspect} =\n#{dat}" }   if log
    rpt[:results] = flds.transform_values { |v| safe_json_parse(v) } if rpt
    record
  end

end

__loading_end(__FILE__)
