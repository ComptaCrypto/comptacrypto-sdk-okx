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

        # @see https://www.okx.com/docs/en/#spot-account_information
        #
        # GET/api/spot/v3/accounts
        #
        def spot_account_information(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/spot/v3/accounts", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot-detail
        #
        # GET/api/spot/v3/fills
        #
        # @option [String] :order_id
        # @option [String] :instrument_id
        # @option [String] :after Pagination of data to return records earlier than the requested ledger_id
        # @option [String] :before Pagination of data to return records newer than the requested ledger_id
        # @option [String] :limit The maximum is 100; the default is 100
        def spot_transaction_detail(ms_iso8601 = remote_ms_iso8601, order_id: nil, instrument_id: nil, after: nil, before: nil, limit: nil)
          private_endpoint(request_path: "/api/spot/v3/fills", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-information
        #
        # GET/api/account/v3/wallet
        def funding_account_information(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/account/v3/wallet", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-all-withdrawal-history
        #
        # GET /api/account/v3/withdrawal/history
        #
        def withdrawal_history(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/account/v3/withdrawal/history", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-all-deposit-history
        #
        # GET/api/account/v3/deposit/history
        #
        def deposit_history(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/account/v3/deposit/history", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#swap-swap---hold_information
        #
        # GET/api/swap/v3/position
        #
        def swap_position(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/swap/v3/position", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#swap-swap---only
        #
        # GET/api/swap/v3/<instrument_id>/position
        #
        # @param instrument_id [String]
        def swap_position_contract(ms_iso8601 = remote_ms_iso8601, instrument_id:)
          request_path = "/api/swap/v3/#{instrument_id}/position"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#swap-swap---singleness
        #
        # GET/api/swap/v3/accounts
        #
        def swap_account(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/swap/v3/accounts", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#swap-swap---query
        #
        # GET/api/swap/v3/accounts/<instrument_id>/ledger
        #
        # @param instrument_id [String]
        # @option [String] :after Pagination of data to return records earlier than the requested ledger_id.
        # @option [String] :before Pagination of data to return records new than the requested ledger_id.
        # @option [String] :limit Number of results per request. The maximum is 100; the default is 100
        # @option [String] :type 1:Open Long, 2:Open Short, 3:Close Long, 4:Close Short, 5:Transfer In，6:Transfer Out,
        # 7:Settled UPL, 8:Clawback, 9:Insurance Fund, 10:Full Liquidation of Long, 11:Full Liquidation of Short,
        # 14: Funding Fee, 15: Manually Add Margin, 16: Manually Reduce Margin, 17: Auto-Margin, 18: Switch Margin Mode,
        # 19: Partial Liquidation of Long, 20 Partial Liquidation of Short, 21 Margin Added with Lowered Leverage, 22: Settled RPL
        def swap_bill_detail(ms_iso8601 = remote_ms_iso8601, instrument_id:, after: nil, before: nil, limit: "100", state: nil)
          request_path = "/api/swap/v3/accounts/#{instrument_id}/ledger"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#swap-swap---list
        #
        # GET/api/swap/v3/orders/<instrument_id>
        #
        # @param instrument_id [String]
        # @param state [String] -2 = Failed, -1 = Canceled, 0 = Open, 1 = Partially Filled, 2 = Fully Filled,
        # 3 = Submitting, 4 = Canceling, 6 = Incomplete (open + partially filled), 7 = Complete (canceled + fully filled)
        # @option [String] :after Pagination of data to return records earlier than the requested order_id.
        # @option [String] :before Pagination of data to return records new than the requested order_id.
        # @option [String] :limit Number of results per request. The maximum is 100; the default is 100
        def swap_order_list(ms_iso8601 = remote_ms_iso8601, instrument_id:, state:, after: nil, before: nil, limit: "100")
          request_path = "/api/swap/v3/orders/#{instrument_id}"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#swap-swap---order_information
        #
        # GET/api/swap/v3/orders/<instrument_id>/<order_id> OR GET/api/swap/v3/orders/<instrument_id>/<client_oid>
        #
        # @param instrument_id [String]
        # Either client_oid or order_id must be present.
        # @option [String] order_id
        # @option [String] client_iod
        def swap_order_detail(ms_iso8601 = remote_ms_iso8601, instrument_id:, client_iod: nil, order_id: nil)
          raise ::ArgumentError if client_iod.nil? && order_id.nil?
          request_path = if client_iod.nil?
            "/api/swap/v3/orders/#{instrument_id}/#{order_id}"
          else
            "/api/swap/v3/orders/#{instrument_id}/#{client_iod}"
          end

          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#swap-swap---futuresdetail
        #
        # GET/api/swap/v3/fills
        #
        # @param instrument_id [String]
        # @option [String] :order_id Complete transaction details for will be returned if the instrument_id is left blank
        # @option [String] :after Pagination of data to return records earlier than the requested trade_id.
        # @option [String] :before Pagination of data to return records newer than the requested trade_id.
        # @option [String] :limit Number of results per request. The maximum is 100; the default is 100
        def swap_transaction_detail(ms_iso8601 = remote_ms_iso8601, instrument_id:, order_id: nil, after:nil, before: nil, limit: "100")
          private_endpoint(request_path: "/api/swap/v3/fills", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#swap-swap---hold_amount
        #
        # @param instrument_id [String]
        def swap_hold_amount(ms_iso8601 = remote_ms_iso8601, instrument_id:)
          request_path = "/api/swap/v3/accounts/#{instrument_id}/holds"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/ #swap-swap---trade_fee
        #
        #  GET /api/swap/v3/trade_fee
        #
        # Choose and enter one parameter between category and instrument_id
        # @option [String] :category Fee Schedule Tier: 1：Tier 1; 2：Tier 2;4：Tier 4
        # @option [String] :instrument_id contract ID，eg：BTC-USD-SWAP
        def swap_trade_fee(ms_iso8601 = remote_ms_iso8601, category: nil, instrument_id: nil)
          raise ::ArgumentError if category.nil? && instrument_id.nil?
          private_endpoint(request_path: "/api/swap/v3/trade_fee", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#swap-swap---algo_list
        #
        # GET /api/swap/v3/order_algo/<instrument_id>
        #
        # @param instrument_id [String]
        # @param order_type [String]
        # status and algo_id are mandatory, select either one
        # @option [String] :status Order status: 1. Pending; 2. 2. Effective; 3. Cancelled;
        # 4. Partially effective; 5. Paused; 6. Order failed [Status 4 and 5 only applies to iceberg and TWAP orders]
        # @option [String] :algo_id Enquiry specific order ID
        # @option [String] :before Request page content after this ID
        # @option [String] :after Request page content before this ID
        # @option [String] :limit The number of results returned by the page. Default and maximum are both 100
        def swap_algo_list(ms_iso8601 = remote_ms_iso8601, instrument_id:, order_type:, status: nil, algo_id: nil, before: nil, after: nil, limit: '100')
          raise ::ArgumentError if status.nil? && algo_id.nil?
          request_path = "/api/swap/v3/order_algo/#{instrument_id}"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#option-option---position
        #
        # GET /api/option/v3/<underlying>/position
        #
        # @param underlying [String]
        # @option [String] instrument_id
        def option_position(ms_iso8601 = remote_ms_iso8601, underlying:, instrument_id: nil)
          request_path = "/api/option/v3/#{underlying}/position"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#option-option---account_underlying
        #
        # GET /api/option/v3/accounts/<underlying>
        #
        # @param underlying [String]
        def option_underlying_account_information(ms_iso8601 = remote_ms_iso8601, underlying:)
          request_path = "/api/option/v3/accounts/#{underlying}"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#option-option---order_information
        #
        # GET /api/option/v3/orders/<underlying>/<order_id OR /api/option/v3/orders/<underlying>/client_oid
        #
        # @param underlying [String]
        # Either client_oid or order_id must be present
        # @option [String] order_id
        # @option [String] client_iod
        def option_order_information(ms_iso8601 = remote_ms_iso8601, underlying:, order_id: nil, client_oid: nil)
          request_path = if client_oid.nil?
            "/api/option/v3/orders/#{underlying}/#{order_id}"
          else
            "/api/option/v3/orders/#{underlying}/#{client_iod}"
          end

          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#option-option---order_list
        #
        # GET /api/option/v3/orders/<underlying>
        #
        # @param underlying [String]
        # @param state [String] -2 = Failed, -1 = Canceled, 0 = Open, 1 = Partially Filled, 2 = Fully Filled, 3 = Submitting,
        # 4 = Canceling, 6 = Incomplete (Open + Partially Filled), 7 = Complete (Canceled + Fully Filled)
        # @option [String] instrument_id
        # @option [String] after Pagination of data to return records earlier than the requested order_id
        # @option [String] before Pagination of data to return records newer than the requested order_id
        # @option [String] limit The maximum is 100; the default is 100
        def option_order_list(ms_iso8601 = remote_ms_iso8601, underlying:, state:, instrument_id: nil, after: nil, before: nil, limit: "100")
          request_path = "/api/option/v3/orders/#{underlying}"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#option-option---fills
        #
        # GET /api/option/v3/fills/<underlying>
        #
        # @param underlying [String]
        # @option [String] order_id
        # @option [String] instrument_id
        # @option [String] after Pagination of data to return records earlier than the requested trade_id
        # @option [String] before Pagination of data to return records newer than the requested trade_id
        # @option [String] limit The maximum is 100; the default is 100
        def option_fill(ms_iso8601 = remote_ms_iso8601, underlying:, order_id: nil, instrument_id: nil, after: nil, before: nil, limit: "100")
          request_path = "/api/option/v3/fills/#{underlying}"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#option-option---ledger
        #
        # GET /api/option/v3/accounts/<underlying>/ledger
        #
        # @param underlying [String]
        # @option [String] after Pagination of data to return records earlier than the requested ledger_id
        # @option [String] before Pagination of data to return records newer than the requested ledger_id
        # @option [String] limit The maximum is 100; the default is 100
        def option_position(ms_iso8601 = remote_ms_iso8601, underlying:, after: nil, before: nil, limit: "100")
          request_path = "/api/option/v3/accounts/#{underlying}/ledger"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#option-option---trade_fee
        #
        # GET /api/option/v3/trade_fee
        #
        # Choose and enter one parameter between category and underlying
        # @option [String] category
        # @option [String] underlying
        def option_position(ms_iso8601 = remote_ms_iso8601, category: nil, underlying: nil)
          raise ::ArgumentError if category.nil? && underlying.nil?
          private_endpoint(request_path: "/api/option/v3/trade_fee", ms_iso8601:)
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
