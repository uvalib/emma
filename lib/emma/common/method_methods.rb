# lib/emma/common/method_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma::Common::MethodMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the name of the calling method.
  #
  # @param [Array<String>, Integer, nil] call_stack
  #
  # @return [String, nil]
  #
  # == Variations
  #
  # @overload calling_method()
  #   Using *call_stack* defaulting to `#caller(2)`.
  #   @return [String]
  #
  # @overload calling_method(call_stack)
  #   @param [Array<String>] call_stack
  #   @return [String]
  #
  # @overload calling_method(depth)
  #   @param [Integer] depth              Call stack depth (default: 2)
  #   @return [String]
  #
  def calling_method(call_stack = nil)
    depth = 2
    if call_stack.is_a?(Integer)
      depth = call_stack if call_stack > depth
      call_stack = nil
    end
    call_stack ||= caller(depth)
    call_stack&.find do |line|
      _file_line, name = line.to_s.split(/:in\s+/)
      name = name.to_s.sub(/^[ `]*(.*?)[' ]*$/, '\1')
      next if name.blank?
      next if %w(each map __output __output_impl).include?(name)
      return name.match(/^(block|rescue)\s+in\s+(.*)$/) ? $2 : name
    end
  end

  # Return the indicated method.  If *meth* is something other than a Symbol or
  # a Method then *nil* is returned.
  #
  # @overload get_method(meth, *)
  #   @param [Method] meth
  #   @return [Method]
  #
  # @overload get_method(bind, *)
  #   @param [Binding] bind
  #   @return [Method, nil]
  #
  # @overload get_method(meth, bind, *)
  #   @param [Symbol]  meth
  #   @param [Binding] bind
  #   @return [Method, nil]
  #
  def get_method(*args)
    meth = (args.shift unless args.first.is_a?(Binding))
    return meth if meth.is_a?(Method)
    bind = args.first
    return unless bind.is_a?(Binding)
    meth ||= bind.eval('__method__')
    bind.receiver.method(meth) if bind.receiver.methods.include?(meth)
  end

  # Return a table of a method's parameters and their values given a Binding
  # from that method invocation.
  #
  # @overload get_params(bind, **opt)
  #   @param [Binding]        bind
  #   @param [Hash]           opt
  #
  # @overload get_params(meth, bind, **opt)
  #   @param [Symbol, Method] meth
  #   @param [Binding]        bind
  #   @param [Hash]           opt
  #
  # @option opt [Symbol, Array<Symbol>] :only
  # @option opt [Symbol, Array<Symbol>] :except
  #
  # @return [Hash{Symbol=>*}]
  #
  def get_params(*args)
    opt    = args.extract_options!
    only   = Array.wrap(opt[:only]).presence
    except = Array.wrap(opt[:except]).presence
    meth   = (args.shift unless args.first.is_a?(Binding))
    bind   = (args.shift if args.first.is_a?(Binding))
    if !meth.is_a?(Method) && bind.is_a?(Binding)
      meth = bind.eval('__method__') unless meth.is_a?(Symbol)
      rcvr = bind.receiver
      meth = (rcvr.method(meth) if rcvr.methods.include?(meth))
    end
    prms = meth.is_a?(Method) ? meth.parameters : {}
    prms.flat_map { |type, name|
      next if (type == :block) || name.blank? || except&.include?(name)
      next unless only.nil? || only.include?(name)
      if type == :keyrest
        bind.local_variable_get(name).map(&:itself)
      else
        [[name, bind.local_variable_get(name)]]
      end
    }.compact.to_h
  end

end

__loading_end(__FILE__)