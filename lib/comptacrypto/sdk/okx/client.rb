# frozen_string_literal: true

require "base64"
require "faraday"
require "openssl"
require "time"

module Comptacrypto
  module Sdk
    module Okx
      class Client
        attr_reader :api_key, :secret_key, :passphrase, :conn

        BASE_URL   = "https://www.okex.com"
        USER_AGENT = "ComptaCrypto/OKX"

        def initialize(api_key: ENV["OKX_API_KEY"], secret_key: ENV["OKX_SECRET_KEY"], passphrase: ENV["OKX_PASSPHRASE"], base_url: ENV["OKX_BASE_URL"])
          @api_key    = String(api_key).encode("UTF-8")
          @secret_key = String(secret_key).encode("UTF-8")
          @passphrase = String(passphrase).encode("UTF-8")
          @base_url   = base_url || BASE_URL

          @conn = ::Faraday.new(@base_url, headers: { "User-Agent" => USER_AGENT }) do |f|
            f.response :json     # decode response bodies as JSON
            f.adapter  :net_http # adds the adapter to the connection, defaults to `Faraday.default_adapter`
          end
        end

        # Public Endpoints

        # @see https://www.okx.com/docs/en/#getting-server-time
        def time
          public_endpoint(request_path: "/api/general/v3/time")
        end

        # Private Endpoints

        # @see https://www.okx.com/docs/en/#account-all-withdrawal-history
        def withdrawal_history(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/account/v3/withdrawal/history", ms_iso8601:)
        end

        private

        def public_endpoint(request_path:)
          conn.get(request_path)
        end

        def private_endpoint(request_path:, ms_iso8601:)
          conn.get(request_path) do |req|
            req.headers["OK-ACCESS-KEY"]        = api_key
            req.headers["OK-ACCESS-SIGN"]       = sign(request_path:, ms_iso8601:)
            req.headers["OK-ACCESS-TIMESTAMP"]  = ms_iso8601
            req.headers["OK-ACCESS-PASSPHRASE"] = passphrase
          end
        end

        def remote_ms_iso8601
          ms_ts_str = time.body.fetch("epoch").delete(".")
          ::Time.strptime(ms_ts_str, "%Q").utc.iso8601(3)
        end

        # Signing Messages
        #
        # @note Given the JS implementation example from the official doc,
        #
        #     var hash = CryptoJS.HmacSHA256("message", "secret");
        #     // => { words: [ -1956689808, 697680217, -1940439631, -501717335, -1205480281, -1798215209, 101319520, 1469462027 ], sigBytes: 32 }
        #
        #     var hashInBase64 = CryptoJS.enc.Base64.stringify(hash);
        #     // => 'i19IcCmVwVmMVz2x4hhmqbgl1KeU0WnXBgoDYFeWNgs='
        #
        #   should match this Ruby implementation:
        #
        #     hash = OpenSSL::HMAC.digest("SHA256", "secret", "message")
        #     # => "\x8B_Hp)\x95\xC1Y\x8CW=\xB1\xE2\x18f\xA9\xB8%\xD4\xA7\x94\xD1i\xD7\x06\n\x03`W\x966\v"
        #
        #     Base64.strict_encode64(hash)
        #     # => "i19IcCmVwVmMVz2x4hhmqbgl1KeU0WnXBgoDYFeWNgs="
        #
        # @see https://www.okx.com/docs/en/#signing-messages
        # @see https://www.okx.com/docs-v5/en/#rest-api-authentication-signature
        def sign(request_path:, ms_iso8601:)
          message = "#{ms_iso8601}GET#{request_path}"
          hash = ::OpenSSL::HMAC.digest("SHA256", secret_key, message)
          ::Base64.strict_encode64(hash)
        end
      end
    end
  end
end
