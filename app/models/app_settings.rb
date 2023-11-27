# app/models/app_global.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class AppSettings < AppGlobal

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  CACHE_KEY = :settings

  # Boolean configuration value keys, partitioned into "sections" by nils.
  #
  # @type [Array<Symbol,nil>]
  #
  FLAGS = [

    :CONSOLE_DEBUGGING,
    :CONSOLE_OUTPUT,
    nil,

    :TRACE_OUTPUT,
    :TRACE_LOADING,
    :TRACE_CONCERNS,
    :TRACE_NOTIFICATIONS,
    :TRACE_RAKE,
    nil,

    :DEBUG_ATTRS,
    :DEBUG_AWS,
    :DEBUG_CABLE,
    :DEBUG_CONFIGURATION,
    :DEBUG_CORS,
    :DEBUG_DECORATOR_EXECUTE,
    :DEBUG_IMPORT,
    :DEBUG_IO,
    :DEBUG_JOB,
    :DEBUG_LOCKSTEP,
    :DEBUG_MIME_TYPE,
    :DEBUG_OAUTH,
    :DEBUG_PUMA,
    :DEBUG_RECORD,
    :DEBUG_REPRESENTABLE,
    :DEBUG_SHRINE,
    :DEBUG_SPROCKETS,
    :DEBUG_THREADS,
    :DEBUG_TRANSMISSION,
    :DEBUG_VIEW,
    :DEBUG_WORKFLOW,
    :DEBUG_XML_PARSE,
    :DEBUG_ZEITWERK,
    nil,

    :SAVE_SEARCHES,
    :IMPLEMENT_OVERRIDES,
    nil,

    :PUMA_LOG_REQUESTS, # NOTE: Might not be changeable...
    nil,

    :SERVICE_UNAVAILABLE,

  ].freeze

  # Other configuration setting keys, partitioned into "sections" by nils.
  #
  # @type [Array<Symbol,nil>]
  #
  #--
  # noinspection SpellCheckingInspection
  #++
  VALUES = [

    :RAILS_ENV,
    :DEPLOYMENT,
    nil,

    # === Bulk Upload
    :BATCH_SIZE,
    :BULK_DB_BATCH_SIZE,
    :DISABLE_UPLOAD_INDEX_UPDATE,
    nil,

    # === Database
    :DATABASE,
    :DBHOST,
    :DBPORT,
    :DBUSER,
    :DBPASSWD,
    nil,

    # === Postgres
    :PGPORT,
    :PGHOST,
    :PGUSER,
    :PGPASSWORD,
    nil,

    # === Authorization
    :AUTH_PROVIDERS,
    :SHIBBOLETH,
    nil,

    # === Mailer
    :MAILER_SENDER,
    :SMTP_DOMAIN,
    :SMTP_PORT,
    nil,

    # === Amazon Web Services
    :AWS_BUCKET,
    :AWS_REGION,
    :AWS_DEFAULT_REGION,
    :AWS_ACCESS_KEY_ID,
    :AWS_SECRET_KEY,
    nil,

    # === EMMA Unified Search API
    :SEARCH_API_VERSION,
    :SEARCH_BASE_URL,
    :SERVICE_SEARCH_PRODUCTION,
    :SERVICE_SEARCH_QA,
    :SERVICE_SEARCH_STAGING,
    nil,

    # === EMMA Unified Ingest API
    :INGEST_API_VERSION,
    :INGEST_API_KEY,
    :INGEST_BASE_URL,
    :SERVICE_INGEST_PRODUCTION,
    :SERVICE_INGEST_QA,
    :SERVICE_INGEST_STAGING,
    nil,

    # === Internet Archive
    :IA_DOWNLOAD_BASE_URL,
    :IA_ACCESS,
    :IA_SECRET,
    :IA_USER_COOKIE,
    :IA_SIG_COOKIE,
    nil,

    # === Benetech "Math Detective"
    :MD_API_KEY,
    :MD_BASE_PATH,
    nil,

    # === OCLC/WorldCat
    :WORLDCAT_API_KEY,
    :WORLDCAT_REGISTRY,
    :WORLDCAT_PRINCIPAL,
    nil,

    # === Google, Google Books, Google Search
    :GOOGLE_USER,
    :GOOGLE_PASSWORD,
    :GOOGLE_API_KEY,
    :GB_USER,
    :GB_PASSWORD,
    :GB_API_KEY,
    :GS_USER,
    :GS_PASSWORD,
    :GS_API_KEY,
    nil,

    # === Shrine uploader
    :SHRINE_CLOUD_STORAGE,
    :STORAGE_DIR,
    nil,

    # === Rails
    :SCRIPT_NAME,
    :RAILS_APP_VERSION,
    :RAILS_MIN_THREADS,
    :RAILS_MAX_THREADS,
    :RAILS_LOG_TO_STDOUT,
    :RAILS_SERVE_STATIC_FILES,
    :RAILS_CACHE_ID,
    :RAILS_MASTER_KEY,
    :SECRET_KEY_BASE,
    nil,

    # === GoodJob
    :GOOD_JOB_CRON,
    :GOOD_JOB_ENABLE_CRON,
    :GOOD_JOB_EXECUTION_MODE,
    :GOOD_JOB_MAX_CACHE,
    :GOOD_JOB_MAX_THREADS,
    :GOOD_JOB_PIDFILE,
    :GOOD_JOB_POLL_INTERVAL,
    :GOOD_JOB_PROBE_PORT,
    :GOOD_JOB_QUEUES,
    :GOOD_JOB_SHUTDOWN_TIMEOUT,
    :GOOD_JOB_CLEANUP_INTERVAL_JOBS,
    :GOOD_JOB_CLEANUP_INTERVAL_SECONDS,
    :GOOD_JOB_CLEANUP_PRESERVED_JOBS_BEFORE_SECONDS_AGO,
    nil,

    # === Puma
    :PORT,
    :PIDFILE,
    :WEB_CONCURRENCY,
    nil,

    # === Logging
    :LOG_SILENCER,
    :LOG_SILENCER_ENDPOINTS,
    :EMMA_LOG_FILTERING,
    :EMMA_LOG_AWS_FORMATTING,
    nil,

    # === Testing
    :PARALLEL_WORKERS,
    :TEST_FORMATS,
    nil,

    # === System
    :USER,
    :GROUP,
    :HOME,
    :TZ,
    :LANG,
    :LC_ALL,
    :LANGUAGE,
    :SMTP_DOMAIN,
    :SMTP_PORT,
    nil,

    # === Other
    :BUNDLE_GEMFILE,
    :DEBUGGER_STORED_RUBYLIB,
    :IN_PASSENGER,
    :REDIS_URL,
    :RUBYMINE_CONFIG,
    :SCHEDULER,

  ].freeze

  # Configuration field types.
  #
  # @type [Hash{Symbol=>Array<Symbol,nil>}]
  #
  TYPE_KEYS = {
    flag:    FLAGS,
    setting: VALUES,
  }.freeze

  if sanity_check?
    raise 'FLAGS and VALUES cannot overlap' if FLAGS.compact.intersect?(VALUES)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # An AppSettings value instance.
  #
  class Value

    # Either :flag or :setting.
    #
    # @return [Symbol]
    #
    attr_reader :type

    # The value if acquired from ENV.
    #
    # @return [*]
    #
    attr_reader :env

    # The value if acquired from a constant.
    #
    # @return [*]
    #
    attr_reader :obj

    # Whether this instance represents a *nil* value.
    #
    # @return [Boolean]
    #
    attr_reader :null

    # Whether this instance represents a non-value which can be used to
    # indicate a break between related groups of values.
    #
    # @return [Boolean]
    #
    attr_reader :spacer

    # Create a new instance which may represent either a value set from ENV,
    # a value set from a constant, a *nil* value, or a spacer.
    #
    # @param [Symbol, String, nil] type_key   Required if :type is not present.
    # @param [Hash]                opt
    #
    # @option opt [Symbol, String] :type
    # @option opt [*]              :env
    # @option opt [*]              :obj
    # @option opt [Boolean]        :null
    # @option opt [Boolean]        :spacer
    #
    def initialize(type_key = nil, **opt)
      # noinspection RubyMismatchedVariableType
      @type   = (opt.delete(:type) || type_key)&.to_sym
      keys    = opt.compact_blank.keys
      fail "cannot specify #{keys} together" if keys.many?
      @env_   = opt.key?(:env)
      @env    = opt.delete(:env)
      @obj_   = opt.key?(:obj)
      @obj    = opt.delete(:obj)
      @null   = opt.delete(:null)   || false
      @spacer = opt.delete(:spacer) || false
    end

    # Indicate whether the value was acquired from ENV (even if it is *nil*).
    #
    def env? = @env_

    # Indicate whether the value was acquired from a constant.
    #
    def obj? = @obj_

    # Indicate whether this instance represents a *nil* value.
    #
    def nil?    = null.present?

    # Indicate whether this instance represents a *nil* value.
    #
    def null?   = null.present?

    # Indicate whether this instance represents a non-value which can be used
    # to indicate a break between related groups of values.
    #
    def spacer? = spacer.present?

  end

  # A table of AppSettings value instances.
  #
  class Values < ::Hash

    include Emma::Common

    def initialize(keys)
      if keys.is_a?(Hash)
        super
      else
        keys.each { |k| acquire_value(k) }
      end
    end

    protected

    # Set the value at index *k* from either the associated `ENV` variable or
    # an associated constant.
    #
    # @param [Symbol, String, nil] k
    #
    # @return [Value]
    #
    def acquire_value(k)
      # noinspection RubyMismatchedArgumentType
      if (k = k&.to_s).nil?
        k = spacer_key
        v = { spacer: true }
      elsif ENV.key?(k)
        v = { env: storage_value(ENV[k]) }
      elsif (mod = module_defining(k))
        v = { obj: storage_value(mod.const_get(k)) }
      else
        v = { null: true }
      end
      self[k.to_sym] = Value.new(type_key, **v)
    end

    # Return the module that defines a constant with the given name.
    #
    # @param [Symbol, String] k
    #
    # @return [Module, nil]
    #
    def module_defining(k)
      k = k&.to_sym or return
      mods = {
        BATCH_SIZE:                   Record::Properties,
        BULK_DB_BATCH_SIZE:           UploadWorkflow::Bulk::External,
        DEBUG_DECORATOR_EXECUTE:      BaseDecorator::List,
        DISABLE_UPLOAD_INDEX_UPDATE:  Record::Submittable::IndexIngestMethods,
        SAVE_SEARCHES:                SearchConcern,
        WORLDCAT_PRINCIPAL_ID:        LookupService::WorldCat::Common,
        WORLDCAT_REGISTRY_ID:         LookupService::WorldCat::Common,
        WORLDCAT_WSKEY:               LookupService::WorldCat::Common,
      }
      [mods[k], Object].compact.find { |mod| mod.const_defined?(k) }
    end

    protected

    def self.type_key = must_be_overridden

    def self.spacer_key = must_be_overridden

    def self.storage_value(v) = must_be_overridden

    delegate :type_key, :spacer_key, :storage_value, to: :class

  end

  # A table of AppSettings flag values.
  #
  class FlagValues < Values

    def self.type_key
      :flag
    end

    def self.spacer_key
      # noinspection RbsMissingTypeSignature
      @spacer_key = @spacer_key&.succ || :"#{type_key}_1"
    end

    def self.storage_value(v)
      true?(v) unless v.nil?
    end

  end

  # A table of AppSettings non-flag settings values.
  #
  class SettingValues < Values

    def self.type_key
      :setting
    end

    def self.spacer_key
      # noinspection RbsMissingTypeSignature
      @spacer_key = @spacer_key&.succ || :"#{type_key}_1"
    end

    def self.storage_value(v)
      v
    end

  end

  module Methods

    include AppGlobal::Methods
    include Emma::Json

    # =========================================================================
    # :section: AppGlobal::Methods overrides
    # =========================================================================

    public

    # The value returned if global application settings were not present.
    #
    # @return [Hash]
    #
    def default
      {}
    end

    # Get global application settings values.
    #
    # @return [Hash{Symbol=>*}]
    #
    def get_item(**opt)
      filter_all(super, **opt)
    end

    # Set global application settings values.
    #
    # @param [Hash]    values
    # @param [Boolean] replace        If *true* erase current settings first.
    #
    # @return [Hash{Symbol=>*}]       The new settings.
    # @return [nil]                   If the write failed.
    #
    def set_item(values, replace: false, **opt)
      values = prepare_all(values, **opt) or return default
      values = get_item.deep_merge!(values) unless replace
      super(values)
    end

    # Initialize global application settings.
    #
    # @param [Hash, nil] values
    #
    # @return [Hash{Symbol=>*}]       The new settings.
    # @return [nil]                   If the write failed.
    #
    def reset_item(values = nil)
      values = prepare_all(values) || default
      super(values)
    end

    # =========================================================================
    # :section: AppGlobal::Methods overrides
    # =========================================================================

    protected

    # The key defined by the subclass.
    #
    # @return [Symbol]
    #
    def cache_key
      CACHE_KEY
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # filter_all
    #
    # @param [Hash]                       values
    # @param [Symbol, nil]                type
    # @param [Boolean]                    spacers
    # @param [Array<Symbol>, Symbol, nil] only
    #
    # @return [Hash]
    #
    def filter_all(values, type: nil, spacers: false, only: nil, **)
      only &&= Array.wrap(only).flatten.compact.presence
      only ||= TYPE_KEYS[type] if type
      values = values.select { |_, v| v.type == type } if type
      if only && spacers
        values.select { |k, v| v.spacer? || only.include?(k) }
      elsif only
        values.slice(*only)
      elsif spacers
        values
      else
        values.reject { |_, v| v.spacer? }
      end
    end

    # prepare_all
    #
    # @param [Hash, nil] values
    # @param [Hash]      opt          Passed to #filter_all.
    #
    # @return [Hash, nil]
    #
    def prepare_all(values, **opt)
      return if values.blank?
      values = values.transform_values { |v| prepare(v) }
      opt[:only] = FLAGS + VALUES if opt.slice(:only, :type).blank?
      # noinspection RubyMismatchedArgumentType
      filter_all(values, **opt)
    end

    # Recursively prepare a single item.
    #
    # @param [*] item
    #
    # @return [*]
    #
    def prepare(item)
      case item
        when nil, :nil, :null
          :null
        when Hash
          item.map { |k, v| [k.to_sym, prepare(v)] }.to_h.compact
        when Array
          item.map { |v| prepare(v) }.compact
        when String
          true?(item) || (false?(item) ? false : item)
        else
          item
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Render application settings for display (showing symbols appropriately).
    #
    # @param [Hash, nil] values       Default: all items.
    # @param [Hash]      opt          Passed to #filter_all.
    #
    # @return [String]
    #
    # @note Currently unused
    #
    #--
    # noinspection RubyMismatchedArgumentType
    #++
    def inspect_all(values = nil, **opt)
      values = values ? filter_all(values, **opt) : get_item(**opt)
      values = encode_symbols(values)
      values = pretty_json(values)
      decode_symbols(values)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Preserve symbols for resolution with #decode_symbols.
    #
    # @param [*] item
    #
    # @return [*]
    #
    def encode_symbols(item)
      case item
        when Hash   then item.transform_values { |v| encode_symbols(v) }
        when Array  then item.map { |v| encode_symbols(v) }
        when Symbol then encode_symbol(item)
        else             item
      end
    end

    # encode_symbol
    #
    # @param [Symbol] symbol
    #
    # @return [String]
    #
    def encode_symbol(symbol)
      ":#{symbol}:"
    end

    # decode_symbols
    #
    # @param [String] string
    #
    # @return [String]
    #
    def decode_symbols(string)
      string.gsub(/":([^\n]+):"/, ':\1')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    alias :get_all   :get_item
    alias :set_all   :set_item
    alias :reset_all :reset_item
    alias :clear_all :clear_item

    # Retrieve an individual setting.
    #
    # @param [Symbol, String] name
    #
    # @return [*]
    #
    def [](name)
      get_item[name.to_sym] if name
    end

    # Assign an individual setting.
    #
    # @param [Symbol, String] name
    # @param [*]              value
    #
    # @return [*]
    #
    def []=(name, value)
      name   = name.to_sym
      values = { name => value}
      set_item(values)&.dig(name)
    end

    # Iterate over each configuration flag.
    #
    # @param [Hash] opt               Passed to #each_pair
    #
    def each_flag(**opt, &blk)
      each_pair(type: :flag, **opt, &blk)
    end

    # Iterate over each configuration setting.
    #
    # @param [Hash] opt               Passed to #each_pair
    #
    def each_setting(**opt, &blk)
      each_pair(type: :setting, **opt, &blk)
    end

    # Iterate over each configuration value.
    #
    # @param [Hash] opt               Passed to #get_item.
    #
    # @yield [name, value] Operate on a configuration value.
    # @yieldparam [Symbol] name
    # @yieldparam [*]      value
    #
    def each_pair(**opt, &blk)
      get_item(**opt).each_pair(&blk)
    end

    alias :each :each_pair

    # Update global settings.
    #
    # @param [Hash, String, nil] values
    #
    # @return [Hash, nil]
    #
    def update(values)
      values = json_parse(values) if values.is_a?(String)
      # noinspection RubyMismatchedArgumentType
      set_item(values, replace: false)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include Methods

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  begin
    values = {}
    values.merge!(FlagValues.new(FLAGS))
    values.merge!(SettingValues.new(VALUES))
    set_item(values, replace: true, spacers: true)
  rescue => error
    Log.error("#{self} initialization failed")
    raise error
  end

end

__loading_end(__FILE__)
