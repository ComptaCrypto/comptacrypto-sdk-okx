# frozen_string_literal: true

require "faraday"
require "openssl"

module Comptacrypto
  module Sdk
    module Okx
      class Client
        attr_reader :api_key, :secret_key, :passphrase, :conn

        USER_AGENT = "ComptaCrypto/OKX"

        def initialize(api_key: ENV["OKX_API_KEY"], secret_key: ENV["OKX_SECRET_KEY"], passphrase: ENV["OKX_PASSPHRASE"])
          @api_key    = api_key
          @secret_key = secret_key
          @passphrase = passphrase

          @conn = ::Faraday.new(ENV.fetch("OKX_BASE_URL"), headers: { "User-Agent" => USER_AGENT }) do |f|
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
        def withdrawal_history(timestamp = time.body.fetch("epoch"))
          private_endpoint(request_path: "/api/account/v3/withdrawal/history", timestamp:)
        end

        private

        def public_endpoint(request_path:)
          conn.get(request_path)
        end

        def private_endpoint(request_path:, timestamp:)
          conn.get(request_path) do |req|
            req.headers["OK-ACCESS-KEY"]        = api_key
            req.headers["OK-ACCESS-SIGN"]       = sign(request_path:, timestamp:)
            req.headers["OK-ACCESS-TIMESTAMP"]  = timestamp
            req.headers["OK-ACCESS-PASSPHRASE"] = passphrase
          end
        end

        def sign(request_path:, timestamp:)
          message = "#{timestamp}GET#{request_path}"
          ::OpenSSL::HMAC.base64digest("SHA256", secret_key, message)
        end
      end
    end
  end
end
