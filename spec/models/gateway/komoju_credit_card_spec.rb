require "spec_helper"

describe Spree::Gateway::KomojuCreditCard do
  let(:gateway) { described_class.create!(name: "KomojuGateway") }

  describe "#provider_class" do
    it "returns komoju gateway" do
      expect(subject.provider_class).to eq ::ActiveMerchant::Billing::KomojuGateway
    end
  end

  describe "#options" do
    it "returns options" do
      api_key = double("api_key")
      allow(subject).to receive(:preferred_api_key) { api_key }
      allow(subject).to receive(:preferred_test_mode) { true }

      expect(subject.options).to eq ({ api_key: nil, test: true, server: "test", test_mode: true, login: api_key })
    end
  end

  describe "#purchase" do
    let(:money) { 1000.0 }
    let(:payment) { double("payment", to_active_merchant: {}) }
    let(:options) { { login: "api_key", shipping: 100.0, tax: 200.0, subtotal: 800.0, discount: 100.0,
                      currency: currency } }

    before do
      allow_any_instance_of(Spree::Gateway::KomojuCreditCard).to receive(:options) { options }
    end

    context "with currency is USD" do
      let(:currency) { "USD" }

      it "calls ActiveMerchant::Billing::KomojuGateway#purchase with original options" do
        response = double(ActiveMerchant::Billing::Response)
        expect_any_instance_of(ActiveMerchant::Billing::KomojuGateway).to receive(:purchase).with(800.0, {}, options) { response }

        gateway.purchase(money, payment, options)
      end
    end

    context "with currency is JPY" do
      let(:currency) { "JPY" }

      it "calls ActiveMerchant::Billing::KomojuGateway#purchase with options converted from cents to dollars" do
        response = double(ActiveMerchant::Billing::Response)
        options_converted_to_dollars = { login: "api_key", shipping: 1.0, tax: 2.0, subtotal: 8.0, discount: 1.0,
                                         currency: currency }
        expect_any_instance_of(ActiveMerchant::Billing::KomojuGateway).to receive(:purchase).with(998.0, {}, options_converted_to_dollars) { response }

        gateway.purchase(money, payment, options)
      end
    end
  end

  describe "#credit" do
    it "calls provider#refund" do
      api_key = double("api_key")
      money = double(Money)
      credit_card = double(Spree::CreditCard)
      response_code = "external_payment_id"

      allow(gateway).to receive(:preferred_api_key) { api_key }
      expect_any_instance_of(ActiveMerchant::Billing::KomojuGateway).to receive(:refund).with(money, response_code, {})

      gateway.credit(money, credit_card, response_code, {})
    end
  end
end
