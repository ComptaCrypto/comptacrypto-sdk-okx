# frozen_string_literal: true

RSpec.describe Comptacrypto::Sdk::Okx::Client do
  subject(:client) do
    described_class.new
  end

  describe "#time", :vcr do
    let(:payload) do
      {
        "iso" => "2022-02-08T07:57:58.088Z",
        "epoch" => "1644307078.088"
      }
    end

    it "returns the server time in milliseconds" do
      expect(client.time.body).to eq payload
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
      expect(client.trading_pairs.body.fetch(0)).to eq first_trading_pair
    end
  end

  describe "#withdrawal_history", :vcr do
    # @todo When the authentication will be corrected,
    #   we will be able to generate a VCR cassette and refresh the payload.
    let(:payload) do
      [
        {
          "amount" => 0.094,
          "withdrawal_id" => "4703879",
          "fee" => "0.01000000eth",
          "txid" => "0x62477bac6509a04512819bb1455e923a60dea5966c7caeaa0b24eb8fb0432b85",
          "currency" => "ETH",
          "chain" => "ETH-TRC20",
          "from" => "13426335357",
          "to" => "0xA41446125D0B5b6785f6898c9D67874D763A1519",
          "timestamp" => "2018-04-22T23:09:45.000Z",
          "status" => "2"
        },
        {
          "amount" => 0.01,
          "withdrawal_id" => "4703879",
          "fee" => "0.00000000btc",
          "txid" => "",
          "currency" => "BTC",
          "chain" => "BTC-TRC20",
          "from" => "13426335357",
          "to" => "13426335357",
          "timestamp" => "2018-05-17T02:43:08.000Z",
          "status" => "2"
        }
      ]
    end

    xit "returns the withdrawal history" do
      expect(client.withdrawal_history.body).to eq payload
    end
  end
end
