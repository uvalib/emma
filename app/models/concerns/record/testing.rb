# app/models/concerns/record/testing.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support for "destructive testing".
#
module Record::Testing

  extend ActiveSupport::Concern

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    # noinspection RbsMissingTypeSignature
    if safe_const_get(:DESTRUCTIVE_TESTING)

      include Record::Exceptions

      # =======================================================================
      # :section:
      # =======================================================================

      private

      FAULT_INJECTION   = true
      FORCED_EXCEPTION  = true

      # == Fault injection types

      bit = -1
      # noinspection RubyUnusedLocalVariable
      ALL_FAULTS = [
        BAD_PARAM = 1 << (bit += 1),
      ].sum

      FAULT_METHOD = {
        #upload_file:  BAD_PARAM,
        #db_insert:    BAD_PARAM,
      }.freeze

      # == Forced exception types

      DEFAULT_EXCEPTION = Record::Error

      EXCEPTION_TYPE = {
        Record::Error             => '(simulated) RECORD ERROR',
        Record::NotFound          => '(simulated) RECORD NOT FOUND ERROR',
        Record::StatementInvalid  => '(simulated) RECORD LOOKUP ERROR',
        Record::SubmitError       => '(simulated) WORKFLOW ERROR',
      }.freeze

      EXCEPTION_METHOD = {
        upload_file:  Record::SubmitError,
        #db_insert:    Record::StatementInvalid,
      }.freeze

      # =======================================================================
      # :section:
      # =======================================================================

      protected

      # Injection point for "destructive testing", both forced exceptions and
      # fault injection.
      #
      # @param [Model, Hash, nil] item  Data subject to modification.
      #
      # @return [void]
      #
      def fault!(item)
        meth = calling_method&.to_sym
        inject_exception(meth) or inject_fault!(meth, item)
      end

      # Injection point for "destructive testing" modifications to method
      # parameters.
      #
      # @param [Symbol, nil]      meth  Calling method.
      # @param [Model, Hash, nil] item  Item to be altered.
      #
      # @return [Integer]               Test cases applied.
      # @return [nil]                   If no injection was performed
      #
      def inject_fault!(meth, item)
        return unless FAULT_INJECTION
        return unless (faults = meth ? FAULT_METHOD[meth] : ALL_FAULTS)
        unless item.is_a?(Model) || item.is_a?(Hash)
          Log.warn do
            "#{__method__}: expected Model or Hash; got #{item.inspect}"
          end unless item.nil?
          return
        end

        __debug_banner("#{self.class}.#{meth} FAULT")
        tests = 0

        # == Bad parameter
        if BAD_PARAM & faults
          tests += 1
          item[:bad_param] = 'bad_param_value'
        end

        positive(tests)
      end

      # Injection point for "destructive testing" simulation of exception.
      # If an exception is not specified, the calling method must be included
      # in #EXCEPTION_METHOD.
      #
      # @param [Symbol, nil] meth     Calling method.
      # @param [Class<Record::Error>, Record::Error, String, nil] ex
      # @param [Array]       args     Passed to initializer if *ex* is a class.
      #
      # @return [nil]                 If no exception was generated.
      #
      def inject_exception(meth, ex = nil, *args)
        return unless FORCED_EXCEPTION
        return unless (de = meth ? EXCEPTION_METHOD[meth] : DEFAULT_EXCEPTION)
        # noinspection RubyCaseWithoutElseBlockInspection, RubyNilAnalysis
        case (ex ||= de)
          when Class  then ex = ex.new(*(args.presence || EXCEPTION_TYPE[ex]))
          when String then ex = de.new(ex, *args)
        end
        return unless ex.present?
        __debug_banner("#{self.class}.#{meth} #{ex.class}")
        # noinspection RubyMismatchedArgumentType
        failure(ex)
      end

    else

      protected

      neutralize(:fault!)
      neutralize(:inject_fault!)
      neutralize(:inject_exception)

    end

  end

end

__loading_end(__FILE__)
