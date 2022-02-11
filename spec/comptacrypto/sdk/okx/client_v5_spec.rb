# frozen_string_literal: true

RSpec.describe Comptacrypto::Sdk::Okx::ClientV5 do
  subject(:client_v5) do
    described_class.new
  end

  describe "#trade_get_order_list", :vcr do
    let(:payload) do
      {
        "code" => "0",
        "data" => [],
        "msg" => ""
      }
    end

    it "returns the trade order list" do
      expect(client_v5.trade_get_order_list.body).to eq payload
    end
  end

  describe "#funding_get_withdrawal_history", :vcr do
    let(:payload) do
      {
        "code" => "0",
        "data" => [],
        "msg" => ""
      }
    end

    it "returns the withdrawal history" do
      expect(client_v5.funding_get_withdrawal_history.body).to eq payload
    end
  end
end
