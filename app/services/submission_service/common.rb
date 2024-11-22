# app/services/submission_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Service implementation methods.
#
module SubmissionService::Common

  include ApiService::Common

  include SubmissionService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @return [SubmissionService::Request]
  attr_accessor :request

  # @return [SubmissionService::Response, nil]
  attr_accessor :result

  # @return [Float, nil]
  attr_accessor :start_time

  # @return [Float, nil]
  attr_accessor :end_time

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def request    = @request
  def result     = @result
  def start_time = @start_time
  def end_time   = @end_time

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the request sequence has begun.
  #
  # @note Currently used only by unused methods.
  # :nocov:
  def started?
    !start_time.nil?
  end
  # :nocov:

  # Indicate whether the request sequence has finished.
  #
  def finished?
    !end_time.nil?
  end

  # How long the total request sequence took.
  #
  # @param [Integer] precision        Digits after the decimal point.
  #
  # @return [Float] Wall clock time in seconds; zero if not finished.
  #
  def duration(t_end = nil, t_start = nil, precision: 2)
    return 0.0 if t_start.nil? && !finished?
    t_start ||= start_time
    t_end   ||= end_time || timestamp
    # noinspection RubyMismatchedArgumentType
    (t_end - t_start).round(precision).to_f
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.include(SubmissionService::Definition)
    base.extend(self)
  end

end

__loading_end(__FILE__)
