# lib/emma/common/method_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma::Common::MethodMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  # @type [Regexp]
  BLOCK_RESCUE_RE = /^(block|rescue)\s+(\(\d+ levels?\)\s+)?in\s+(.*)$/.freeze

  # Return the name of the calling method.
  #
  # NOTE: Callers expect only the method name and not something of the form
  #   "class#method" (as produced by Ruby 3.4+).
  #
  # @param [Array<String>, Integer, nil] call_stack
  #
  # @return [Symbol, nil]
  #
  #--
  # === Variations
  #++
  #
  # @overload calling_method()
  #   Using *call_stack* defaulting to `#caller(2)`.
  #   @return [Symbol]
  #
  # @overload calling_method(call_stack)
  #   @param [Array<String>] call_stack
  #   @return [Symbol]
  #
  # @overload calling_method(depth)
  #   @param [Integer] depth              Call stack depth (default: 2)
  #   @return [Symbol]
  #
  def calling_method(call_stack = nil)
    depth = 2
    if call_stack.is_a?(Integer)
      depth = call_stack if call_stack > depth
      call_stack = nil
    end
    call_stack ||= caller(depth)
    call_stack&.find { |line|
      name = line.to_s.sub(/^.*:in [`'](.*?)'$/, '\1')
      next if name.blank? || %w[each map __output __output_impl].include?(name)
      name = name.split('#').last
      break name.sub(BLOCK_RESCUE_RE, '\3')
    }&.to_sym
  end

  # Return the indicated method.  If *meth* is something other than a Symbol or
  # a Method then *nil* is returned.
  #
  # @param [any, nil] meth            Symbol, Method
  # @param [any, nil] bind            Binding
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
  # @param [any, nil]              meth   Symbol, Method
  # @param [any, nil]              bind   Binding
  # @param [Symbol, Array<Symbol>] only
  # @param [Symbol, Array<Symbol>] except
  #
  # @return [Hash{Symbol=>any}]
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
  #   @return [Hash{Symbol=>any}]
  #
  # @overload get_params(bind, only: [], except: [], **)
  #   @param [Binding]               bind
  #   @param [Symbol, Array<Symbol>] only
  #   @param [Symbol, Array<Symbol>] except
  #   @return [Hash{Symbol=>any}]
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
