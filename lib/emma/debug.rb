# lib/emma/debug.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'puma/null_io'

# Debugging support methods.
#
module Emma::Debug

  include Emma::Common

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
    opt = args.extract_options!
    opt[:separator] ||= ' | '
    __debug(*args, opt, &block)
  end

  # Output the parameters of the current method execution.
  #
  # @overload __debug_args(bind, *added, **opt)
  #   @param [Binding]        bind
  #   @param [Array]          added   Parts appended to the output line.
  #   @param [Hash]           opt     Passed to #get_params and #__debug_line.
  #   @return [nil]
  #
  # @overload __debug_args(meth, bind, [opt])
  #   @param [Symbol, Method] meth
  #   @param [Binding]        bind
  #   @param [Array]          added   Parts appended to the output line.
  #   @param [Hash]           opt     Passed to #get_params and #__debug_line.
  #   @return [nil]
  #
  # @yield Supply additional items to output.
  # @yieldreturn [Hash,Array,String,*]
  #
  # @example Output current method parameters
  #   __debug_args(__method__, binding)
  #
  def __debug_args(*args)
    p_opt, opt = partition_options(args.extract_options!, :only, :except)
    meth = (args.shift unless args.first.is_a?(Binding))
    bind = (args.shift if args.first.is_a?(Binding))
    lead = opt.key?(:leader) ? opt.delete(:leader) : '+++'
    lead = [lead, meth].compact.join(' ')
    args << get_params(meth, bind, p_opt)
    if block_given?
      __debug_line(lead, *args, opt) { __debug_inspect_items(*yield, opt) }
    else
      __debug_line(lead, *args, opt)
    end
  end

  # Output a line for invocation of a route method.
  #
  # If the route method is not passed as a Symbol in *args* then
  # `#calling_method` is used.
  #
  # @overload __debug_route(controller = nil, method = nil, **opt)
  #   @param [String, Symbol] controller
  #   @param [String, Symbol] method
  #   @param [Hash]           opt         Passed to #__debug_line.
  #
  # @overload __debug_route(method = nil, **opt)
  #   @param [String, Symbol] method
  #   @param [Hash]           opt         Passed to #__debug_line.
  #
  # @return [nil]
  #
  def __debug_route(controller = nil, method = nil, **opt, &block)
    controller, method = [nil, controller] if controller.is_a?(Symbol)
    controller ||= self.class.name || params[:controller]
    parts = controller.to_s.underscore.split('_')
    parts.pop if !controller.include?('_') && (parts.size > 1)
    parts.map!(&:upcase)
    parts << (method || calling_method)
    __debug_line(parts.join(' '), "params = #{params.inspect}", opt, &block)
  end

  # Output request values and contents.
  #
  # @param [Array] args
  # @param [Proc]  block              Passed to #__debug_items.
  #
  # args[0]  [Symbol]                 Calling method (def: `#calling_method`).
  # args[-1] [Hash]                   Options passed to #__debug.
  #
  # @return [nil]
  #
  def __debug_request(*args, &block)
    opt = args.extract_options!
    unless opt.key?(:leader)
      meth = args.first.is_a?(Symbol) ? args.shift : calling_method
      opt[:leader] = "--- #{meth}"
    end
    {
      session:           ['/ SESSION', session],
      'request.env':     ['- ENV',     request.env],
      'request.headers': ['\ HEADER',  request.headers],
      'request.cookies': ['| COOKIE]', request.cookies],
      'rack.input':      request.headers['rack.input'],
      'request.body':    request.body
    }.each_pair do |item, entry|
      prefix, value = entry.is_a?(Array) ? entry : [nil, entry]
      lines = __debug_inspect_item(value, opt)
      lines.map! { |line| "#{prefix} #{line}" } if prefix && lines.is_a?(Array)
      __debug("#{item} =", *lines, opt)
    end
    __debug_items(*args, opt, &block) if block || args.present?
  end

  # OmniAuth endpoint console debugging output.
  #
  # If the endpoint method is not passed as a Symbol in *args* then
  # `#calling_method` is used.
  #
  # @param [Array] args               Additional value(s) to output.
  # @param [Proc]  block              Passed to #__debug_line.
  #
  # args[-1] [Hash]                   Options passed to #__debug_line.
  #
  # @return [nil]
  #
  def __debug_auth(*args, &block)
    opt  = args.extract_options!
    meth = args.first.is_a?(Symbol) ? args.shift : calling_method
    lead = "OMNIAUTH #{meth}"
    req  = (request&.method if respond_to?(:request))
    prms = (params.inspect  if respond_to?(:params))
    args = [req, prms, *args].compact
    __debug_line(lead, *args, opt, &block)
  end

  # Exception console debugging output.
  #
  # @param [String]    label
  # @param [Exception] exception
  # @param [Array]     args
  # @param [Proc]      block          Passed to #__debug_line.
  #
  # args[-1] [Hash]                   Options passed to #__debug_line.
  #
  # @return [nil]
  #
  def __debug_exception(label, exception, *args, &block)
    opt = args.extract_options!
    opt[:leader] ||= '!!!'
    args << "#{label} #{exception.class}"
    args << "ERROR: #{exception.message}"
    args << "api_error_message = #{api_error_message.inspect}"
    args << "flash.now[:alert] = #{flash.now[:alert].inspect}"
    __debug_line(*args, opt, &block)
  end

  # Output each data item on its own line.
  #
  # @param [Array] args
  #
  # args[-1] [Hash]   Options passed to #__debug and #__debug_inspect_items.
  #
  # @return [nil]
  #
  # @yield Supply additional items to output.
  # @yieldreturn [Hash,Array,String,*]
  #
  def __debug_items(*args)
    opt = args.extract_options!
    args += Array.wrap(yield) if block_given?
    __debug(opt) { __debug_inspect_items(*args, opt) }
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
  DEBUG_INSPECT_COMMON_CLASSES = [
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
    leader = trailer = nil
    # noinspection RubyCaseWithoutElseBlockInspection
    case value
      when Puma::NullIO then leader = '(empty body)'
    end
    unless DEBUG_INSPECT_COMMON_CLASSES.include?(value.class)
      leader += ' ' if leader.present?
      leader = "#{leader}{%s}" % value.class
    end
    max      ||= DEBUG_INSPECT_MAX
    omission ||= DEBUG_INSPECT_OMISSION
    omission +=
      case value
        when Hash   then '}'
        when Array  then ']'
        when String then '"'
        else             '>'
      end
    value = value.inspect.truncate(max, omission: omission)
    [leader, value, trailer].compact.join(' ')
  end

  # Produce an inspection.
  #
  # @overload __debug_inspect(arg)
  #   @param [Hash, Array] arg
  #   @param [Hash, nil]   opt        Options passed to #__debug_inspect.
  #   @return [Array<String>]
  #
  # @overload __debug_inspect(arg)
  #   @param [*]           arg
  #   @param [Hash, nil]   opt        Options passed to #__debug_inspect.
  #   @return [String]
  #
  def __debug_inspect_item(arg, opt = nil)
    opt ||= {}
    case arg
      when Hash     then arg.map { |k, v| "#{k} = #{__debug_inspect(v, opt)}" }
      when Array    then arg.map { |v| __debug_inspect(v, opt) }
      when StringIO then __debug_inspect(arg.string, opt)
      when Tempfile then __debug_inspect(arg.path, opt)
      when IO       then __debug_inspect(arg.path, opt)
      else               __debug_inspect(arg, opt)
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
  # @see #__debug_inspect_item
  #
  def __debug_inspect_items(*args)
    opt = {}
    if block_given?
      opt = args.pop if args.last.is_a?(Hash)
      args += Array.wrap(yield)
    else
      opt = args.pop if args.last.is_a?(Hash) && (args.size > 1)
    end
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
