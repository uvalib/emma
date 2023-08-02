if !production_deployment?
  Rails.application.configure do
    class EmailDeliveryObserver
      def self.delivered_email(message)
        Log.info(message)
      end
    end
    config.action_mailer.observers = %w[EmailDeliveryObserver]
  end
end