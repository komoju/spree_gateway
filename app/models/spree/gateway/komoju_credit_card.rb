module Spree
  class Gateway::KomojuCreditCard < Gateway
    preference :api_key, :string

    def provider_class
      ActiveMerchant::Billing::KomojuGateway
    end

    def options
      super.merge(login: preferred_api_key, test: preferred_test_mode)
    end

    def purchase(money, payment, options)
      # We need to change shipping, tax, subtotal and discount from cents to dollar for Komoju gateway.
      # Because, Komoju gateway supports JPY currency only.
      #
      # Spree changes price from dollar to cents. Almost payment gateway supports cents only.
      # See. https://github.com/spree/spree/blob/master/core/app/models/spree/payment/gateway_options.rb
      options = change_options_to_dollar(options) if options[:currency] == "JPY"
      super(money - options[:tax], payment.to_active_merchant, options)
    end

    def credit(money, creditcard, response_code, gateway_options)
      provider.refund(money, response_code, {})
    end

    private

    def change_options_to_dollar(options)
      %i(shipping tax subtotal discount).each { |key| options[key] = options[key] / 100.0 }
      options
    end
  end
end
