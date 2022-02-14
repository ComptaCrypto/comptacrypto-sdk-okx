# frozen_string_literal: true

RSpec.describe Comptacrypto::Sdk::Okx::ClientV3 do
  subject(:client_v3) do
    described_class.new
  end

  describe "#time", :vcr do
    let(:payload) do
      {
        "iso" => "2022-02-12T17:45:46.804Z",
        "epoch" => "1644687946.804"
      }
    end

    it "returns the server time in milliseconds" do
      expect(client_v3.time.body).to eq payload
    end
  end

  describe "#trading_pairs", :vcr do
    let(:first_trading_pair) do
      {
        "base_currency" => "BTC",
        "instrument_id" => "BTC-USDT",
        "min_size" => "0.00001",
        "quote_currency" => "USDT",
        "size_increment" => "0.00000001",
        "category" => "1",
        "tick_size" => "0.1"
      }
    end

    it "returns the first trading pair" do
      expect(client_v3.trading_pairs.body.fetch(0)).to eq first_trading_pair
    end
  end
end
