# app/models/record/reportable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods relating to error reporting.
#
module Record::Reportable

  extend ActiveSupport::Concern

  include Emma::Json

  include Record
  include Record::Exceptions
  include Record::Updatable::InstanceMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default name for the column that holds error report(s).
  #
  # @type [Symbol]
  #
  REPORT_COLUMN = :report

  # Whether the #REPORT_COLUMN should be persisted as a Hash.
  #
  # @type [Boolean]
  #
  REPORT_HASH = true

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Workflow errors.
  #
  # @param [Boolean, nil] refresh     If *true*, re-fetch from the database.
  #
  # @return [ExecReport]
  #
  def exec_report(refresh = false)
    get_exec_report(refresh)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Fetch the current value of #REPORT_COLUMN for the current record.
  #
  # @param [Boolean, nil] refresh     If *false*, don't re-fetch.
  #
  # @return [ExecReport]
  #
  def get_exec_report(refresh = true)
    if !defined?(@exec_report) || @exec_report.nil?
      @exec_report = ExecReport.new(self, get_report_column)
    elsif refresh
      @exec_report.set(get_report_column)
    else
      @exec_report
    end
  end

  # Update the current value of #REPORT_COLUMN for the current record.
  #
  # @param [ExecReport, Hash, String, Array<String>, Array<FlashPart>, nil] value
  #
  # @raise [ActiveRecord::ReadOnlyRecord]   If the record is not writable.
  #
  # @return [ExecReport]                    New value of `#exec_report`.
  #
  def set_exec_report(value = nil)
    @exec_report ||= ExecReport.new(self)
    # noinspection RubyMismatchedArgumentType
    @exec_report.set(value || ExecError::DEFAULT_ERROR)
    set_report_column(@exec_report.serialize)
    @exec_report
  end

  # Clear the current value of #REPORT_COLUMN for the current record.
  #
  # @return [nil]
  #
  def clear_exec_report(...)
    set_report_column(nil)
    exec_report.clear
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get the contents of the current record's #REPORT_COLUMN.
  #
  # @param [Symbol] col               Default: `#REPORT_COLUMN`.
  #
  # @return [*]
  #
  def get_report_column(*, col: REPORT_COLUMN, **)
    get_field_direct(col)
  end

  # Directly update the contents of the current record's #REPORT_COLUMN.
  #
  # @param [*]           value
  # @param [Symbol, nil] meth         Default: `#calling_method`.
  # @param [Boolean]     fatal        If *true* raise on error.
  # @param [Symbol]      col          Default: `#REPORT_COLUMN`.
  #
  # @raise [RuntimeError]             If updating failed and !fatal.
  #
  # @return [Boolean]
  #
  def set_report_column(value, meth: nil, fatal: false, col: REPORT_COLUMN)
    result = set_field_direct(col, value) and return result
    result = result.nil?
    err = result ? 'record deleted' : "failed to update with #{value.inspect}"
    Log.warn do
      meth ||= calling_method(3)
      "#{meth}: #{err}"
    end
    raise err if fatal
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
