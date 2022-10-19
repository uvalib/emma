# lib/emma/debug.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'emma/common'

# Debugging support methods.
#
module Emma::Debug

  # Methods for processing values for debug output.
  #
  module FormatMethods

    include Emma::Common

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Separator between parts on a single debug line.
    #
    # @type [String]
    #
    DEBUG_SEPARATOR = ' | '

    # Truncate long inspection results to this number of characters.
    #
    # @type [Integer]
    #
    DEBUG_INSPECT_MAX = 1024

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
      ActionController::Parameters,
      Array,
      FalseClass,
      Hash,
      NilClass,
      Numeric,
      String,
      StringIO,
      Symbol,
      TrueClass,
    ].freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Representation of the calling method.
    #
    # @param [String, Symbol, Binding, nil] call_class   Def: `self.class.name`
    # @param [String, Symbol, Method,  nil] call_method  Def: `#calling_method`
    #
    # @return [String]
    #
    def __debug_label(call_class: nil, call_method: nil, **)
      # noinspection RubyNilAnalysis
      call_method = call_method.name if call_method.is_a?(Method)
      if call_class.is_a?(Binding)
        call_method ||= call_class.eval('__method__')
        call_class = nil
      end
      call_method ||= calling_method
      call_class  ||= self.class.name
      "#{call_class} #{call_method}"
    end

    # Representation of the controller/action for a route.
    #
    # @param [String, Symbol, nil] controller   Default: `self.class.name`.
    # @param [String, Symbol, nil] action       Default: `#calling_method`.
    #
    # @return [String]
    #
    def __debug_route_label(controller: nil, action: nil, **)
      action     ||= calling_method
      controller ||= self.class.name
      controller ||= (params[:controller] if respond_to?(:params))
      controller =
        controller.to_s.underscore.split('_').tap { |parts|
          # noinspection RubyNilAnalysis
          parts.pop if !controller.include?('_') && (parts.size > 1)
        }.map!(&:upcase).join('_')
      __debug_label(call_class: controller, call_method: action)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Session values transformed into a Hash.
    #
    # @param [Hash, ActionDispatch::Request, ActionDispatch::Request::Session] value
    #
    # @return [Hash]
    # @return [nil]                   If *value* is invalid or indeterminate.
    #
    #--
    # noinspection RailsParamDefResolve
    #++
    def __debug_session_hash(value = nil)
      value ||= try(:request)
      value   = value.session if value.respond_to?(:session)
      value ||= try(:session)
      if value.respond_to?(:to_hash)
        value.to_hash
      elsif value.respond_to?(:each)
        Hash.new.tap { |result| value.each { |k, v| result[k] = v } }
      end
    end

    # Environment values transformed into a Hash.
    #
    # @param [Hash, ActionDispatch::Request] value
    #
    # @return [Hash]
    # @return [nil]                   If *value* is invalid or indeterminate.
    #
    #--
    # noinspection RailsParamDefResolve
    #++
    def __debug_env_hash(value = nil)
      value ||= try(:request)
      value = value.env if value.respond_to?(:env)
      value&.to_hash&.sort&.to_h
    end

    # HTTP message headers transformed into a Hash.
    #
    # @param [Hash, ActionDispatch::Request, ActionDispatch::Response] value
    #
    # @return [Hash]
    # @return [nil]                   If *value* is invalid or indeterminate.
    #
    #--
    # noinspection RailsParamDefResolve
    #++
    def __debug_header_hash(value = nil)
      value ||= try(:request)
      value = value.headers if value.respond_to?(:headers)
      if value.respond_to?(:to_hash)
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

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Produce an inspection for each argument.
    #
    # @param [Array<*>] args
    # @param [Hash]     opt           Options passed to #__debug_inspect_item.
    #
    # @return [Array<String>]
    #
    # @yield To supply additional items.
    # @yieldreturn [Any, Array<Any>]
    #
    # @see #__debug_inspect_item
    #
    def __debug_inspect_items(*args, **opt)
      args += Array.wrap(yield) if block_given?
      # noinspection RubyMismatchedReturnType
      args.flat_map { |arg| __debug_inspect_item(arg, **opt) }
    end

    # Generate one or more inspections.
    #
    # @param [Hash, Array, *] value
    # @param [Hash]           opt     Options passed to #__debug_inspect except
    #
    # @option opt [Boolean] :compact  If *true*, ignore empty values (but show
    #                                   if value is a FalseClass).
    #
    # @return [Array<String>]
    #
    def __debug_inspect_item(value, **opt)
      compact = opt.delete(:compact)
      if value.is_a?(Hash)
        value.map { |k, v|
          next if compact && v.blank? && !v.is_a?(FalseClass)
          "#{k} = #{__debug_inspect(v, **opt)}"
        }.compact
      else
        Array.wrap(value).map { |v| __debug_inspect(v, **opt) }
      end
    end

    # Decorate and truncate inspection results.
    #
    # @param [Any]     value
    # @param [Integer] max            Default: #DEBUG_INSPECT_MAX.
    # @param [String]  omission       Default: #DEBUG_INSPECT_OMISSION.
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
      common = DEBUG_INSPECT_COMMON.any? { |t| (type == t) || (type < t) }
      output = (value if common)
      output ||=
        case value
          when ActionDispatch::RemoteIp::GetIp then value.to_s
          when Exception                       then value.full_message
          when StringIO                        then value.string
          when STDERR                          then :'<STDERR>'
          when STDOUT                          then :'<STDOUT>'
          else                                      value.try(:path)
        end
      if output.nil? || output.is_a?(Symbol)
        output = output.to_s
      else
        output = to_utf8(output).inspect
      end
    rescue => error
      Log.debug { "#{__method__}: #{value.class}: #{error}" }
    ensure
      type   = ("{#{type}}" unless common)
      output = output&.truncate(max, omission: omission) || 'ERROR'
      return [type, output].compact.join(' ')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Generate lines to produce boxed-line text.
    #
    # @param [String]  text
    # @param [Integer] line_length
    # @param [Integer] gap_width
    # @param [String]  char
    #
    # @return [Array<String>]
    #
    def __debug_box(text, line_length: 80, gap_width: 2, char: '#', **)
      bar   = char * line_length
      side  = char * 4
      space = ' '
      max   = line_length - (2 * (side.size + gap_width))
      label = text.strip
      if label.size > max
        middle = space * max
        left   = space * gap_width
        right  = space * gap_width
        spacer = [side, left, middle, right, side].join
        label  = [side, left, label].join
      else
        middle = space * label.size
        free   = max - middle.size + (2 * gap_width)
        left   = free / 2
        right  = left + (free - (2 * left))
        left   = space * left
        right  = space * right
        spacer = [side, left, middle, right, side].join
        label  = [side, left, label,  right, side].join
      end
      [
        bar,
        bar,
        spacer,
        label,
        spacer,
        bar,
        bar
      ]
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
    end

  end

  # Methods for emitting debug output.
  #
  # When a module includes "Emma::Debug", these are made available only if
  # CONSOLE_DEBUGGING is defined.
  #
  module OutputMethods

    include FormatMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Output arguments in a single line.
    #
    # @param [Array<*>] args          Passed to #__debug_impl.
    # @param [Hash]     opt
    # @param [Proc]     block         Passed to #__debug_impl.
    #
    # @return [nil]
    #
    def __debug_line(*args, **opt, &block)
      opt.reverse_merge!(separator: DEBUG_SEPARATOR)
      __debug_impl(*args, **opt, &block)
    end

    # Output each data item on its own line, with special handling to inject
    # the parameter values of the calling method if a Binding is given.
    #
    # @param [Array<*>] args          Passed to #__debug_line.
    # @param [Hash]     opt
    # @param [Proc]     block         Passed to #__debug_inspect_items.
    #
    # @return [nil]
    #
    #--
    # == Variations
    #++
    #
    # @overload __debug_items(meth, bind, *parts, **opt)
    #   Injects the parameters of the calling method as indicated by *bind*.
    #   @param [Symbol, Method] meth    Start of the output line.
    #   @param [Binding]        bind    Source of appended parameter values.
    #   @param [Array<*>]       parts   Parts of the output line.
    #   @param [Hash]           opt     Passed to #__debug_line except for:
    #   @option opt [Any] :only         Passed to #get_params.
    #   @option opt [Any] :except       Passed to #get_params.
    #
    # @overload __debug_items(bind, *parts, **opt)
    #   Injects the parameters of the calling method as indicated by *bind*.
    #   @param [Binding]        bind    Source of appended parameter values.
    #   @param [Array<*>]       parts   Parts of the output line.
    #   @param [Hash]           opt     Passed to #__debug_line except for:
    #   @option opt [Any] :only         Passed to #get_params.
    #   @option opt [Any] :except       Passed to #get_params.
    #
    # @overload __debug_items(*parts, **opt)
    #   The normal case with *parts* on a single output line.
    #   @param [Array<*>]       parts   Parts of the output line.
    #   @param [Hash]           opt     Passed to #__debug_line.
    #
    def __debug_items(*args, **opt, &block)
      gp_opt = extract_hash!(opt, :only, :except)
      meth, bind = args.first(2)
      if bind.is_a?(Binding)
        args.shift(2)
      elsif meth.is_a?(Binding)
        args.shift
        meth, bind = [nil, meth]
      end

      # Append calling method parameter values if possible.
      # Prepend the method label if it was given or could be determined.
      if bind.is_a?(Binding)
        prms = get_params(meth, bind, **gp_opt).presence
        unless meth.is_a?(String)
          meth = get_method(meth, bind) || calling_method
          meth = __debug_label(call_method: meth)
        end
        args = [meth, *args, prms].compact
      end

      items = block ? __debug_inspect_items(**opt, &block) : []
      __debug_line(*args, *items, **opt)
    end

    # Exception console debugging output.
    #
    # @param [String]    label
    # @param [Exception] exception
    # @param [Array<*>]  args         Passed to #__debug_line.
    # @param [Hash]      opt
    # @param [Proc]      block        Passed to #__debug_line.
    #
    # args[-1] [Hash]                 Options passed to #__debug except for:
    #
    # @option args.last [Boolean] :trace  Finish with a call stack trace to log
    #                                       output.
    #
    # @return [nil]
    #
    def __debug_exception(label, exception, *args, **opt, &block)
      opt.reverse_merge!(leader: '!!!')
      trace = opt.delete(:trace)
      args << "#{label} #{exception.class}"
      args << "ERROR: #{exception.message}"

      # Parts that are only relevant from a controller/view.
      if defined?(flash)
        args << "flash.now[:alert] = #{flash.now[:alert].inspect}"
        args +=
          ApiService.table(user: current_user).map { |service, instance|
            error = instance.exec_report
            "#{service} ERROR: #{error.inspect}" if error.present?
          }.compact
      end

      __debug_line(*args, **opt, &block)
      Log.warn { exception.full_message(order: :top) } if trace
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
    #--
    # noinspection RailsParamDefResolve
    #++
    def __debug_route(controller: nil, action: nil, **opt, &block)
      action ||= calling_method
      leader   = __debug_route_label(controller: controller, action: action)
      prms     = try(:params)&.inspect || 'n/a'
      __debug_line(leader, "params = #{prms}", **opt)
      __debug_items(**opt, &block) if block
    end

    # Output request values and contents.
    #
    # @param [Array<*>]                args   Passed to #__debug_items.
    # @param [ActionDispatch::Request] req    Default: `#request`.
    # @param [Hash]                    opt    Passed to #__debug_items.
    # @param [Proc]                    block  Passed to #__debug_items.
    #
    # @return [nil]
    #
    #--
    # == Variations
    #++
    #
    # @overload __debug_request(meth, *args, req: nil, **opt)
    #   Specify calling method.
    #   @param [Symbol]                  meth
    #   @param [Array<*>]                args
    #   @param [ActionDispatch::Request] req
    #   @param [Hash]                    opt
    #   @return [nil]
    #
    # @overload __debug_request(*args, req: nil, **opt)
    #   Calling method defaults to `#calling_method`.
    #   @param [Array<*>]                args
    #   @param [ActionDispatch::Request] req
    #   @param [Hash]                    opt
    #   @return [nil]
    #
    def __debug_request(*args, req: nil, **opt, &block)
      req ||= request
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
        # noinspection RubyMismatchedArgumentType
        lines = __debug_inspect_item(value, **opt)
        lines.map! { |line| "[#{prefix}] #{line}" } if prefix
        item = +"== #{item} "
        item << '=' * (count - item.size)
        __debug_impl(item, *lines, **opt)
      end
      __debug_items(*args, **opt, &block) if block || args.present?
    end

    # Output a box which highlights the given text.
    #
    # @param [String] text
    # @param [Hash]   opt             Passed to #__debug_box.
    #
    # @return [nil]
    #
    def __debug_banner(text, **opt)
      __debug_impl("\n")
      __debug_impl(__debug_box(text, **opt))
      __debug_impl("\n")
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Within the block, output to $stderr is captured and returned as a string.
  #
  # @return [String]
  #
  # @yield Block to execute.
  # @yieldreturn [void]
  #
  # @note Currently unused.
  #
  def capture_stderr
    saved, $stderr = $stderr, StringIO.new
    yield
    $stderr.string
  ensure
    # noinspection RubyMismatchedReturnType
    $stderr = saved
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  if CONSOLE_DEBUGGING

    include FormatMethods
    include OutputMethods

  else

    include FormatMethods

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # If CONSOLE_DEBUGGING is *false*, all of the debug output methods are
    # neutralized so that debug statements are syntactically correct but will
    # not emit output and their blocks will not be evaluated.
    #
    # @param [Module] base
    #
    def self.included(base)
      OutputMethods.instance_methods(false).each { |m| base.neutralize(m) }
      base
    end

  end

end

__loading_end(__FILE__)
