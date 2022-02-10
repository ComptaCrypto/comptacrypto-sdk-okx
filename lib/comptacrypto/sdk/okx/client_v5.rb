# frozen_string_literal: true

require "faraday"
require "time"
require "uri"

require_relative "base64_encoded_signature"

module Comptacrypto
  module Sdk
    module Okx
      # @see https://www.okx.com/docs-v5/en/
      class ClientV5
        attr_reader :api_key, :secret_key, :passphrase, :conn

        BASE_URL   = "https://www.okx.com"
        USER_AGENT = "ComptaCrypto/OKX"

        def initialize(api_key: ENV["OKX_API_KEY"], secret_key: ENV["OKX_SECRET_KEY"], passphrase: ENV["OKX_PASSPHRASE"], base_url: ENV["OKX_BASE_V5_URL"])
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

        # @see https://www.okx.com/docs-v5/en/#rest-api-public-data-get-system-time
        def time
          public_endpoint(request_path: "/api/v5/public/time")
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-public-data-get-instruments
        #
        # GET /api/v5/public/instruments
        #
        # @param instType [String]
        # @option [String] :uly
        # @option [String] :instId
        def trading_pairs(instType:, uly: nil, instId: nil)
          request_path = URI("/api/v5/public/instruments")
          params = { instType:, uly:, instId: }.compact
          request_path.query = URI.encode_www_form(params)

          public_endpoint(request_path: request_path.to_s)
        end

        # Private Endpoints

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-deposit-history
        #
        # GET /api/v5/asset/deposit-history
        #
        # @option [String] ccy
        # @option [String] txId
        # @option [String] state 0: waiting for confirmation, 1: deposit credited, 2: deposit successful
        # @option [String] after Pagination of data to return records earlier than the requested ts, Unix timestamp format in milliseconds
        # @option [String] before Pagination of data to return records newer than the requested ts, Unix timestamp format in milliseconds
        # @option [String] limit The maximum is 100; The default is 100
        def deposit_history(ms_iso8601 = remote_ms_iso8601, ccy: nil, txId: nil, state: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/asset/deposit-history")
          params = { ccy:, txId:, state:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end
        
        # Get withdrawal history
        #
        # @note Retrieve the withdrawal records according to the currency, withdrawal
        #   status, and time range in reverse chronological order. The 100 most
        #   recent records are returned by default.
        #
        #   GET /api/v5/asset/withdrawal-history
        #
        # @param ccy    [String] Currency, e.g. "`BTC`"
        # @param tx_id  [String] Hash record of the deposit
        # @param state  [String] Status of withdrawal (from "`-3`" to "`5`")
        # @param after  [String] Pagination of data to return records earlier than the requested ts, Unix timestamp format in milliseconds, e.g. "`1597026383085`"
        # @param before [String] Pagination of data to return records newer than the requested ts, Unix timestamp format in milliseconds, e.g. "`1597026383085`"
        # @param limit  [String] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-withdrawal-history
        def withdrawal_history(ms_iso8601 = remote_ms_iso8601, ccy: nil, tx_id: nil, state: nil, after: nil, before: nil, limit: nil)
          request_path = URI("/api/v5/asset/withdrawal-history")
          query_params = { ccy:, tx_id:, state:, after:, before:, limit: }.compact
          request_path.query = ::URI.encode_www_form(query_params) if query_params.any?

          private_endpoint(request_path:, ms_iso8601:)
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
          ms_ts_str = time.body.fetch("data").fetch(0).fetch("ts")
          ::Time.strptime(ms_ts_str, "%Q").utc.iso8601(3)
        end

        def sign(request_path:, ms_iso8601:)
          Base64EncodedSignature.new(secret_key:).call(request_path:, ms_iso8601:)
        end
      end
    end
  end
end
