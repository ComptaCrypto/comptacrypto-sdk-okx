# frozen_string_literal: true

RSpec.describe Comptacrypto::Sdk::Okx::Base64EncodedSignature do
  subject(:encoder_klass) do
    described_class
  end

  describe ".new" do
    subject(:encoder_instance) do
      encoder_klass.new(secret_key:)
    end

    context "when secret key is 'secret-foo'" do
      let(:secret_key) do
        "secret-foo"
      end

      describe "#call" do
        subject(:encoded_value) do
          encoder_instance.call(request_path:, ms_iso8601:)
        end

        let(:ms_iso8601) do
          "2022-02-07T21:37:33.383Z"
        end

        context "without querystring params" do
          let(:request_path) do
            "/orders"
          end

          it "signs the message" do
            expect(encoded_value).to eq "bI6DJV5K+G4laid4txciR/5p/pX4tjf39B5jIc6nFck="
          end
        end

        context "with querystring params" do
          let(:request_path) do
            "/orders?before=2&limit=30"
          end

          it "signs the message" do
            expect(encoded_value).to eq "olT7YgbofkVgIdeD5OxL6VHVfOMXRDHP+EjKCDGoFYU="
          end
        end
      end
    end

    context "when secret key is 'secret-bar'" do
      let(:secret_key) do
        "secret-bar"
      end

      describe "#call" do
        subject(:encoded_value) do
          encoder_instance.call(request_path:, ms_iso8601:)
        end

        let(:ms_iso8601) do
          "2022-02-07T21:37:33.383Z"
        end

        context "without querystring params" do
          let(:request_path) do
            "/orders"
          end

          it "signs the message" do
            expect(encoded_value).to eq "gdct2bwMcqtQpGJTN7h3iGzkSs+nYHvtSV001gvZV34="
          end
        end

        context "with querystring params" do
          let(:request_path) do
            "/orders?before=2&limit=30"
          end

          it "signs the message" do
            expect(encoded_value).to eq "5gRqlGFBITlsVMK7Js2lWvS1z9UIZkJb07dtLlAL2Ig="
          end
        end
      end
    end
  end
end
