# frozen_string_literal: true

RSpec.describe Comptacrypto::Sdk::Okx::ClientV5 do
  subject(:client_v5) do
    described_class.new
  end

  describe "#withdrawal_history", :vcr do
    let(:payload) do
      {
        "code" => "0",
        "data" => [],
        "msg" => ""
      }
    end

    it "returns the withdrawal history" do
      expect(client_v5.withdrawal_history.body).to eq payload
    end
  end
end
