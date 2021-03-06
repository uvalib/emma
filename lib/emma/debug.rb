# lib/emma/debug.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Debugging support methods.
#
module Emma::Debug

  # Methods for processing values for debug output.
  #
  module FormatMethods

    # @private
    def self.included(base)
      base.send(:extend, self)
    end

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
    def __debug_label(call_class: nil, call_method: nil)
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
    def __debug_route_label(controller: nil, action: nil)
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
    # noinspection RailsParamDefResolve, RubyYardReturnMatch
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
    # noinspection RailsParamDefResolve, RubyYardReturnMatch
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
    # @param [Array] args
    #
    # args[-1] [Hash]                 Options passed to #__debug_inspect_item.
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

    # Generate one or more inspections.
    #
    # @param [Hash, Array, *] value
    # @param [Hash, nil]      opt     Options passed to #__debug_inspect except
    #
    # @option opt [Boolean] :compact  If *true*, ignore empty values (but show
    #                                   if value is a FalseClass).
    #
    # @return [Array<String>]
    #
    def __debug_inspect_item(value, opt = nil)
      compact = opt&.dig(:compact)
      opt     = opt&.except(:compact)
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
    # @param [*]       value
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
        output = output.inspect
      end
    rescue => error
      Log.debug { "#{__method__}: #{value.class}: #{error}" }
    ensure
      type   = ("{#{type}}" unless common)
      output = output&.truncate(max, omission: omission) || 'ERROR'
      return [type, output].compact.join(' ')
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
    # @param [Array] args             Passed to #__debug_impl.
    # @param [Proc]  block            Passed to #__debug_impl.
    #
    # @return [nil]
    #
    def __debug_line(*args, &block)
      # noinspection RubyNilAnalysis
      opt = args.extract_options!.reverse_merge(separator: DEBUG_SEPARATOR)
      __debug_impl(*args, opt, &block)
    end

    # Output each data item on its own line, with special handling to inject
    # the parameter values of the calling method if a Binding is given.
    #
    # @param [Array] args             Passed to #__debug_line.
    # @param [Proc]  block            Passed to #__debug_inspect_items.
    #
    # @return [nil]
    #
    # == Variations
    #
    # @overload __debug_items(meth, bind, *parts, **opt)
    #   Injects the parameters of the calling method as indicated by *bind*.
    #   @param [Symbol, Method] meth    Start of the output line.
    #   @param [Binding]        bind    Source of appended parameter values.
    #   @param [Array]          parts   Parts of the output line.
    #   @param [Hash]           opt     Passed to #__debug_line except for:
    #   @option opt [*] :only           Passed to #get_params.
    #   @option opt [*] :except         Passed to #get_params.
    #
    # @overload __debug_items(bind, *parts, **opt)
    #   Injects the parameters of the calling method as indicated by *bind*.
    #   @param [Binding]        bind    Source of appended parameter values.
    #   @param [Array]          parts   Parts of the output line.
    #   @param [Hash]           opt     Passed to #__debug_line except for:
    #   @option opt [*] :only           Passed to #get_params.
    #   @option opt [*] :except         Passed to #get_params.
    #
    # @overload __debug_items(*parts, **opt)
    #   The normal case with *parts* on a single output line.
    #   @param [Array]          parts   Parts of the output line.
    #   @param [Hash]           opt     Passed to #__debug_line.
    #
    def __debug_items(*args, &block)
      opt = args.extract_options!

      # Variations to inject the parameters of the calling method.
      if args[0..1].any? { |arg| arg.is_a?(Binding) }

        # Extract the method and/or binding from *args*.
        gp_opt, opt = partition_hash(opt, :only, :except)
        meth = (args.shift unless args.first.is_a?(Binding))
        bind = (args.shift if args.first.is_a?(Binding))
        meth ||= (bind.eval('__method__') if bind.is_a?(Binding))

        # Append calling method parameter values if possible.
        prms = meth.is_a?(Method) || bind.is_a?(Binding)
        args << get_params(meth, bind, gp_opt) if prms

        # Prepend the method label if it was given or could be determined.
        unless meth.is_a?(String)
          meth = __debug_label(call_method: (meth || calling_method))
        end
        args.prepend(meth) if meth

      end

      items = block ? __debug_inspect_items(*[opt], &block) : []
      __debug_line(*args, *items, opt)
    end

    # Exception console debugging output.
    #
    # @param [String]    label
    # @param [Exception] exception
    # @param [Array]     args         Passed to #__debug_line.
    # @param [Proc]      block        Passed to #__debug_line.
    #
    # args[-1] [Hash]                 Options passed to #__debug except for:
    #
    # @option args.last [Boolean] :trace  Finish with a call stack trace to log
    #                                       output.
    #
    # @return [nil]
    #
    def __debug_exception(label, exception, *args, &block)
      # noinspection RubyNilAnalysis
      opt   = args.extract_options!.reverse_merge(leader: '!!!')
      trace = opt.delete(:trace)
      args << "#{label} #{exception.class}"
      args << "ERROR: #{exception.message}"

      # Parts that are only relevant from a controller/view.
      if defined?(flash)
        args << "flash.now[:alert] = #{flash.now[:alert].inspect}"
        args +=
          ApiService.table.map { |service, instance|
            error = instance.error_message
            "#{service} ERROR: #{error.inspect}" if error.present?
          }.compact
      end

      __debug_line(*args, opt, &block)
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
      __debug_line(leader, "params = #{prms}", opt)
      __debug_items(opt, &block) if block
    end

    # Output request values and contents.
    #
    # @param [Array] args             Passed to #__debug_items.
    # @param [Proc]  block            Passed to #__debug_items.
    #
    # args[0]  [Symbol]               Calling method (def: `#calling_method`).
    # args[-1] [Hash]                 Options passed to #__debug except for:
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
        __debug_impl(item, *lines, opt)
      end
      __debug_items(*args, opt, &block) if block || args.present?
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  if CONSOLE_DEBUGGING

    include FormatMethods
    include OutputMethods

  else

    include FormatMethods

    # If CONSOLE_DEBUGGING is *false*, all of the debug output methods are
    # neutralized so that debug statements are syntactically correct but will
    # not emit output and their blocks will not be evaluated.
    #
    # @param [Module] base
    #
    # @private
    #
    def self.included(base)
      OutputMethods.instance_methods(false).each { |m| base.neutralize(m) }
    end

  end

end

__loading_end(__FILE__)
