# config/initializers/mail_observers.rb
#
# frozen_string_literal: true
# warn_indent:           true

unless production_deployment?

  class EmailDeliveryObserver
    def self.delivered_email(message)
      Log.info(message)
    end
  end

  # noinspection RubyResolve
  Rails.configuration.action_mailer.observers = %w[EmailDeliveryObserver]

end

# noinspection RubyResolve
__output "=> Mailer config #{Rails.configuration.action_mailer.smtp_settings.inspect}"
