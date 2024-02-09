# app/models/exec_report.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An object encapsulating error reporting information.
#
# @!attribute [r] part
#   Error report parts [x].
#   @return [Array<ExecReport::Part>]
#
# @!attribute [rw] render_html
#   When *true*, render methods return ActiveSupport::SafeBuffer [x].
#   @return [Boolean]
#
# === Usage Notes
# Rather than attempting to (partially) process error information at the site
# of its reception, the raw information is wrapped in an ExecReport so that it
# may be processed as needed.
#
class ExecReport

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Error report parts.
  #
  # @return [Array<ExecReport::Part>]
  #
  attr_reader :parts

  # When *true*, render methods return ActiveSupport::SafeBuffer.
  #
  # @return [Boolean]
  #
  attr_accessor :render_html

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Array] src
  #
  #--
  # === Variations
  #++
  #
  # @overload initialize(base, *src)
  #   @param [ApplicationRecord] base
  #   @param [Array<ExecReport,Exception,Hash,Array<String>,String,nil>] src
  #
  # @overload initialize(*src)
  #   @param [Array<ExecReport,Hash,Array<String>,String,nil>] src
  #
  def initialize(*src)
    set(*src)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Clear the instance.
  #
  # @return [self]
  #
  def clear(...)
    @parts = []
    @render_html = false
    self
  end

  # Replace the original data of the instance.
  #
  # @param [Array<ExecReport, Exception, Hash, Array<String>, String, nil>] src
  #
  # @return [self]
  #
  def set(*src)
    clear
    add(*src)
  end

  # Accumulate data from the given source(s).
  #
  # @param [Array<ExecReport, Exception, Hash, Array<String>, String, nil>] src
  #
  # @return [self]
  #
  def add(*src)
    added =
      src.flatten.compact_blank!.flat_map do |v|
        v.is_a?(ExecReport) ? v.parts : ExecReport::Part[v]
      end
    @render_html ||= added.any?(&:html_safe?)
    @parts.concat(added)
    self
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Find the first exception associated with a error report part.
  #
  # @return [Exception, nil]
  #
  def exception
    # noinspection RubyMismatchedReturnType
    parts.find { |p| ex = p.exception and return ex }
  end

  # Produce error report lines.
  #
  # @param [Boolean, nil] html        Set/unset HTML-safe output.
  #
  # @return [Array<String>]
  #
  def render(html: nil, **)
    html = true if html.nil?
    error_messages(nil, html: html)
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Indicate whether the report is currently set to produce HTML-safe values.
  #
  def html_safe?
    render_html.present?
  end

  # Indicate whether the error report has any valid data.
  #
  # This is not the same as `self.part.empty?`.
  #
  def blank?
    parts.compact_blank.empty?
  end

  # Duplication is deep by default.
  #
  # @return [ExecReport]
  #
  def dup
    self.class.new(*parts.map(&:dup))
  end

  # Freeze all contents.
  #
  def deep_freeze
    parts.deep_freeze
    freeze
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Values relating to analyzing/constructing error reports.
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  module Constants

    TOPIC_KEY   = :topic
    TOPIC_SEP   = ': '

    DETAILS_KEY = :errors
    DETAILS_SEP = '; '

    STATUS_KEYS = %i[http_status status].freeze
    STATUS_KEY  = STATUS_KEYS.first

    HTML_KEYS   = %i[render_html html].freeze
    HTML_KEY    = HTML_KEYS.first

    EXCEPTION_KEY = :exception

    # Error key prefix which indicates a general (non-item-specific) error
    # message entry.
    #
    # @type [String]
    #
    GENERAL_ERROR_TAG = 'ERROR'

    GENERAL_ERROR_KEY = "#{GENERAL_ERROR_TAG}[%d]"

  end

  include Constants

  # Methods for converting to/from hashes.
  #
  module DataMethods

    include Emma::Common
    include Emma::Json

    include ExecReport::Constants

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Prepare an error report value for assignment to a database column.
    #
    # @param [any, nil] src   ExecReport,ExecReport::Part,Exception,Hash,String
    #
    # @return [String, nil]   *nil* if *src* was blank.
    #
    def serialize(src)
      data = deserialize(src)
      data = serialize_filter(data)
      data.to_json if data.present?
    end

    # Interpret an error report value from a database column.
    #
    # @param [any, nil] src   ExecReport,ExecReport::Part,Exception,Hash,String
    #
    # @return [Array<Hash{Symbol=>String,Array<String>}>, nil]
    #
    def deserialize(src)
      # noinspection RubyMismatchedArgumentType
      message_hashes(src).presence
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Remove or transform data that should not be persisted as is.
    #
    # @param [Array<Hash>, Hash, nil] part
    #
    # @return [Array<Hash>, Hash, nil]
    #
    #--
    # noinspection RubyMismatchedReturnType
    #++
    def serialize_filter(part)
      case part
        when Array
          part.map { |v| serialize_filter(v) }.compact_blank!
        when Hash
          part.map { |k, v|
            v = v.class.name if v.is_a?(Exception)
            [k, v] unless v.blank? || HTML_KEYS.include?(k)
          }.compact.to_h
        else
          Log.debug { "#{__method__}: skipping #{inspect_item(part)}" }
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get topic/details from *src*.
    #
    # @param [any, nil] src   ExecReport,ExecReport::Part,Exception,Hash,String
    #
    # @return [Array<Hash{Symbol=>String,Array<String>}>]
    #
    def message_hashes(src)
      extract_message_hashes(src, __method__).map! { |part|
        normalized_hash(part)
      }.compact_blank!
    end

    # Get topic/details from *src*.
    #
    # @param [any, nil] src   ExecReport,ExecReport::Part,Exception,Hash,String
    #
    # @return [Hash{Symbol=>String,Array<String>}]
    #
    def message_hash(src)
      result = extract_message_hash(src, __method__)
      normalized_hash(result)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # normalized_hash
    #
    # @param [Hash] hash
    #
    # @return [Hash{Symbol=>String,Array<String>}]
    #
    def normalized_hash(hash)
      hash.map { |k, v|
        v = Array.wrap(v)
        v = v.first unless k == DETAILS_KEY
        v = normalized_value(v)
        [k, v] if v || v.is_a?(FalseClass)
      }.compact.to_h
    end

    # normalized_value
    #
    # @param [any, nil] value
    #
    # @return [any, nil]
    #
    def normalized_value(value)
      case value
        when Array
          value.map { |s| normalized_value(s) }.compact.presence
        when ActiveSupport::SafeBuffer
          to_utf8(value).presence
        when String
          to_utf8(value) if (value = value.strip).present?
        when FalseClass
          value
        else
          value.presence
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Attempt to get an HTTP status value from *src*.
    #
    # @param [any, nil] src           ExecReport, Exception, Faraday::Response
    #
    # @return [Integer, Symbol, nil]
    #
    def extract_status(src)
      return if src.nil?
      src = src.exception if src.is_a?(ExecReport)
      # noinspection RailsParamDefResolve
      src.try(:http_status) || src.try(:status) || src.try(:code) ||
        src.try(:dig, :status) || src.try(:response).try(:dig, :status)
    end

    # Attempt to get topic/details from *src*.
    #
    # @param [any, nil] src   ExecReport,ExecReport::Part,Exception,Hash,String
    # @param [Symbol, nil] meth
    #
    # @return [Array<Hash{Symbol=>Array}>]
    #
    def extract_message_hashes(src, meth = nil)
      meth ||= __method__
      case src
        when ExecReport then src = src.parts
        when String     then src = safe_json_parse(src, log: false)
      end
      if src.is_a?(Array)
        src.flatten.flat_map { |v| extract_message_hashes(v, meth) }
      else
        [extract_message_hash(src, meth)]
      end
    end

    # Attempt to get topic/details from *src*.
    #
    # @param [any, nil] src   ExecReport,ExecReport::Part,Exception,Hash,String
    # @param [Symbol, nil] meth
    #
    # @return [Hash{Symbol=>Array<String>}]
    #
    def extract_message_hash(src, meth = nil)
      return {} if src.blank?
      meth ||= __method__
      src    = safe_json_parse(src, log: false) if src.is_a?(String)
      parts  =
        case src
          when Array               then src
          when ExecReport          then src.parts
          when Api::Record         then src.exception || {}
          when ActiveModel::Errors then src.full_messages
          when ApplicationRecord   then src.errors.full_messages
        end
      # noinspection RubyMismatchedArgumentType
      if parts.nil?
        make_message_hash(src, meth)
      elsif !parts.is_a?(Array)
        send(__method__, parts, meth)
      elsif !parts.all? { |part| part.is_a?(String) }
        parts.map { |part| send(__method__, part, meth) }.reduce(&:rmerge!)
      else
        topic   = make_message_hash(parts.shift)
        details = (make_message_hash(DETAILS_KEY => parts) if parts.present?)
        details ? topic.rmerge!(details) : topic
      end
    end

    # Create message hash values from *src*.
    #
    # @param [any, nil]    src        ExecReport::Part, Exception, Hash, String
    # @param [Symbol, nil] meth
    #
    # @return [Hash{Symbol=>Array}]
    #
    def make_message_hash(src, meth = nil)
      return {} if src.blank?
      case src
        when ExecReport::Part
          result = { TOPIC_KEY => src.topic, DETAILS_KEY => src.details }
          # noinspection RubyMismatchedArgumentType
          result = result.merge!(src.info).deep_dup
          result[HTML_KEY] = src.html_safe? unless result.key?(HTML_KEY)

        when Exception
          # noinspection RubyMismatchedArgumentType
          src    = ExecError.new(src) unless src.is_a?(ExecError)
          result = { TOPIC_KEY => src.message&.dup }
          result[DETAILS_KEY]   = src.messages[1..]&.deep_dup
          result[STATUS_KEY]    = src.try(:http_status)
          result[HTML_KEY]      = src.messages.any?(&:html_safe?)
          result[EXCEPTION_KEY] = src

        when Hash
          result = src.deep_dup.deep_symbolize_keys!
          result[STATUS_KEY] = result.extract!(*STATUS_KEYS).values.first
          result[HTML_KEY]   = result.extract!(*HTML_KEYS).values.first

        when Numeric
          result = { TOPIC_KEY => src.to_s, HTML_KEY => false }

        when ActiveSupport::SafeBuffer
          result = { TOPIC_KEY => src, HTML_KEY => true }

        when String
          src    = src.strip.presence
          result = src ? { TOPIC_KEY => src, HTML_KEY => false } : {}

        else
          meth ||= __method__
          error  = "#{meth}: unexpected #{src.class}: #{src.inspect}"
          Log.info { error }
          result = { TOPIC_KEY => "-[ #{error} ]-" }
      end
      result.compact_blank!.transform_values! { |v| Array.wrap(v) }
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # message_line
    #
    # @param [Array<String, nil>] args
    # @param [String]             separator
    # @param [Hash]               opt
    #
    # @return [String, ActiveSupport::SafeBuffer]
    #
    # @see #message_topic
    # @see #message_details
    #
    def message_line(*args, separator: TOPIC_SEP, **opt)
      k = message_topic(args.shift, **opt)
      v = message_details(args, **opt)
      line = [k, v].compact.join(separator)
      opt[:html] ? line.html_safe : line
    end

    # message_topic
    #
    # @param [Array<String>, String, nil] src
    # @param [Hash]                       opt
    #
    # @option opt [String, nil] :separator  Default: `opt[:t_sep]`.
    # @option opt [String, nil] :t_sep      Default: #TOPIC_SEP.
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    # @see #message_portion
    #
    def message_topic(src, **opt)
      opt[:separator] ||= opt[:t_sep] || TOPIC_SEP
      message_portion(src, **opt)
    end

    # message_details
    #
    # @param [Array<String>, String, nil] src
    # @param [Hash]                       opt
    #
    # @option opt [String, nil] :separator  Default: `opt[:d_sep]`.
    # @option opt [String, nil] :d_sep      Default: #DETAILS_SEP.
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    # @see #message_portion
    #
    def message_details(src, **opt)
      opt[:separator] ||= opt[:d_sep] || DETAILS_SEP
      message_portion(src, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # message_portion
    #
    # @param [Array<String>, String, nil] src
    # @param [Hash]                       opt
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    # @see #message_part
    #
    def message_portion(src, **opt)
      src = src && Array.wrap(src).compact_blank.uniq.presence or return
      sep = opt[:separator]
      opt[:separators] = [sep, sep.strip]
      src.map! { |v| message_part(v, **opt) }
      html = opt[:html] || src.any?(&:html_safe?)
      html ? html_join(src, sep) : src.join(sep)
    end

    # message_part
    #
    # @param [String, nil] src
    # @param [Hash]        opt
    #
    # @option opt [String]        :separator
    # @option opt [Array<String>] :separators
    # @option opt [Boolean, nil]  :html
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    def message_part(src, **opt)
      return if src.blank?
      val  = to_utf8(src) || src.to_s
      seps = Array.wrap(opt[:separators] || opt[:separator])
      seps = seps.flat_map { |s| [s, s.strip] } unless seps.many?
      if (sep = seps.find { |s| val.end_with?(s) })
        safe = val.html_safe?
        val  = val.delete_suffix(sep)
        return val.html_safe if safe
      end
      opt[:html] ? ERB::Util.h(val) : val
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include DataMethods

  # Logic which is not dependent on an ExecReport instance.
  #
  module BaseMethods

    include Emma::Common
    include Emma::Json

    include ExecReport::Constants
    include ExecReport::DataMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get the HTTP status value from *src*.
    #
    # @param [any, nil] src           ExecReport, Exception, Faraday::Response
    #
    # @return [Integer, Symbol, nil]
    #
    def http_status(src)
      extract_status(src)
    end

    # error_table
    #
    # @param [Array<ExecReport,Exception,Hash,Array,*>] entries
    # @param [Boolean, nil]                             html
    # @param [Hash]                                     opt
    #
    # @return [Hash{String,Integer=>String}]
    #
    # @see #error_table_hash
    #
    def error_table(*entries, html: nil, **opt)
      html = entries.any? { |v| v.try(:html_safe?) } if html.nil?
      error_table_hash(entries, **opt).transform_values! { |v|
        message_line(nil, *v, html: html)
      }.compact_blank!
    end

    # Return workflow error messages as multiple string(s).
    #
    # @param [any, nil]     src       ExecReport, Model, Exception, Hash, Array
    # @param [Boolean, nil] html
    # @param [Hash]         opt
    #
    # @return [Array<String>]
    #
    # @see #error_table_hash
    #
    def error_messages(src, html: nil, **opt)
      src  = src.exec_report      if src.respond_to?(:exec_report)
      html = src.try(:html_safe?) if html.nil?
      error_table_hash(src, **opt).map { |k, v|
        next if v.blank?
        k = k.to_s
        k = nil if k.start_with?(GENERAL_ERROR_TAG)
        message_line(k, *v, html: html)
      }.compact_blank!
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # error_table_hash
    #
    # @param [Array<ExecReport,Exception,Hash,Array,*>] src
    # @param [String, Regexp, Array, nil]               ignore
    #
    # @return [Hash{String,Integer=>String}]
    #
    def error_table_hash(src, ignore: nil, **)
      result = {}
      t_idx  = 0
      ignore = Array.wrap(ignore).presence
      Array.wrap(src).flatten.each do |entry|
        message_hashes(entry).each do |part|
          topic, details = part.values_at(TOPIC_KEY, DETAILS_KEY)
          t_key = GENERAL_ERROR_KEY % (t_idx += 1)
          d_idx = 0
          items =
            Array.wrap(details).flatten.map { |item|
              msg = item.to_s
              next if ignore&.any? { |pattern| msg.match?(pattern) }
              key, txt = msg.split(/\s*-+\s*/, 2)
              txt = item unless (key = positive(key))
              next if txt.blank?
              key ||= "#{t_key}[%d]" % (d_idx += 1)
              [key, txt]
            }.compact.to_h
          if topic.present? && (details.blank? || items.present?)
            result[t_key] = topic
          elsif items.blank?
            t_idx -= 1
          end
          items.each_pair do |key, txt|
            result[key] ||= []
            result[key] << txt
          end
        end
      end
      result
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    def inspect_item(value)
      case value
        when Symbol, NilClass
          value.inspect
        when Hash
          value = value.map { |k, v| "#{k.inspect} => #{inspect_item(v)}" }
          'Hash(%d)-{%s}' % [value.size, value.join(', ')]
        when Array
          value = value.map { |v| inspect_item(v) }
          'Array(%d)-[%s]' % [value.size, value.join(', ')]
        when Exception
          "#<#{value.class.name}:#{value.object_id}>"
        else
          size = ('(%d)' % value.size if value.respond_to?(:size))
          "%s#{size}-%s" % [value.class, value.inspect]
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include BaseMethods

  # ===========================================================================
  # :section: ExecReport::DataMethods overrides
  # ===========================================================================

  public

  # Prepare the error report value for assignment to a database column.
  #
  # @param [any, nil] src             Default: `self`
  #
  # @return [String, nil]             *nil* if *src* was blank.
  #
  def serialize(src = nil)
    src and super or @serialize ||= super(self)&.freeze
  end

  # Interpret the error report value from a database column.
  #
  # @param [any, nil] src             Default: `self`
  #
  # @return [Array<Hash{Symbol=>String,Array<String>}>, nil]
  #
  def deserialize(src = nil)
    src and super or @deserialize ||= super(self)&.deep_freeze
  end

  # ===========================================================================
  # :section: ExecReport::BaseMethods overrides
  # ===========================================================================

  public

  # The error table for the current instance.
  #
  # @param [Array<ExecReport,Exception,Hash,Array,*>] entries   Def.: `self`.
  # @param [Boolean, nil]                             html
  # @param [Hash]                                     opt       To super
  #
  # @return [Hash{String,Integer=>String}]
  #
  def error_table(*entries, html: nil, **opt)
    if entries.present?
      super
    elsif opt.present? || (html.presence != render_html.presence)
      super(self, html: html, **opt)
    else
      @error_table ||= super(self).deep_freeze
    end
  end

  # Return error messages from the instance as multiple string(s).
  #
  # @param [any, nil]     src         Default: `self`
  # @param [Boolean, nil] html
  # @param [Hash]         opt         To super
  #
  # @return [Array<String>]
  #
  def error_messages(src = nil, html: nil, **opt)
    if src
      super
    elsif opt.present? || (html.presence != render_html.presence)
      super(self, html: html, **opt)
    else
      @error_messages ||= super(self).deep_freeze
    end
  end

  # Return the HTTP status value from the instance.
  #
  # @param [any, nil] src             ExecReport, Exception, Faraday::Response
  #
  # @return [Integer, Symbol, nil]
  #
  def http_status(src = nil)
    src and super or @http_status ||= super(self)
  end

  # Get topic/details from *src*.
  #
  # @param [any, nil] src             Default: `self`.
  #
  # @return [Array<Hash{Symbol=>String,Array<String>}>]
  #
  def message_hashes(src = nil)
    src and super or @message_hashes ||= super(self).deep_freeze
  end

  # Get topic/details from *src*.
  #
  # @param [any, nil] src             Default: `self`.
  #
  # @return [Hash{Symbol=>String,Array<String>}]
  #
  def message_hash(src = nil)
    src ||= self.exception
    super
  end

  # ===========================================================================
  # :section: ExecReport::BaseMethods overrides
  # ===========================================================================

  protected

  # Attempt to get an HTTP status value from *src*.
  #
  # @param [any, nil] src             Default: `self`.
  #
  # @return [Integer, Symbol, nil]
  #
  def extract_status(src = nil)
    src ||= self
    super
  end

  # Attempt to get topic/details from *src*.
  #
  # @param [any, nil]    src          Default: `self`.
  # @param [Symbol, nil] meth
  #
  # @return [Array<Hash{Symbol=>Array<String>}>]
  #
  def extract_message_hashes(src = nil, meth = nil)
    src, meth = [nil, src] if meth.nil? && src.is_a?(Symbol)
    src ||= self.parts
    super
  end

  # Attempt to get topic/details from *src*.
  #
  # @param [any, nil]    src          Default: `self`.
  # @param [Symbol, nil] meth
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def extract_message_hash(src = nil, meth = nil)
    src, meth = [nil, src] if meth.nil? && src.is_a?(Symbol)
    src ||= self.exception
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate an ExecReport if necessary.
  #
  # @param [any, nil] src             ExecReport or arg to initializer.
  #
  # @return [ExecReport]
  #
  def self.[](src)
    # noinspection RubyMismatchedReturnType
    src.is_a?(self) ? src : new(src)
  end

end

# A single ExecReport entry.
#
class ExecReport::Part

  include Emma::Json

  include ExecReport::Constants

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Main report text.
  #
  # @return [String, nil]
  #
  attr_reader :topic

  # List of specific errors/problems.
  #
  # @return [Array<String>]
  #
  attr_reader :details

  # Additional tagged information.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  attr_reader :info

  # When *true*, render methods return ActiveSupport::SafeBuffer.
  #
  # @return [Boolean]
  #
  attr_accessor :render_html

  # The originating exception (if applicable).
  #
  # @return [Exception, nil]
  #
  attr_reader :exception

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [any, nil] src             ExecReport::Part, Hash, Array, String
  #
  # === Implementation Notes
  # Member variables are initialized in the order which optimizes display when
  # the instance is inspected.
  #
  def initialize(src)
    hash         = src.presence ? message_hash(src) : {}
    ex           = hash.delete(EXCEPTION_KEY)
    @topic       = hash.delete(TOPIC_KEY)
    @details     = hash.delete(DETAILS_KEY) || []
    html, @info  = partition_hash(hash, *HTML_KEYS)
    @render_html = true?(html.values.first)
    @exception   = [src, ex].find { |v| v.is_a?(Exception) }
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Indicate whether the part is currently set to produce HTML-safe values.
  #
  def html_safe?
    (render_html || topic&.html_safe? || details.any?(&:html_safe?)).present?
  end

  # Indicate whether the error report part has any valid data.
  #
  # The "out-of-band" contents of :info are not evaluated.
  #
  def blank?
    topic.blank? && details.blank?
  end

  # Duplication is deep by default.
  #
  # @note Because :exception is not strictly a part of the data, it is copied
  #   by reference.
  #
  # @return [ExecReport::Part]
  #
  def dup
    self.class.new(self)
  end

  # Freeze all contents.
  #
  def deep_freeze
    topic.freeze
    details.deep_freeze
    info.deep_freeze
    freeze
  end

  # Inspect the contents of the instance without repeating the contents of
  # @info[:exception] (if present).
  #
  # @return [String]
  #
  def inspect
    vars =
      instance_variables.map do |var|
        "#{var}=%s" % inspect_item(instance_variable_get(var))
      end
    "#<#{self.class.name}:#{object_id} %s>" % vars.join(' ')
  end

  # Generate a string representation of the report part.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :html       If *true*, return an HTML-safe string.
  #
  # @return [ActiveSupport::SafeBuffer]   If opt[:html] is *true*.
  # @return [String]
  #
  def to_s(**opt)
    portions   = [topic, *details]
    opt[:html] = portions.compact.any?(:html_safe?) if opt[:html].nil?
    message_line(*portions, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate an HTML-safe string representation of the parts of the entry.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_safe
    # noinspection RubyMismatchedReturnType
    to_s(html: true)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Methods for converting to/from hashes.
  #
  module DataMethods

    include ExecReport::DataMethods

    # =========================================================================
    # :section: ExecReport::DataMethods overrides
    # =========================================================================

    public

    # Interpret an error report value from a database column.
    #
    # @param [any, nil] src   ExecReport::Part, Exception, Hash, Array, String
    #
    # @return [Array<Hash{Symbol=>String,Array<String>}>, nil]
    #
    def deserialize(src)
      message_hash(src).presence
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # extract_topic
    #
    # @param [any, nil] src
    #
    # @return [String, nil]
    #
    def extract_topic(src)
      src.try(:topic) || src.try(:dig, TOPIC_KEY)
    end

    # extract_details
    #
    # @param [any, nil] src
    #
    # @return [Array<String>]
    #
    def extract_details(src)
      Array.wrap(src.try(:details) || src.try(:dig, DETAILS_KEY)).compact_blank
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include DataMethods

  # Logic which is not dependent on an ExecReport::Part instance.
  #
  module BaseMethods

    include ExecReport::BaseMethods
    include ExecReport::Part::DataMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Generate a rendering of the error report part.
    #
    # @param [any, nil] src           ExecReport::Part, Hash, Array, String
    # @param [Hash]     opt           Passed to #render_line
    #
    # @option opt [String, nil]  :separator
    # @option opt [Boolean, nil] :html
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    def render(src, **opt)
      opt[:html] = src.try(:html_safe?) if opt[:html].nil?
      render_line(src, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Generate a rendering of the error report part.
    #
    # @param [any, nil]    src        ExecReport::Part, Hash, Array, String
    # @param [String, nil] separator
    # @param [Hash]        opt
    #
    # @option opt [Boolean, nil] :html
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    # @see #render_topic
    # @see #render_details
    #
    def render_line(src, separator: TOPIC_SEP, **opt)
      src   = Array.wrap(src)
      label = render_topic(src.first, **opt)
      parts = render_details((src[1..] || src), **opt)
      line  = [label, parts].compact_blank!.presence or return
      opt[:html] ? html_join(line, separator) : line.join(separator)
    end

    # Render the leading topic portion of the report part.
    #
    # @param [any, nil] src           ExecReport::Part, Hash, Array, String
    # @param [Hash]     opt
    #
    # @option opt [String, nil] :separator  Default: `opt[:t_sep]`.
    # @option opt [String, nil] :t_sep      Default: #TOPIC_SEP.
    #
    # @return [ActiveSupport::SafeBuffer, String, nil]
    #
    # @see #render_portion
    #
    def render_topic(src, **opt)
      opt[:separator] ||= opt[:t_sep] || TOPIC_SEP
      src = extract_topic(src)   unless src.is_a?(String)
      # noinspection RubyMismatchedArgumentType
      render_portion(src, **opt) if src.present?
    end

    # Render the trailing details portion of the report part.
    #
    # @param [any, nil] src           ExecReport::Part, Hash, Array, String
    # @param [Hash]     opt
    #
    # @option opt [String, nil] :separator  Default: `opt[:d_sep]`.
    # @option opt [String, nil] :d_sep      Default: #DETAILS_SEP.
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    # @see #render_portion
    #
    def render_details(src, **opt)
      opt[:separator] ||= opt[:d_sep] || DETAILS_SEP
      src = [src]                if src.is_a?(String)
      src = extract_details(src) unless src.is_a?(Array)
      # noinspection RubyMismatchedArgumentType
      render_portion(src, **opt) if src.present?
    end

    # Render either the topic or details portion of the report part.
    #
    # @param [String, Array<String>, nil] src
    # @param [Hash]                       opt
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    # @see #render_part
    #
    def render_portion(src, **opt)
      src = src && Array.wrap(src).compact_blank.uniq.presence or return
      sep = opt[:separator]
      opt[:separators] = [sep, sep.strip]
      src.map! { |v| render_part(v, **opt) }
      opt[:html] ? html_join(src, sep) : src.join(sep)
    end

    # Generate a rendering of a single part of the entry.
    #
    # @param [String, nil] src
    # @param [Hash]        opt
    #
    # @option opt [Boolean, nil] :html
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    def render_part(src, **opt)
      src = src.try(:html_safe) || ERB::Util.h(src.to_s) if opt[:html]
      message_part(src, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include BaseMethods

  # ===========================================================================
  # :section: ExecReport::Part::DataMethods overrides
  # ===========================================================================

  public

  # Prepare an error report part for assignment to a database column.
  #
  # @param [any, nil] src             Default: `self`
  #
  # @return [String, nil]             *nil* if *src* was blank.
  #
  def serialize(src = nil)
    src ||= self
    super
  end

  # Interpret an error report part from a database column.
  #
  # @param [any, nil] src             Default: `self`
  #
  # @return [Array<Hash{Symbol=>String,Array<String>}>, nil]
  #
  def deserialize(src = nil)
    src ||= self
    super
  end

  # ===========================================================================
  # :section: ExecReport::DataMethods overrides
  # ===========================================================================

  public

  # Get topic/details from *src*.
  #
  # @param [any, nil] src             Default: `self`
  #
  # @return [Array<Hash{Symbol=>String,Array<String>}>]
  #
  def message_hashes(src = nil)
    [message_hash(src)]
  end

  # Get topic/details from *src*.
  #
  # @param [any, nil] src             Default: `self`
  #
  # @return [Hash{Symbol=>String,Array<String>}]
  #
  def message_hash(src = nil)
    src and super or @message_hash ||= super(self)
  end

  # ===========================================================================
  # :section: ExecReport::Part::BaseMethods overrides
  # ===========================================================================

  public

  # Generate a rendering of the error report part.
  #
  # @param [any, nil] src             Default: `self`
  # @param [Hash]     opt
  #
  # @option opt [String, nil]  :separator
  # @option opt [Boolean, nil] :html          Default: `#render_html`.
  #
  # @return [String, ActiveSupport::SafeBuffer, nil]
  #
  def render(src = nil, **opt)
    src ||= self
    super
  end

  # ===========================================================================
  # :section: ExecReport::BaseMethods overrides
  # ===========================================================================

  public

  # http_status
  #
  # @return [Integer, nil]
  #
  def http_status
    # noinspection RubyMismatchedReturnType
    info[__method__]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate an ExecReport::Part if necessary.
  #
  # @param [any, nil] src             ExecReport::Part or arg to initializer
  #
  # @return [ExecReport::Part]
  #
  def self.[](src)
    # noinspection RubyMismatchedReturnType
    src.is_a?(self) ? src : new(src)
  end

end

# Each instance translates to a distinct line in the flash message.
#
class ExecReport::FlashPart < ExecReport::Part

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [any, nil] topic     ExecReport::Part, Hash, String, Integer, Array
  # @param [any, nil] details   ExecReport::Part, Hash, String, Array
  #
  #--
  # === Variations
  #++
  #
  # @overload initialize(topic)
  #   @param [ExecReport::Part, Hash, String, Integer] topic
  #
  # @overload initialize(details)
  #   @param [Array] details
  #
  # @overload initialize(topic, details)
  #   @param [ExecReport::Part, Hash, String, Integer] topic
  #   @param [ExecReport::Part, Hash, String, Array]   details
  #
  def initialize(topic, details = nil)
    if details
      super(TOPIC_KEY => topic, DETAILS_KEY => details)
    else
      super(topic)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Logic which is not dependent on an ExecReport::Part instance.
  #
  module BaseMethods

    include ExecReport::Part::BaseMethods

    # =========================================================================
    # :section: ExecReport::Part::BaseMethods overrides
    # =========================================================================

    public

    # Generate a rendering of the error report part.
    #
    # @param [any, nil] src           ExecReport::Part, Hash
    # @param [Hash]     opt
    #
    # @option opt [Integer, nil] :first       Index of the first column.
    # @option opt [Integer, nil] :last        Index of the last column.
    # @option opt [String, nil]  :separator
    # @option opt [Boolean, nil] :html
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    def render(src, **opt)
      opt[:html] = src.try(:html_safe?) if opt[:html].nil?
      src = [extract_topic(src), *extract_details(src)] unless src.is_a?(Array)
      opt[:first] ||= 1
      opt[:last]  ||= opt[:first] + (positive(src.compact.size) || 1) - 1
      render_line(src, **opt)
    end

    # =========================================================================
    # :section: ExecReport::Part::BaseMethods overrides
    # =========================================================================

    protected

    # Render the leading topic portion of the report part.
    #
    # @param [any, nil] src           ExecReport::Part, Hash, Array, String
    # @param [Hash]     opt
    #
    # @return [ActiveSupport::SafeBuffer, String, nil]
    #
    def render_topic(src, **opt)
      opt[:start] ||= opt[:first]
      super
    end

    # Render the trailing details portion of the report part.
    #
    # @param [any, nil] src           ExecReport::Part, Hash, Array, String
    # @param [Hash]     opt
    #
    # @option opt [Integer, nil] :start
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    def render_details(src, **opt)
      opt[:start] ||= opt[:first] + 1
      super
    end

    # Render either the topic or details portion of the report part.
    #
    # @param [String, Array<String>] src
    # @param [Integer, nil]          start
    # @param [Hash]                  opt
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    # @see #render_part
    #
    def render_portion(src, start: nil, **opt)
      src = src && Array.wrap(src).compact_blank.uniq.presence or return
      sep = opt[:separator]
      opt[:separators] = [sep, sep.strip]
      idx = start || 1
      src.map!.with_index(idx) { |v, i| render_part(v, **opt, pos: i) }
      src.compact!
      opt[:html] ? html_join(src, sep) : src.join(sep) if src.present?
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include BaseMethods

  # ===========================================================================
  # :section: ExecReport::FlashPart::BaseMethods overrides
  # ===========================================================================

  public

  # Generate a rendering of the parts of the entry.
  #
  # @param [any, nil] src             ExecReport::Part, Hash; default: `self`.
  # @param [Hash]     opt
  #
  # @return [String, ActiveSupport::SafeBuffer, nil]
  #
  # @see #render_part
  #
  def render(src = nil, **opt)
    src ||= self
    super
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # A short-cut for creating a FlashPart only if required.
  #
  # @param [any, nil] src             FlashPart or arg to initializer
  #
  # @return [FlashPart]
  #
  def self.[](other)
    # noinspection RubyMismatchedReturnType
    other.is_a?(self) ? other : new(other)
  end

end

__loading_end(__FILE__)
