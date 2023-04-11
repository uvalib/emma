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
    nil,

    :TRACE_LOADING,
    :TRACE_CONCERNS,
    :TRACE_NOTIFICATIONS,
    :TRACE_RAKE,
    nil,

    :DEBUG_AWS,
    :DEBUG_CABLE,
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

    # == Bulk Upload
    :BATCH_SIZE,
    :BULK_DB_BATCH_SIZE,
    :DISABLE_UPLOAD_INDEX_UPDATE,
    nil,

    # == Database
    :DATABASE,
    :DBHOST,
    :DBPORT,
    :DBUSER,
    :DBPASSWD,
    nil,

    # == Postgres
    :PGPORT,
    :PGHOST,
    :PGUSER,
    :PGPASSWORD,
    nil,

    # == Amazon Web Services
    :AWS_BUCKET,
    :AWS_REGION,
    :AWS_DEFAULT_REGION,
    :AWS_ACCESS_KEY_ID,
    :AWS_SECRET_KEY,
    nil,

    # == EMMA Unified Search API
    :SEARCH_API_VERSION,
    :SEARCH_BASE_URL,
    nil,

    # == EMMA Unified Ingest API
    :INGEST_API_VERSION,
    :INGEST_API_KEY,
    nil,

    # == Bookshare API
    :BOOKSHARE_API_URL,
    :BOOKSHARE_API_VERSION,
    :BOOKSHARE_API_KEY,
    nil,

    # == Bookshare OAuth2 service
    :BOOKSHARE_AUTH_URL,
    :BOOKSHARE_TEST_AUTH,
    nil,

    # == Internet Archive
    :IA_DOWNLOAD_BASE_URL,
    :IA_ACCESS,
    :IA_SECRET,
    :IA_USER_COOKIE,
    :IA_SIG_COOKIE,
    nil,

    # == Benetech "Math Detective"
    :MD_API_KEY,
    :MD_BASE_PATH,
    nil,

    # == OCLC/WorldCat
    :WORLDCAT_API_KEY,
    :WORLDCAT_REGISTRY,
    :WORLDCAT_PRINCIPAL,
    nil,

    # == Google, Google Books, Google Search
    :GOOGLE_USER,
    :GOOGLE_PASSWORD,
    :GOOGLE_API_KEY,
    #:GB_USER,
    #:GB_PASSWORD,
    #:GB_API_KEY,
    #:GS_USER,
    #:GS_PASSWORD,
    #:GS_API_KEY,
    nil,

    # == Shrine uploader
    :SHRINE_CLOUD_STORAGE,
    :STORAGE_DIR,
    nil,

    # == Rails
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

    # == GoodJob
    :GOOD_JOB_CLEANUP_INTERVAL_JOBS,
    :GOOD_JOB_CLEANUP_INTERVAL_SECONDS,
    :GOOD_JOB_CLEANUP_PRESERVED_JOBS_BEFORE_SECONDS_AGO,
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
    nil,

    # == Puma
    :PORT,
    :PIDFILE,
    :WEB_CONCURRENCY,
    nil,

    # == Testing
    :PARALLEL_WORKERS,
    :TEST_BOOKSHARE,
    :TEST_FORMATS,
    :EMMADSO_TOKEN,
    :EMMACOLLECTION_TOKEN,
    :EMMAMEMBERSHIP_TOKEN,
    nil,

    # == System
    :USER,
    :GROUP,
    :HOME,
    :TZ,
    :LANG,
    :LC_ALL,
    :LANGUAGE,
    nil,

    # == Other
    :BUNDLE_GEMFILE,
    :IN_PASSENGER,
    :DEBUGGER_STORED_RUBYLIB,
    :REDIS_URL,
    :SCHEDULER,
    :RUBYMINE_CONFIG,

  ].freeze

  # Configuration field types.
  #
  # @type [Hash{Symbol=>Array<Symbol,nil>}]
  #
  TYPE_KEYS = {
    flag:    FLAGS,
    setting: VALUES,
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
    # @param [Array<Symbol>, Symbol, nil] only
    # @param [Boolean]                    spacers
    #
    # @return [Hash]
    #
    def filter_all(values, type: nil, only: nil, spacers: false, **)
      spacer = %i[spacer]
      only &&= Array.wrap(only).flatten.compact.presence
      if type
        spacer = [type, *spacer]
        only ||= TYPE_KEYS[type]
      end
      is_spacer = ->(v) {
        v.is_a?(Array) && (v.intersection(spacer) == spacer)
      }
      if only && spacers
        values.select { |k, v| is_spacer.call(v) || only.include?(k) }
      elsif only
        values.slice(*only)
      elsif spacers
        values
      else
        values.reject { |_, v| is_spacer.call(v) }
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
      values &&= prepare(values).presence or return
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
      values = { name => value}
      set_item(values)&.dig(name.to_sym)
    end

    # Iterate over each configuration flag.
    #
    # @param [Boolean] spacers
    #
    # @yield [name, value] Operate on a configuration flag.
    # @yieldparam [Symbol]  name
    # @yieldparam [Boolean] value
    #
    def each_flag(spacers: false, &block)
      each_pair(spacers: spacers, type: :flag, &block)
    end

    # Iterate over each configuration setting.
    #
    # @param [Boolean] spacers
    #
    # @yield [name, value] Operate on a configuration setting.
    # @yieldparam [Symbol] name
    # @yieldparam [*]      value
    #
    def each_setting(spacers: false, &block)
      each_pair(spacers: spacers, type: :setting, &block)
    end

    # Iterate over each configuration value.
    #
    # @param [Hash] opt               Passed to #get_item.
    #
    # @yield [name, value] Operate on a configuration value.
    # @yieldparam [Symbol] name
    # @yieldparam [*]      value
    #
    def each_pair(**opt, &block)
      get_item(**opt).each_pair(&block)
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
    env    = ENV.to_h.symbolize_keys
    hash   = ->(type, &block) {
      TYPE_KEYS[type].map.each_with_index { |k, i|
        k ? [k, block.call(env[k])] : [:"#{type}_#{i}", [type, :spacer]]
      }.to_h
    }
    flags  = hash.call(:flag)    { |v| true?(v) }
    values = hash.call(:setting) { |v| v.nil? ? 'nil' : v }
    set_item(flags.merge!(values), replace: true, spacers: true)
  rescue => error
    Log.error("#{self} initialization failed")
    raise error
  end

end

__loading_end(__FILE__)
