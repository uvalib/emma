# app/jobs/mailer_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# This is a replacement for ActionMailer::MailDeliveryJob which persists the
# job results to the "good_jobs" table, allowing it to show up in the GoodJob
# dashboard.
#
class MailerJob < ApplicationJob

  queue_as do
    mailer_class&.deliver_later_queue_name || default_queue_name
  end

  rescue_from StandardError, with: :handle_exception_with_mailer_class

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  # Generate mail via *mail_method* and deliver it.
  #
  # @param [String, Class] mailer
  # @param [any]           mail_method
  # @param [any]           delivery_method
  # @param [any]           args             ruby2_keywords :args, :params
  # @param [Hash]          opt
  #
  # @return [void]
  #
  #--
  # noinspection RubyArgCount
  #++
  def perform(mailer, mail_method, delivery_method, *args, **opt)
    no_raise = nil
    record   = JobResult.create(active_job_id: job_id)
    super
    opt      = args.extract_options!.dup.merge(opt)
    args     = opt[:args]
    kwargs   = opt[:kwargs]
    params   = opt[:params]

    mailer   = mailer.constantize  if mailer.is_a?(String)
    mailer   = mailer.with(params) if params
    if kwargs
      message = mailer.public_send(mail_method, *args, **kwargs)
    else
      message = mailer.public_send(mail_method, *args)
    end
    result   = message.send(delivery_method)

    record.update(output: result)

  rescue => error
    record&.update(error: error)
    raise error unless no_raise
    __output "JOB ERROR: #{error.full_message}"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # "Deserialize" the mailer class name by hand in case another argument
  # (like a Global ID reference) raised DeserializationError.
  #
  # @return [Class, nil]
  #
  def mailer_class
    mailer = Array(@serialized_arguments).first || Array(arguments).first
    mailer&.constantize
  end

  # Invoke ActionMailer rescue handler if possible.
  #
  # @param [Exception] exception
  #
  # @return [void]
  #
  def handle_exception_with_mailer_class(exception)
    mailer = mailer_class
    mailer ? mailer.handle_exception(exception) : raise(exception)
  end

end

__loading_end(__FILE__)
