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
    IndexError,       # includes KeyError, StopIteration, UnpermittedParameters
    LocalJumpError,
    NameError,        # includes NoMethodError
    NoMemoryError,
    RangeError,       # includes FloatDomainError
    RegexpError,
    ScriptError,      # includes LoadError, SyntaxError, NotImplementedError
    SecurityError,
    SignalException,  # includes Interrupt
    SystemCallError,  # includes Errno::E2BIG, Errno::EACCES, etc.
    SystemExit,
    SystemStackError,
    ThreadError,
    TypeError,
    ZeroDivisionError,
  ].freeze

  private

  # This allows `self_class(nil)` to return NilClass.
  module SelfContext; end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Report on the class associated with "self".
  #
  # @param [*] this                   Default: self.
  #
  # @return [Class]
  #
  def self_class(this = SelfContext)
    this = self if this == SelfContext
    # noinspection RubyMismatchedReturnType
    this.is_a?(Class) ? this : this.class
  end

  # Indicate whether *error* is an exception which matches or is derived from
  # one of the exceptions listed in #INTERNAL_EXCEPTION.
  #
  # @param [Exception, Any, nil] error
  #
  def internal_exception?(error)
    ancestors = self_class(error).ancestors || []
    ancestors.intersect?(INTERNAL_EXCEPTION)
  end

  # Indicate whether *error* is an exception which is not (derived from) one of
  # the exceptions listed in #INTERNAL_EXCEPTION.
  #
  # @param [Exception, Any, nil] error
  #
  def operational_exception?(error)
    ancestors = self_class(error).ancestors || []
    ancestors.include?(Exception) && !ancestors.intersect?(INTERNAL_EXCEPTION)
  end

  # Re-raise an exception which indicates a likely programming error.
  #
  # @param [Exception, *] error
  #
  # @return [nil]
  #
  # == Usage Notes
  # The re-raise will happen only when running on the desktop.
  #
  def re_raise_if_internal_exception(error)
    return unless internal_exception?(error)
    if request.format.html? && application_deployed?
      Log.warn { "EATING INTERNAL EXCEPTION #{error}" }
    else
      Log.warn { "RE-RAISING INTERNAL EXCEPTION #{error}" }
      raise error
    end
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
