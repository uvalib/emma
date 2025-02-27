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

    :SERVICE_UNAVAILABLE,
    :ANALYTICS_ENABLED,
    nil,

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
    :DEBUG_DECORATOR_COLLECTION,
    :DEBUG_DECORATOR_EXECUTE,
    :DEBUG_DECORATOR_INHERITANCE,
    :DEBUG_DOWNLOAD,
    :DEBUG_HASH,
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
    :DEBUG_TESTS,
    :DEBUG_THREADS,
    :DEBUG_TRANSMISSION,
    :DEBUG_VIEW,
    :DEBUG_WORKFLOW,
    :DEBUG_XML_PARSE,
    :DEBUG_ZEITWERK,
    nil,

    # === JavaScript client debug
    :JS_DEBUG_ACCESSIBILITY,
    :JS_DEBUG_ADVANCED_SEARCH,
    :JS_DEBUG_BASE_CLASS,
    :JS_DEBUG_BIB_LOOKUP,
    :JS_DEBUG_CABLE_CHANNEL,
    :JS_DEBUG_CABLE_CONSUMER,
    :JS_DEBUG_CALLBACKS,
    :JS_DEBUG_CHANNEL_LOOKUP,
    :JS_DEBUG_CHANNEL_REQUEST,
    :JS_DEBUG_CHANNEL_RESPONSE,
    :JS_DEBUG_CHANNEL_SUBMIT,
    :JS_DEBUG_CLIENT_DEBUG,
    :JS_DEBUG_DATABASE,
    :JS_DEBUG_DOWNLOAD,
    :JS_DEBUG_FLASH,
    :JS_DEBUG_GRIDS,
    :JS_DEBUG_IFRAME,
    :JS_DEBUG_IMAGES,
    :JS_DEBUG_INLINE_POPUP,
    :JS_DEBUG_LOOKUP_MODAL,
    :JS_DEBUG_LOOKUP_REQUEST,
    :JS_DEBUG_LOOKUP_RESPONSE,
    :JS_DEBUG_MANIFESTS,
    :JS_DEBUG_MANIFEST_EDIT,
    :JS_DEBUG_MANIFEST_REMIT,
    :JS_DEBUG_MATH_DETECTIVE,
    :JS_DEBUG_MENU,
    :JS_DEBUG_MODAL_BASE,
    :JS_DEBUG_MODAL_DIALOG,
    :JS_DEBUG_MODAL_HOOKS,
    :JS_DEBUG_MODEL_FORM,
    :JS_DEBUG_NAV_GROUP,
    :JS_DEBUG_OVERLAY,
    :JS_DEBUG_PANEL,
    :JS_DEBUG_QUEUE,
    :JS_DEBUG_RAILS,
    :JS_DEBUG_RECORDS,
    :JS_DEBUG_SCROLL,
    :JS_DEBUG_SEARCH,
    :JS_DEBUG_SEARCH_ANALYSIS,
    :JS_DEBUG_SEARCH_IN_PROGRESS,
    :JS_DEBUG_SESSION,
    :JS_DEBUG_SETUP,
    :JS_DEBUG_SKIP_NAV,
    :JS_DEBUG_SUBMIT_MODAL,
    :JS_DEBUG_SUBMIT_REQUEST,
    :JS_DEBUG_SUBMIT_RESPONSE,
    :JS_DEBUG_TABLE,
    :JS_DEBUG_TURBOLINKS,
    :JS_DEBUG_UPLOADER,
    :JS_DEBUG_XHR,
    nil,

    # === Search
    :SEARCH_EXTENDED_TITLE,
    :SEARCH_GENERATE_SCORES,
    :SEARCH_RELEVANCY_SCORE,
    :SEARCH_SAVE_SEARCHES,
    nil,

    # === Upload
    :UPLOAD_DEFER_INDEXING,
    :UPLOAD_EMERGENCY_DELETE,
    :UPLOAD_FORCE_DELETE,
    :UPLOAD_REPO_CREATE,
    :UPLOAD_REPO_EDIT,
    :UPLOAD_REPO_REMOVE,
    :UPLOAD_TRUNCATE_DELETE,
    nil,

    # === Bulk Upload
    :DISABLE_UPLOAD_INDEX_UPDATE,
    nil,

    # === Logging
    :EMMA_LOG_AWS_FORMATTING,
    :EMMA_LOG_FILTERING,
    nil,

    # === Puma
    :PUMA_DEBUG,
    :PUMA_LOG_REQUESTS, # NOTE: Might not be changeable...
    nil,

    # === Other
    :IMPLEMENT_OVERRIDES,
    :OAUTH_DEBUG,
    :SHIBBOLETH,
    :SHRINE_CLOUD_STORAGE,
    :STRICT_FORMATS,
    :TABLE_HEAD_DARK,
    :TABLE_HEAD_STICKY,
    :SESSION_DEBUG_CSS_CLASS,
    :SESSION_DEBUG_DATA_ATTR,
    nil,

  ].freeze

  # Other configuration setting keys, partitioned into "sections" by nils.
  #
  # @type [Array<Symbol,nil>]
  #
  VALUES = [

    :RAILS_ENV,
    :DEPLOYMENT,
    nil,

    # === Database
    :DATABASE,
    :DBNAME,
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

    # === Mailer
    :MAILER_SENDER,
    :SMTP_DOMAIN,
    :SMTP_PORT,
    nil,

    # === Authorization
    :AUTH_PROVIDERS,
    nil,

    # === EMMA Unified Search API
    :SEARCH_API_VERSION,
    :SERVICE_SEARCH_PRODUCTION,
    :SERVICE_SEARCH_STAGING,
    :SERVICE_SEARCH_TEST,
    nil,

    # === EMMA Unified Ingest API
    :INGEST_API_VERSION,
    :INGEST_API_KEY,
    :INGEST_MAX_SIZE,
    :SERVICE_INGEST_PRODUCTION,
    :SERVICE_INGEST_STAGING,
    :SERVICE_INGEST_TEST,
    nil,

    # === Bulk Upload
    :BATCH_SIZE,
    :BULK_DB_BATCH_SIZE,
    :BULK_THROTTLE_PAUSE,
    :REINDEX_BATCH_SIZE,
    :UPLOAD_DEV_TITLE_PREFIX,
    nil,

    # === Amazon Web Services for EMMA storage.
    :AWS_CONSOLE_URL,
    :AWS_BUCKET,
    :AWS_REGION,
    :AWS_ACCESS_KEY_ID,
    :AWS_SECRET_KEY,
    :AWS_DEFAULT_REGION,
    nil,

    # === Amazon Web Services for BiblioVault collections.
    :BV_BUCKET,
    :BV_REGION,
    :BV_ACCESS_KEY_ID,
    :BV_SECRET_KEY,
    :BV_DEFAULT_REGION,
    nil,

    # === Internet Archive
    :IA_DOWNLOAD_API_URL,
    :IA_ACCESS,
    :IA_SECRET,
    nil,

    # === Lookup API keys
    :CROSSREF_API_KEY,  # CrossRef
    :GOOGLE_API_KEY,    # Google Books
    :WORLDCAT_API_KEY,  # OCLC/WorldCat
    nil,

    # === Benetech "Math Detective"
    :MD_API_KEY,
    :MD_BASE_PATH,
    nil,

    # === Ruby
    :RUBY_VERSION,
    :RUBYOPT,
    :RUBYLIB,
    nil,

    # === Rails
    :RAILS_APP_VERSION,
    :RAILS_CACHE_ID,
    :RAILS_LOG_TO_STDOUT,
    :RAILS_MASTER_KEY,
    :RAILS_MAX_THREADS,
    :RAILS_MIN_THREADS,
    :RAILS_SERVE_STATIC_FILES,
    :SECRET_KEY_BASE,
    nil,

    # === GoodJob
    :GOOD_JOB_CRON,
    :GOOD_JOB_CLEANUP_DISCARDED_JOBS,
    :GOOD_JOB_CLEANUP_INTERVAL_JOBS,
    :GOOD_JOB_CLEANUP_INTERVAL_SECONDS,
    :GOOD_JOB_CLEANUP_PRESERVED_JOBS_BEFORE_SECONDS_AGO,
    :GOOD_JOB_ENABLE_CRON,
    :GOOD_JOB_ENABLE_LISTEN_NOTIFY,
    :GOOD_JOB_EXECUTION_MODE,
    :GOOD_JOB_IDLE_TIMEOUT,
    :GOOD_JOB_MAX_CACHE,
    :GOOD_JOB_MAX_THREADS,
    :GOOD_JOB_PIDFILE,
    :GOOD_JOB_POLL_INTERVAL,
    :GOOD_JOB_QUEUES,
    :GOOD_JOB_QUEUE_SELECT_LIMIT,
    :GOOD_JOB_SHUTDOWN_TIMEOUT,
    nil,

    # === Puma
    :PORT,
    :PIDFILE,
    :WEB_CONCURRENCY,
    :PUMA_PORT,
    :PUMA_FIRST_DATA_TIMEOUT,
    :PUMA_PERSISTENT_TIMEOUT,
    :PUMA_WORKER_TIMEOUT,
    nil,

    # === Analytics
    :ANALYTICS_HOST,
    :ANALYTICS_SITE,
    :ANALYTICS_TOKEN,
    nil,

    # === ReCaptcha
    :RECAPTCHA_VERSION,
    :RECAPTCHA_SITE_KEY,
    :RECAPTCHA_SECRET_KEY,
    nil,

    # === Logging
    :LOG_SILENCER,
    :LOG_SILENCER_ENDPOINTS,
    nil,

    # === Testing
    :PARALLEL_WORKERS,
    :TEST_FORMATS,
    nil,

    # === System
    :USER,
    :GROUP,
    :HOME,
    :PWD,
    :SHELL,
    :TZ,
    :LANG,
    :LC_ALL,
    :LANGUAGE,
    :PATH,
    nil,

    # === Execution environment
    :BOOTSNAP_CACHE_DIR,
    :BUNDLE_GEMFILE,
    :CACHE_DIR,
    :DEBUGGER_STORED_RUBYLIB,
    :IN_PASSENGER,
    :RUBYMINE_CONFIG,
    :SCRIPT_NAME,
    nil,

    # === Other
    :DOWNLOAD_EXPIRATION,
    :FILE_UPLOAD_MIN_SIZE,
    :GITHUB_URL,
    :HEX_RAND_DIGITS,
    :MAXIMUM_PASSWORD_LENGTH,
    :MINIMUM_PASSWORD_LENGTH,
    :REDIS_URL,
    :ROW_PAGE_SIZE,
    :S3_PREFIX_LIMIT,
    :SHRINE_STORAGE_DIR,
    :TERRAFORM_URL,

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
    # These are not expected to be in "en.emma.env_var", either because they're
    # not associated with an environment variable or because they're
    # intentionally not included in the set of configuration values.
    constants_only = %i[
      AUTH_PROVIDERS
      BV_DEFAULT_REGION
      CONSOLE_OUTPUT
      PARALLEL_WORKERS
      SCRIPT_NAME
      TRACE_OUTPUT
    ]
    f, v    = [FLAGS, VALUES].map(&:compact)
    f_dup   = f.tally.select { |_, count| count > 1 }.presence
    v_dup   = v.tally.select { |_, count| count > 1 }.presence
    f_v     = (f + v).excluding(*constants_only)
    cfg     = ENV_VAR.from_yaml.keys.map(&:to_sym)
    added   = (f_v - cfg).presence
    missing = (cfg - f_v).presence
    overlap = f.intersection(v).presence
    Log.warn { "#{self} FLAGS duplicates: #{f_dup.keys.inspect}" }  if f_dup
    Log.warn { "#{self} VALUES duplicates: #{v_dup.keys.inspect}" } if v_dup
    Log.warn { "#{self} FLAGS/VALUES added: #{added.inspect}" }     if added
    Log.warn { "#{self} FLAGS/VALUES missing: #{missing.inspect}" } if missing
    raise "#{self} FLAGS/VALUES overlap: #{overlap.inspect}"        if overlap
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # An AppSettings value instance.
  #
  class Value

    # Sources for AppSettings values.
    #
    # @type [Array<Symbol>]
    #
    # @see "en.emma.term.sys.from_*"
    #
    ORIGIN = %i[env cred yaml const other].freeze

    # Either :flag or :setting.
    #
    # @return [Symbol]
    #
    attr_reader :type

    # The source of the value.
    #
    # @return [Symbol, nil]           An element of Value#ORIGIN.
    #
    attr_reader :origin

    # The value itself.
    #
    # @return [any, nil]
    #
    attr_reader :content

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
    # @option opt [any, nil]       :env
    # @option opt [any, nil]       :cred
    # @option opt [any, nil]       :yaml
    # @option opt [any, nil]       :const
    # @option opt [any, nil]       :other
    # @option opt [Boolean]        :null
    # @option opt [Boolean]        :spacer
    #
    def initialize(type_key = nil, **opt)
      @type    = (opt.delete(:type) || type_key).to_sym
      keys     = opt.compact_blank.keys
      fail "cannot specify #{keys} together" if keys.many?
      @null    = true?(opt[:null])
      @spacer  = true?(opt[:spacer])
      @origin  = opt.keys.intersection(ORIGIN).first
      @content = opt[@origin]
    end

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

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Create a new instance with values acquired for the named keys.
    #
    # @param [Array] keys
    #
    def initialize(keys)
      if keys.is_a?(Hash)
        super
      else
        keys.each { acquire_value(_1) }
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Set the value at index *k* from either the associated `ENV` variable or
    # an associated constant.
    #
    # @param [Symbol, String, nil] k
    #
    # @return [Value]
    #
    def acquire_value(k)
      if (k = k&.to_s).nil?
        k = spacer_key
        v = { spacer: true }
      elsif !ENV_VAR.from_env[k].nil?
        v = { env:    storage_value(ENV_VAR[k]) }
      elsif !ENV_VAR.from_credentials[k].nil?
        v = { cred:   storage_value(ENV_VAR[k]) }
      elsif ENV_VAR.key?(k)
        v = { yaml:   storage_value(ENV_VAR[k]) }
      elsif (mod = module_defining(k))
        v = { const:  storage_value(mod.const_get(k)) }
      elsif k.start_with?('GOOD_JOB_')
        v = { other:  storage_value(good_job_value(k)) }
      else
        v = { null:   true }
      end
      self[k.to_sym] = Value.new(type_key, **v)
    end

    # Return the module that defines a constant with the given name.
    #
    # @param [Symbol, String, nil] const
    #
    # @return [Module, nil]
    #
    def module_defining(const)
      return if (const = const&.to_sym).blank?
      [constant_map[const], Object].compact.find { _1.const_defined?(const) }
    end

    # Return the GoodJob configuration value associated with the given
    # environment name.
    #
    # @param [Symbol, String, nil] var
    #
    # @return [any, nil]
    #
    def good_job_value(var)
      key = GOOD_JOB_ENV_KEY_MAP[var&.to_s].presence or return
      # noinspection RubyResolve
      if Rails.application.config.good_job.key?(key)
        Rails.application.config.good_job[key] || :null
      elsif GoodJob.configuration.respond_to?("#{key}?")
        GoodJob.configuration.send("#{key}?")
      elsif GoodJob.configuration.respond_to?(key)
        GoodJob.configuration.send(key) || :null
      elsif key == :queues
        GoodJob.configuration.queue_string
      end
    end

    # =========================================================================
    # :section: Class methods
    # =========================================================================

    protected

    def self.type_key = must_be_overridden

    def self.spacer_key = must_be_overridden

    def self.storage_value(v) = must_be_overridden

    def self.constant_map
      # noinspection RbsMissingTypeSignature
      @constant_map ||= {
        BATCH_SIZE:                   Record::Properties,
        BULK_DB_BATCH_SIZE:           UploadWorkflow::Bulk::External,
        DEBUG_DECORATOR_COLLECTION:   BaseCollectionDecorator,
        DEBUG_DECORATOR_EXECUTE:      BaseDecorator::List,
        DEBUG_DECORATOR_INHERITANCE:  BaseDecorator,
        DEBUG_HASH:                   Emma::Common::HashMethods,
        DISABLE_UPLOAD_INDEX_UPDATE:  Record::Submittable::IndexIngestMethods,
        DOWNLOAD_EXPIRATION:          Record::Uploadable,
        HEX_RAND_DIGITS:              CssHelper,
        MAXIMUM_PASSWORD_LENGTH:      AccountDecorator::SharedGenericMethods,
        MINIMUM_PASSWORD_LENGTH:      AccountDecorator::SharedGenericMethods,
        ROW_PAGE_SIZE:                BaseDecorator::Row,
        S3_PREFIX_LIMIT:              AwsHelper,
        SEARCH_EXTENDED_TITLE:        SearchDecorator::SharedGenericMethods,
        SEARCH_GENERATE_SCORES:       SearchConcern,
        SEARCH_RELEVANCY_SCORE:       SearchDecorator::SharedGenericMethods,
        SEARCH_SAVE_SEARCHES:         SearchConcern,
        SESSION_DEBUG_CSS_CLASS:      SessionDebugHelper,
        SESSION_DEBUG_DATA_ATTR:      SessionDebugHelper,
        STRICT_FORMATS:               FileNaming,
        UPLOAD_DEFER_INDEXING:        UploadWorkflow::Bulk::Create::Actions,
        UPLOAD_DEV_TITLE_PREFIX:      Record::Properties,
        UPLOAD_EMERGENCY_DELETE:      Record::Properties,
        UPLOAD_FORCE_DELETE:          Record::Properties,
        UPLOAD_REPO_CREATE:           Record::Properties,
        UPLOAD_REPO_EDIT:             Record::Properties,
        UPLOAD_REPO_REMOVE:           Record::Properties,
        UPLOAD_TRUNCATE_DELETE:       Record::Properties,
      }
    end

    delegate :type_key, :spacer_key, :storage_value, :constant_map, to: :class

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
    # @return [Hash]
    #
    def get_item(**opt)
      filter_all(super, **opt)
    end

    # Set global application settings values.
    #
    # @param [Hash]    values
    # @param [Boolean] replace        If *true* erase current settings first.
    #
    # @return [Hash]                  The new settings.
    # @return [nil]                   If the `write` failed.
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
    # @return [Hash]                  The new settings.
    # @return [nil]                   If the `write` failed.
    #
    def reset_item(values = nil)
      values = prepare_all(values) || default
      super
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
      values = values.transform_values { prepare(_1) }
      opt[:only] = FLAGS + VALUES if opt.slice(:only, :type).blank?
      # noinspection RubyMismatchedArgumentType
      filter_all(values, **opt)
    end

    # Recursively prepare a single item.
    #
    # @param [any, nil] item
    #
    # @return [any, nil]
    #
    def prepare(item)
      case item
        when nil, :nil then :null
        when Hash      then item.map { [_1.to_sym, prepare(_2)] }.to_h.compact
        when Array     then item.map { prepare(_1) }.compact
        when String    then true?(item) || (false?(item) ? false : item)
        else                item
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
    # @note Currently unused.
    #
    #--
    # noinspection RubyMismatchedArgumentType
    #++
    # :nocov:
    def inspect_all(values = nil, **opt)
      values = values ? filter_all(values, **opt) : get_item(**opt)
      values = encode_symbols(values)
      values = pretty_json(values)
      decode_symbols(values)
    end
    # :nocov:

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Preserve symbols for resolution with #decode_symbols.
    #
    # @param [any, nil] item
    #
    # @return [any, nil]
    #
    # @note Currently used only by #inspect_all.
    # :nocov:
    def encode_symbols(item)
      # noinspection RubyMismatchedArgumentType
      case item
        when Hash   then item.transform_values { encode_symbols(_1) }
        when Array  then item.map { encode_symbols(_1) }
        when Symbol then encode_symbol(item)
        else             item
      end
    end
    # :nocov:

    # encode_symbol
    #
    # @param [Symbol] symbol
    #
    # @return [String]
    #
    # @note Currently used only by #encode_symbols.
    # :nocov:
    def encode_symbol(symbol)
      ":#{symbol}:"
    end
    # :nocov:

    # decode_symbols
    #
    # @param [String] string
    #
    # @return [String]
    #
    # @note Currently used only by #inspect_all.
    # :nocov:
    def decode_symbols(string)
      string.gsub(/":([^\n]+):"/, ':\1')
    end
    # :nocov:

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
    # @return [any, nil]
    #
    def [](name)
      get_item[name.to_sym] if name
    end

    # Assign an individual setting.
    #
    # @param [Symbol, String] name
    # @param [any, nil]       value
    #
    # @return [any, nil]
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
    # @yieldparam [Symbol]   name
    # @yieldparam [any, nil] value
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
