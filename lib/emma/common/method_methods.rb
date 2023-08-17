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
  #--
  # === Variations
  #++
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
    # noinspection RubyMismatchedArgumentType
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
  # @param [Symbol, Method, *] meth
  # @param [Binding, *]        bind
  #
  # @return [Method, nil]
  #
  #--
  # === Variations
  #++
  #
  # @overload get_method(meth, bind, *)
  #   @param [Symbol]  meth
  #   @param [Binding] bind
  #   @return [Method, nil]
  #
  # @overload get_method(bind, *)
  #   @param [Binding] bind
  #   @return [Method, nil]
  #
  # @overload get_method(meth, *)
  #   @param [Method] meth
  #   @return [Method]
  #
  def get_method(meth, bind, *)
    return meth if meth.is_a?(Method)
    meth, bind = [nil, meth] if meth.is_a?(Binding)
    return unless bind.is_a?(Binding)
    meth = bind.eval('__method__') unless meth.is_a?(Symbol)
    rcvr = bind.receiver
    rcvr.method(meth) if rcvr.methods.include?(meth)
  end

  # Return a table of a method's parameters and their values given a Binding
  # from that method invocation.
  #
  # @param [Symbol, Method, *]     meth
  # @param [Binding, *]            bind
  # @param [Symbol, Array<Symbol>] only
  # @param [Symbol, Array<Symbol>] except
  #
  # @return [Hash{Symbol=>Any}]
  #
  #--
  # === Variations
  #++
  #
  # @overload get_params(meth, bind, only: [], except: [], **)
  #   @param [Symbol, Method]        meth
  #   @param [Binding]               bind
  #   @param [Symbol, Array<Symbol>] only
  #   @param [Symbol, Array<Symbol>] except
  #   @return [Hash{Symbol=>Any}]
  #
  # @overload get_params(bind, only: [], except: [], **)
  #   @param [Binding]               bind
  #   @param [Symbol, Array<Symbol>] only
  #   @param [Symbol, Array<Symbol>] except
  #   @return [Hash{Symbol=>Any}]
  #
  def get_params(meth, bind, *, only: [], except: [], **)
    meth, bind = [nil, meth] if meth.is_a?(Binding)
    meth   = get_method(meth, bind) or return {}
    only   = Array.wrap(only).presence
    except = Array.wrap(except).presence
    meth.parameters.flat_map { |type, name|
      next if (type == :block) || name.blank? || %i[* **].include?(name)
      next if only && !only.include?(name) || except&.include?(name)
      next unless bind.local_variable_defined?(name)
      next unless (value = bind.local_variable_get(name))
      if type == :keyrest
        value.map(&:itself)
      else
        [[name, value]]
      end
    }.compact.to_h
  end

end

__loading_end(__FILE__)
