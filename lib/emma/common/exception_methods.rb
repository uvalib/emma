# lib/emma/common/exception_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma::Common::ExceptionMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Exceptions which are more likely to indicate unexpected exceptions (i.e.,
  # programming problems) and not operational exceptions due to external API
  # failures.
  #
  # @type [Array<Class>] Sub-classes of Exception.
  #
  INTERNAL_EXCEPTION = [
    ArgumentError,
    FrozenError,
    IndexError,
    LocalJumpError,
    NameError,
    NoMemoryError,
    NotImplementedError,
    RangeError,
    RegexpError,
    ScriptError,
    SecurityError,
    SignalException,
    SystemCallError,
    SystemStackError,
    ThreadError,
    TypeError,
    ZeroDivisionError,
  ].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether *error* is an exception which matches or is derived from
  # one of the exceptions listed in #INTERNAL_EXCEPTION.
  #
  # @param [Exception, Any, nil] error
  #
  def internal_exception?(error)
    # noinspection RubyNilAnalysis
    ancestors = (error.is_a?(Class) ? error : error.class).ancestors
    ancestors.size > (ancestors - INTERNAL_EXCEPTION).size
  end

  # Indicate whether *error* is an exception which is not (derived from) one of
  # the exceptions listed in #INTERNAL_EXCEPTION.
  #
  # @param [Exception, Any, nil] error
  #
  def operational_exception?(error)
    # noinspection RubyNilAnalysis
    a = (error.is_a?(Class) ? error : error.class).ancestors
    a.include?(Exception) && (a.size == (a - INTERNAL_EXCEPTION).size)
  end

  # Re-raise an exception which indicates a likely programming error.
  #
  # @param [Exception, Any, nil] error
  #
  # == Usage Notes
  # The re-raise will happen only when running on the desktop.
  #
  def re_raise_if_internal_exception(error)
    return unless internal_exception?(error)
    Log.warn { "RE-RAISING INTERNAL EXCEPTION #{error}" }
    raise error unless request.format.html?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Raise NotImplementedError.
  #
  # @param [String, nil] message      Additional description.
  # @param [Symbol, nil] meth         Calling method to prepend to message.
  #
  # @raise [NotImplementedError]
  #
  def not_implemented(message = nil, meth: nil, **)
    meth ||= calling_method&.to_sym
    raise NotImplementedError, [self.class, meth, message].compact.join(': ')
  end

end

__loading_end(__FILE__)
