# lib/emma/debug.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Debugging support methods.
#
module Emma::Debug

  include Emma::Common

  # Separator between parts on a single debug line.
  #
  # @type [String]
  #
  DEBUG_SEPARATOR = ' | '

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Output arguments in a single line.
  #
  # @param [Array] args               Passed to #__debug.
  # @param [Proc]  block              Passed to #__debug.
  #
  # @return [nil]
  #
  def __debug_line(*args, &block)
    opt = { separator: DEBUG_SEPARATOR }
    opt.merge!(args.pop) if args.last.is_a?(Hash)
    __debug(*args, opt, &block)
  end

  # Output the parameters of the current method execution.
  #
  # @overload __debug_args(bind, *added, **opt)
  #   @param [Binding]        bind
  #   @param [Array]          added   Parts appended to the output line.
  #   @param [Hash]           opt     Passed to #get_params and #__debug_items.
  #   @param [Proc]           block   Passed to #__debug_items.
  #   @return [nil]
  #
  # @overload __debug_args(meth, bind, *added, **opt)
  #   @param [Symbol, Method] meth
  #   @param [Binding]        bind
  #   @param [Array]          added   Parts appended to the output line.
  #   @param [Hash]           opt     Passed to #get_params and #__debug_items.
  #   @param [Proc]           block   Passed to #__debug_items.
  #   @return [nil]
  #
  def __debug_args(*args, &block)
    prms_opt, opt = partition_options(args.extract_options!, :only, :except)
    meth = (args.shift unless args.first.is_a?(Binding))
    bind = (args.shift if args.first.is_a?(Binding))
    meth = bind.eval('__method__') if meth.nil? && bind.is_a?(Binding)
    prms = meth.is_a?(Method) || (meth.is_a?(Symbol) && bind.is_a?(Binding))
    prms = (get_params(meth, bind, prms_opt) if prms)
    opt[:separator] ||= DEBUG_SEPARATOR
    __debug_items(meth&.to_s, *args, prms, opt, &block)
  end

  # Output a line for invocation of a route method.
  #
  # @param [String, Symbol] controller  Default: `self.class.name`.
  # @param [String, Symbol] action      Default: `#calling_method`.
  # @param [Hash]           opt         Passed to #__debug_line.
  # @param [Proc]           block       Passed to #__debug_items.
  #
  # @return [nil]
  #
  def __debug_route(controller: nil, action: nil, **opt, &block)
    action ||= calling_method
    leader = __debug_route_label(controller: controller, action: action)
    __debug_line(leader, "params = #{params.inspect}", opt, &block)
    __debug_items(opt, &block) if block
  end

  # Output request values and contents.
  #
  # @param [Array] args               Passed to #__debug_items.
  # @param [Proc]  block              Passed to #__debug_items.
  #
  # args[0]  [Symbol]                 Calling method (def: `#calling_method`).
  # args[-1] [Hash]                   Options passed to #__debug except for:
  #
  # @option args.last [ActionDispatch::Request] :req  Default: `#request`.
  #
  # @return [nil]
  #
  def __debug_request(*args, &block)
    opt = args.last.is_a?(Hash) ? args.last.dup : {}
    req = opt.delete(:req) || request
    unless opt.key?(:leader)
      meth = args.first.is_a?(Symbol) ? args.shift : calling_method
      opt[:leader] = "-- #{meth}"
    end
    count = 80
    count -= opt[:leader].size + 1 if opt[:leader]
    {
      session:           ['SESSION', :__debug_session_hash],
      'request.headers': ['HEADER',  :__debug_header_hash],
      'request.env':     ['ENV',     :__debug_env_hash],
      'request.cookies': ['COOKIE',  req.cookies],
      'request.body':    req.body
    }.each_pair do |item, entry|
      prefix, value = entry.is_a?(Array) ? entry : [nil, entry]
      # noinspection RubyCaseWithoutElseBlockInspection
      case value
        when Proc   then value = value.call(req)
        when Symbol then value = send(value, req)
      end
      lines = __debug_inspect_item(value, opt)
      lines.map! { |line| "[#{prefix}] #{line}" } if prefix
      item = +"== #{item} "
      item << '=' * (count - item.size)
      __debug(item, *lines, opt)
    end
    __debug_items(*args, opt, &block) if block || args.present?
  end

  # Exception console debugging output.
  #
  # @param [String]    label
  # @param [Exception] exception
  # @param [Array]     args           Passed to #__debug_line.
  # @param [Proc]      block          Passed to #__debug_line.
  #
  # @return [nil]
  #
  def __debug_exception(label, exception, *args, &block)
    opt = args.extract_options!.reverse_merge(leader: '!!!')
    args << "#{label} #{exception.class}"
    args << "ERROR: #{exception.message}"
    args << "bs_api_error_message = #{bs_api_error_message.inspect}"
    args << "flash.now[:alert] = #{flash.now[:alert].inspect}"
    __debug_line(*args, opt, &block)
  end

  # Output each data item on its own line.
  #
  # @param [Array] args               Passed to #__debug.
  # @param [Proc]  block              Passed to #__debug_inspect_items.
  #
  # @return [nil]
  #
  def __debug_items(*args, &block)
    opt = args.extract_options!
    items = block ? __debug_inspect_items(opt, &block) : []
    __debug(*args, *items, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Representation of the controller/action for a route.
  #
  # @param [String, Symbol] controller  Default: `self.class.name`.
  # @param [String, Symbol] action      Default: `#calling_method`.
  #
  # @return [String]
  #
  def __debug_route_label(controller: nil, action: nil)
    controller = (controller || self.class.name || params[:controller]).to_s
    controller =
      controller.underscore.split('_').tap { |parts|
        parts.pop if !controller.include?('_') && (parts.size > 1)
      }.map!(&:upcase).join('_')
    action ||= calling_method
    "#{controller} #{action}"
  end

  # __debug_session_hash
  #
  # @param [Hash, ActionDispatch::Request, ActionDispatch::Request::Session] value
  #
  # @return [Hash, nil]
  #
  # noinspection RubyNilAnalysis
  def __debug_session_hash(value = nil)
    value ||= request       if respond_to?(:request)
    value   = value.session if value.respond_to?(:session)
    value ||= session       if respond_to?(:session)
    if value.respond_to?(:to_hash)
      # noinspection RubyYardReturnMatch
      value.to_hash
    elsif value.respond_to?(:each)
      Hash.new.tap { |result| value.each { |k, v| result[k] = v } }
    end
  end

  # __debug_env_hash
  #
  # @param [Hash, ActionDispatch::Request] value
  #
  # @return [Hash, nil]
  #
  def __debug_env_hash(value = nil)
    value ||= request
    value = value.env if value.respond_to?(:env)
    # noinspection RubyYardReturnMatch
    value&.to_hash&.sort&.to_h
  end

  # __debug_header_hash
  #
  # @param [Hash, ActionDispatch::Request, ActionDispatch::Response] value
  #
  # @return [Hash, nil]
  #
  def __debug_header_hash(value = nil)
    value ||= request
    value = value.headers if value.respond_to?(:headers)
    if value.respond_to?(:to_hash)
      # noinspection RubyYardReturnMatch
      value.to_hash
    elsif value.respond_to?(:each)
      Hash.new.tap do |result|
        value.each do |k, v|
          next unless (k = k.to_s) =~ /^[A-Z0-9_]+$/
          next if ActionDispatch::Http::Headers::CGI_VARIABLES.include?(k)
          k = k.delete_prefix('HTTP_').downcase
          k = k.split('_').map(&:camelize).join('-')
          result[k] = v
        end
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Truncate long inspection results to this number of characters.
  #
  # @type [Integer]
  #
  DEBUG_INSPECT_MAX = application_deployed? ? 4096 : 1024

  # Truncation indicator appended to a truncated output.
  #
  # @type [String]
  #
  DEBUG_INSPECT_OMISSION = '...'

  # Classes that don't need to be specially annotated in #__debug_inspect.
  #
  # @type [Array<Class>]
  #
  DEBUG_INSPECT_COMMON = [
    Array,
    FalseClass,
    Hash,
    Integer,
    NilClass,
    String,
    Symbol,
    TrueClass,
    ActionController::Parameters,
  ].freeze

  # Decorate and truncate inspection results.
  #
  # @param [*]       value
  # @param [Integer] max              Default: #DEBUG_INSPECT_MAX.
  # @param [String]  omission         Default: #DEBUG_INSPECT_OMISSION.
  #
  # @return [String]
  #
  # @see Module#inspect
  #
  def __debug_inspect(value, max: nil, omission: nil, **)
    output = type = common = nil
    max      ||= DEBUG_INSPECT_MAX
    omission ||= DEBUG_INSPECT_OMISSION
    case value
      when Hash   then omission += '}'
      when Array  then omission += ']'
      when String then omission += '"'
      else             omission += '>'
    end
    type   = value.class
    common = DEBUG_INSPECT_COMMON.any? { |cls| (type == cls) || (type < cls) }
    output = (value if common)
    output ||=
      case value
        when ActionDispatch::RemoteIp::GetIp then value.to_s
        when Exception then value.full_message
        when StringIO  then value.string
        when STDERR    then :'<STDERR>'
        when STDOUT    then :'<STDOUT>'
        else                value.path if value.respond_to?(:path)
      end
    if output.nil? || output.is_a?(Symbol)
      output = output.to_s
    else
      output = output.inspect
    end
  rescue => e
    Log.debug { "#{__method__}: #{value.class}: #{e}" }
  ensure
    type   = ("{#{type}}" unless common)
    output = output&.truncate(max, omission: omission) || 'ERROR'
    return [type, output].compact.join(' ')
  end

  # Generate one or more inspections.
  #
  # @param [Hash, Array, *] value
  # @param [Hash, nil]      opt       Options passed to #__debug_inspect.
  #
  # @return [Array<String>]
  #
  def __debug_inspect_item(value, opt = nil)
    if value.is_a?(Hash)
      value.map { |k, v| "#{k} = #{__debug_inspect(v, **opt)}" }
    else
      Array.wrap(value).map { |v| __debug_inspect(v, **opt) }
    end
  end

  # Produce an inspection for each argument.
  #
  # @param [Array] args
  #
  # args[-1] [Hash]                   Options passed to #__debug_inspect_item.
  #
  # @return [Array<String>]
  #
  # @yield To supply additional items.
  # @yieldreturn [*, Array<*>]
  #
  # @see #__debug_inspect_item
  #
  def __debug_inspect_items(*args)
    opt = args.last.is_a?(Hash) && (block_given? || (args.size > 1))
    opt = opt ? args.pop : {}
    args += Array.wrap(yield) if block_given?
    args.flat_map { |arg| __debug_inspect_item(arg, opt) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  # Neutralize debugging methods when not debugging.
  unless CONSOLE_DEBUGGING
    instance_methods(false).each do |m|
      module_eval "def #{m}(*); end"
    end
  end

end

__loading_end(__FILE__)
