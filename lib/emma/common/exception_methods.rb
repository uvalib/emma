# lib/emma/common/exception_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma::Common::ExceptionMethods

  extend self

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
  # @param [any, nil] this            Default: self.
  #
  # @return [Class]
  #
  def self_class(this = SelfContext)
    this = self if this == SelfContext
    this.is_a?(Class) ? this : this.class
  end

  # Indicate whether *error* is an exception which matches or is derived from
  # one of the exceptions listed in #INTERNAL_EXCEPTION.
  #
  # @param [any, nil] error           Exception
  #
  def internal_exception?(error)
    ancestors = self_class(error).ancestors || []
    ancestors.intersect?(INTERNAL_EXCEPTION)
  end

  # Indicate whether *error* is an exception which is not (derived from) one of
  # the exceptions listed in #INTERNAL_EXCEPTION.
  #
  # @param [any, nil] error           Exception
  #
  # @note Currently unused.
  # :nocov:
  def operational_exception?(error)
    ancestors = self_class(error).ancestors || []
    ancestors.include?(Exception) && !ancestors.intersect?(INTERNAL_EXCEPTION)
  end
  # :nocov:

  # Re-raise an exception which indicates a likely programming error.
  #
  # @param [any, nil] error           Exception
  #
  # @return [nil]
  #
  # === Usage Notes
  # The re-raise will happen only when running on the desktop.
  #
  def re_raise_if_internal_exception(error)
    return unless internal_exception?(error)
    if application_deployed? && try(:request)&.format&.html?
      Log.warn { "CREATING INTERNAL EXCEPTION #{error}" }
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
  # @param [Boolean]     fatal        If *false*, only log.
  #
  # @raise [NotImplementedError]
  #
  def not_implemented(message = nil, meth: nil, fatal: true, log: true, **)
    meth ||= calling_method
    msg    = [self.class, meth, message].compact.join(': ')
    raise NotImplementedError, msg if fatal
    Log.warn(msg)                  if log
  end

  # Raise NotImplementedError to indicate that a base method has been invoked
  # rather than the expected override defined by a subclass or later module.
  #
  # @param [String, nil] message      Additional description.
  # @param [Symbol, nil] meth         Calling method to prepend to message.
  # @param [Hash]        opt          Passed to #not_implemented
  #
  # @raise [NotImplementedError]
  #
  def must_be_overridden(message = nil, meth: nil, **opt)
    meth  ||= calling_method
    message = 'to be overridden %s' % (message || 'by the subclass')
    not_implemented(message, meth: meth, **opt)
  end

  # For use in code which may be provided an implementation by a subclass but
  # can acceptably return *nil* otherwise.
  #
  # This is just informational and neither logs nor raises by default.
  #
  # @param [String, nil] message      Additional description.
  # @param [Symbol, nil] meth         Calling method to prepend to message.
  # @param [Boolean]     fatal
  # @param [Boolean]     log
  #
  # @return [nil]
  #
  def may_be_overridden(message = nil, meth: nil, fatal: false, log: false, **)
    return unless fatal || log
    meth ||= calling_method
    must_be_overridden(message, meth: meth, fatal: fatal, log: log)
  end

  # For use in code which is not defined to have a value or implementation.
  #
  # This is just informational and neither logs nor raises by default.
  #
  # @param [String, nil] message      Additional description.
  # @param [Symbol, nil] meth         Calling method to prepend to message.
  # @param [Boolean]     fatal
  # @param [Boolean]     log
  #
  # @raise [RuntimeError]             If *fatal*.
  #
  # @return [nil]
  #
  def not_applicable(message = nil, meth: nil, fatal: false, log: false, **)
    return unless fatal || log
    meth  ||= calling_method
    message = ['not applicable', message].compact.join(' ')
    message = [self.class, meth, message].compact.join(': ')
    raise RuntimeError, message if fatal
    Log.info(message)           if log
  end

end

__loading_end(__FILE__)
