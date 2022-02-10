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
          query_params = { instType:, uly:, instId: }.compact
          request_path.query = URI.encode_www_form(query_params)

          public_endpoint(request_path: request_path.to_s)
        end

        # Private Endpoints

        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-order-details
        #
        # GET /api/v5/trade/order
        #
        # @param instId [String]
        # Either ordId or clOrdId is required, if both are passed, ordId will be the main one
        # @option [String] ordId
        # @option [String] clOrdId

        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-order-list
        #
        # GET /api/v5/trade/orders-pending
        #
        # @option [String] instType SPOT, MARGIN, SWAP, FUTURES, OPTION
        # @option [String] uly
        # @option [String] instId
        # @option [String] ordType : market: Market order, limit: Limit order, post_only: Post-only order,
        # fok: Fill-or-kill order, ioc: Immediate-or-cancel order, Optimal_limit_ioc :Market order with immediate-or-cancel order
        # @option [String] state : live, partially_filled
        # @option [String] after
        # @option [String] before
        # @option [String] limit
        def trade_get_order_list(ms_iso8601 = remote_ms_iso8601, instType: nil, uly: nil, instId: nil, ordType: nil, state: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/trade/orders-pending")
          query_params = { instType:, uly:, instId:, ordType:, state:, after:, before:, limit: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-order-history-last-7-days
        #
        # @note last 7 days
        #
        # GET /api/v5/trade/orders-history
        #
        # @param instType [String] SPOT, MARGIN, SWAP, FUTURES, OPTION
        # @option [String] uly
        # @option [String] instId
        # @option [String] ordType : market: Market order, limit: Limit order, post_only: Post-only order,
        # fok: Fill-or-kill order, ioc: Immediate-or-cancel order, Optimal_limit_ioc :Market order with immediate-or-cancel order
        # @option [String] state : canceled, filled
        # @option [String] category : twap, adl, full_liquidation, partial_liquidation, delivery, ddh
        # @option [String] after Pagination of data to return records earlier than the requested ordId
        # @option [String] before Pagination of data to return records newer than the requested ordId
        # @option [String] limit Number of results per request. The maximum is 100; The default is 100
        def trade_get_order_history_last_7_days(ms_iso8601 = remote_ms_iso8601, instType:, uly: nil, instId: nil, ordType: nil, state: nil, category: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/trade/orders-history")
          query_params = { instType:, uly:, instId:, ordType:, state:, category:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(query_params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-order-history-last-3-months
        #
        # @note last 3 months
        #
        # GET /api/v5/trade/orders-history-archive
        #
        # @param instType [String] SPOT, MARGIN, SWAP, FUTURES, OPTION
        # @option [String] uly
        # @option [String] instId
        # @option [String] ordType : market: Market order, limit: Limit order, post_only: Post-only order,
        # fok: Fill-or-kill order, ioc: Immediate-or-cancel order, Optimal_limit_ioc :Market order with immediate-or-cancel order
        # @option [String] state : canceled, filled
        # @option [String] category : twap, adl, full_liquidation, partial_liquidation, delivery, ddh
        # @option [String] after : Pagination of data to return records earlier than the requested ordId
        # @option [String] before : Pagination of data to return records newer than the requested ordId
        # @option [String] limit : Number of results per request. The maximum is 100; The default is 100
        def trade_get_order_history_last_3_months(ms_iso8601 = remote_ms_iso8601, instType:, uly: nil, instId: nil, ordType: nil, state: nil, category: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/trade/orders-history-archive")
          query_params = { instType:, uly:, instId:, ordType:, state:, category:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(query_params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-transaction-details-last-3-days
        #
        # @note last 3 days
        #
        # GET /api/v5/trade/fills
        #
        # @option [String] instType : SPOT, MARGIN, SWAP, FUTURES, OPTION
        # @option [String] uly
        # @option [String] instId
        # @option [String] ordId
        # @option [String] after : Pagination of data to return records earlier than the requested billId
        # @option [String] before : Pagination of data to return records newer than the requested billId
        # @option [String] limit : Number of results per request. The maximum is 100; The default is 100
        def trade_get_transaction_details_last_3_days(ms_iso8601 = remote_ms_iso8601, instType: nil, uly: nil, instId: nil, ordId: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/trade/fills")
          query_params = { instType:, uly:, instId:, ordId:, after:, before:, limit: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-transaction-details-last-3-months
        #
        # @note last 3 months
        #
        # GET /api/v5/trade/fills-history
        #
        # @param instType [String] SPOT, MARGIN, SWAP, FUTURES, OPTION
        # @option [String] uly
        # @option [String] instId
        # @option [String] ordId
        # @option [String] after : Pagination of data to return records earlier than the requested billId
        # @option [String] before : Pagination of data to return records newer than the requested billId
        # @option [String] limit : Number of results per request. The maximum is 100; The default is 100
        def trade_get_transaction_details_last_3_months(ms_iso8601 = remote_ms_iso8601, instType:, uly: nil, instId: nil, ordId: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/trade/fills-history")
          query_params = { instType:, uly:, instId:, ordId:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(query_params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-algo-order-list
        #
        # GET /api/v5/trade/orders-algo-pending
        #
        # @param ordType [String] conditional: One-way stop order, oco: One-cancels-the-other order, trigger: Trigger order, move_order_stop: Trailing order, iceberg: Iceberg order, twap: TWAP order
        # @option [String] algoId
        # @option [String] instType
        # @option [String] instId
        # @option [String] after : Pagination of data to return records earlier than the requested algoId
        # @option [String] before : Pagination of data to return records newer than the requested algoId
        # @option [String] limit : Number of results per request. The maximum is 100; The default is 100
        def trade_get_algo_order_list(ms_iso8601 = remote_ms_iso8601, ordType:, algoId: nil, instType: nil, instId: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/trade/orders-algo-pending")
          query_params = { ordType:, algoId:, instType:, instId:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(query_params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-algo-order-history
        #
        # DO NOT WORK response_body={"msg"=>"Invalid Sign", "code"=>"50113"}
        # GET /api/v5/trade/orders-algo-history
        #
        # @param ordType [String] conditional: One-way stop order, oco: One-cancels-the-other order, trigger: Trigger order, move_order_stop: Trailing order, iceberg: Iceberg order, twap: TWAP order
        # Either state or algoId is requied
        # @option [String] state effective, canceled, order_failed
        # @option [String] algoId
        # @option [String] instType SPOT, MARGIN, SWAP, FUTURES, OPTION
        # @option [String] instId
        # @option [String] after : Pagination of data to return records earlier than the requested algoId
        # @option [String] before : Pagination of data to return records newer than the requested algoId
        # @option [String] limit : Number of results per request. The maximum is 100; The default is 100
        # def trade_get_algo_order_history(ms_iso8601 = remote_ms_iso8601, ordType:, state: nil, algoId: nil, instType: nil, instId: nil, after: nil, before: nil, limit: "100")
        #   raise ::ArgumentError if state.nil? && algoId.nil?

        #   request_path = URI("/api/v5/trade/orders-algo-history")
        #   query_params = { ordType:, state:, algoId:, instType:, instId:, after:, before:, limit: }.compact
        #   request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

        #   private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        # end

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-currencies
        #
        # GET /api/v5/asset/currencies
        #
        def funding_get_currencies(ms_iso8601 = remote_ms_iso8601)
          public_endpoint(request_path: URI("/api/v5/asset/currencies"), ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-balance
        #
        # GET /api/v5/asset/balances
        #
        # @option [String] ccy
        def funding_get_balance(ms_iso8601 = remote_ms_iso8601, ccy: nil)
          request_path = URI("/api/v5/asset/balances")
          query_params = { ccy: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-account-asset-valuation
        #
        # GET /api/v5/asset/asset-valuation
        #
        # @option [String] ccy
        def funding_get_account_asset_valuation(ms_iso8601 = remote_ms_iso8601, ccy: nil)
          request_path = URI("/api/v5/asset/asset-valuation")
          query_params = { ccy: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-funds-transfer-state
        #
        # GET /api/v5/asset/transfer-state
        #
        # @option [String] type 0: transfer within account, 1: master account to sub-account, 2: sub-account to master account. The default is 0
        def funding_get_funds_transfer_state(ms_iso8601 = remote_ms_iso8601, type: nil)
          request_path = URI("/api/v5/asset/transfer-state")
          query_params = { type: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-asset-bills-details
        #
        # GET /api/v5/asset/bills
        #
        # @option [String] ccy
        # @option [String] type
        # @option [String] after : Pagination of data to return records earlier than the requested ts, Unix timestamp format in milliseconds
        # @option [String] before :	Pagination of data to return records newer than the requested ts, Unix timestamp format in milliseconds
        # @option [String] limit : Number of results per request. The maximum is 100; The default is 100
        def funding_asset_bills_details(ms_iso8601 = remote_ms_iso8601, ccy: nil, type: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/asset/bills")
          query_params = { ccy:, type:, after:, before:, limit: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-lightning-deposits
        #
        # GET /api/v5/asset/deposit-lightning
        #
        # @param ccy [String]
        # @param amt [String]
        # @option [String] to : 6:funding account, 1:spot account. If empty, will default to funding account.
        def funding_lightning_deposits(ms_iso8601 = remote_ms_iso8601, ccy:, amt:, to: nil)
          request_path = URI("/api/v5/asset/deposit-lightning")
          query_params = { ccy:, amt:, to: }.compact
          request_path.query = URI.encode_www_form(query_params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-deposit-address
        #
        # GET /api/v5/asset/deposit-address
        #
        # @param ccy [String]
        def funding_get_deposit_address(ms_iso8601 = remote_ms_iso8601, ccy:)
          request_path = URI("/api/v5/asset/deposit-address")
          query_params = { ccy: }.compact
          request_path.query = URI.encode_www_form(query_params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

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
        def funding_get_deposit_history(ms_iso8601 = remote_ms_iso8601, ccy: nil, txId: nil, state: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/asset/deposit-history")
          query_params = { ccy:, txId:, state:, after:, before:, limit: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

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
        def funding_get_withdrawal_history(ms_iso8601 = remote_ms_iso8601, ccy: nil, tx_id: nil, state: nil, after: nil, before: nil, limit: nil)
          request_path = URI("/api/v5/asset/withdrawal-history")
          query_params = { ccy:, tx_id:, state:, after:, before:, limit: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-saving-balance
        #
        # GET /api/v5/asset/saving-balance
        #
        # @option [String] ccy
        def funding_get_saving_balance(ms_iso8601 = remote_ms_iso8601, ccy: nil)
          request_path = URI("/api/v5/asset/saving-balance")
          query_params = { ccy: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-lending-history
        #
        # GET /api/v5/asset/lending-history

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-public-borrow-info-public
        #
        # GET /api/v5/asset/lending-rate-summary

        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-public-borrow-history-public
        #
        # GET /api/v5/asset/lending-rate-history

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-balance
        #
        # GET /api/v5/account/balance
        #
        # @option [String] ccy
        def account_get_balance(ms_iso8601 = remote_ms_iso8601, ccy: nil)
          request_path = URI("/api/v5/account/balance")
          query_params = { ccy: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-positions
        #
        # GET /api/v5/account/positions
        #
        # @option [String] instType
        # @option [String] instId
        # @option [String] posId
        def account_get_positions(ms_iso8601 = remote_ms_iso8601, instType: nil, instId: nil, posId: nil)
          request_path = URI("/api/v5/account/positions")
          query_params = { instType:, instId:, posId: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-account-and-position-risk
        #
        # GET /api/v5/account/account-position-risk

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-bills-details-last-7-days
        #
        # GET /api/v5/account/bills
        #
        # @option [String] instType SPOT, MARGIN, SWAP, FUTURES, OPTION
        # @option [String] ccy
        # @option [String] mgnMode isolated, cross
        # @option [String] ctType linear, inverse. Only applicable to FUTURES/SWAP
        # @option [String] type 1: Transfer 2: Trade 3: Delivery 4: Auto token conversion 5: Liquidation 6: Margin transfer
        # 7: Interest deduction 8: Funding fee 9: ADL 10: Clawback 11: System token conversion 12: Strategy transfer 13: ddh
        # @option [String] subType 1: Buy 2: Sell 3: Open long 4: Open short 5: Close long 6: Close short 9: Interest deduction for Market loans
        # 11: Transfer in 12: Transfer out 14: Interest deduction for VIP loans 160: Manual margin increase 161: Manual margin decrease 162: Auto margin increase
        # 110: Auto buy 111: Auto sell 118: System token conversion transfer in 119: System token conversion transfer out 100: Partial liquidation close long
        # 101: Partial liquidation close short 102: Partial liquidation buy 103: Partial liquidation sell 104: Liquidation long 105: Liquidation short
        # 106: Liquidation buy 107: Liquidation sell 110: Liquidation transfer in 111: Liquidation transfer out 125: ADL close long 126: ADL close short
        # 127: ADL buy 128: ADL sell 131: ddh buy 132: ddh sell 170: Exercised 171: Counterparty exercised 172: Expired OTM 112: Delivery long 113: Delivery short
        # 117: Delivery/Exercise clawback 173: Funding fee expense 174: Funding fee income 200:System transfer in 201: Manually transfer in 202: System transfer out 203: Manually transfer out
        # @option [String] after : Pagination of data to return records earlier than the requested bill ID.
        # @option [String] before : Pagination of data to return records newer than the requested bill ID.
        # @option [String] limit : Number of results per request. The maximum is 100; The default is 100
        def account_get_bills_details_last_7_days(ms_iso8601 = remote_ms_iso8601, instType: nil, ccy: nil, mgnMode: nil, ctType: nil, type: nil, subType: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/account/bills")
          query_params = { instType:, ccy:, mgnMode:, ctType:, type:, subType:, after:, before:, limit: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-bills-details-last-3-months
        #
        # GET /api/v5/account/bills-archive
        #
        # @option [String] instType SPOT, MARGIN, SWAP, FUTURES, OPTION
        # @option [String] ccy
        # @option [String] mgnMode isolated, cross
        # @option [String] ctType linear, inverse. Only applicable to FUTURES/SWAP
        # @option [String] type 1: Transfer 2: Trade 3: Delivery 4: Auto token conversion 5: Liquidation 6: Margin transfer
        # 7: Interest deduction 8: Funding fee 9: ADL 10: Clawback 11: System token conversion 12: Strategy transfer 13: ddh
        # @option [String] subType 1: Buy 2: Sell 3: Open long 4: Open short 5: Close long 6: Close short 9: Interest deduction for Market loans
        # 11: Transfer in 12: Transfer out 14: Interest deduction for VIP loans 160: Manual margin increase 161: Manual margin decrease 162: Auto margin increase
        # 110: Auto buy 111: Auto sell 118: System token conversion transfer in 119: System token conversion transfer out 100: Partial liquidation close long
        # 101: Partial liquidation close short 102: Partial liquidation buy 103: Partial liquidation sell 104: Liquidation long 105: Liquidation short
        # 106: Liquidation buy 107: Liquidation sell 110: Liquidation transfer in 111: Liquidation transfer out 125: ADL close long 126: ADL close short
        # 127: ADL buy 128: ADL sell 131: ddh buy 132: ddh sell 170: Exercised 171: Counterparty exercised 172: Expired OTM 112: Delivery long 113: Delivery short
        # 117: Delivery/Exercise clawback 173: Funding fee expense 174: Funding fee income 200:System transfer in 201: Manually transfer in 202: System transfer out 203: Manually transfer out
        # @option [String] after : Pagination of data to return records earlier than the requested bill ID.
        # @option [String] before : Pagination of data to return records newer than the requested bill ID.
        # @option [String] limit : Number of results per request. The maximum is 100; The default is 100
        def account_get_bills_details_last_3_months(ms_iso8601 = remote_ms_iso8601, instType: nil, ccy: nil, mgnMode: nil, ctType: nil, type: nil, subType: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/account/bills-archive")
          query_params = { instType:, ccy:, mgnMode:, ctType:, type:, subType:, after:, before:, limit: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-account-configuration
        #
        # GET /api/v5/account/config

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-maximum-buy-sell-amount-or-open-amount
        #
        # GET /api/v5/account/max-size

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-maximum-available-tradable-amount
        #
        # GET /api/v5/account/max-avail-size

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-leverage
        #
        # GET /api/v5/account/leverage-info

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-the-maximum-loan-of-instrument
        #
        # GET /api/v5/account/max-loan

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-fee-rates
        #
        # GET /api/v5/account/trade-fee

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-interest-accrued-data
        #
        # GET /api/v5/account/interest-accrued

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-interest-rate
        #
        # GET /api/v5/account/interest-rate

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-maximum-withdrawals
        #
        # GET /api/v5/account/max-withdrawal

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-account-risk-state
        #
        # GET /api/v5/account/risk-state

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-borrow-and-repay-history-for-vip-loans
        #
        # GET /api/v5/account/borrow-repay-history

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-borrow-interest-and-limit
        #
        # GET /api/v5/account/interest-limits

        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-greeks
        #
        # GET /api/v5/account/greeks

        # @see https://www.okx.com/docs-v5/en/#rest-api-subaccount-view-sub-account-list
        #
        # @note Applies to master accounts only
        # GET /api/v5/users/subaccount/list
        #
        # @option [String] enable Sub-account status，true: Normal ; false: Frozen
        # @option [String] subAcct Sub-account name
        # @option [String] after If you query the data prior to the requested creation time ID, the value will be a Unix timestamp in millisecond format.
        # @option [String] before If you query the data after the requested creation time ID, the value will be a Unix timestamp in millisecond format.
        # @option [String] limit The maximum is 100; The default is 100
        def subaccount_view_sub_account_list(ms_iso8601 = remote_ms_iso8601, enable: nil, subAcct: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/v5/users/subaccount/list")
          query_params = { enable:, subAcct:, after:, before:, limit: }.compact
          request_path.query = ::URI.encode_www_form(**query_params) if query_params.any?

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-subaccount-query-the-apikey-of-a-sub-account
        #
        # GET /api/v5/users/subaccount/apikey

        # @see https://www.okx.com/docs-v5/en/#rest-api-subaccount-get-sub-account-balance
        #
        # GET /api/v5/account/subaccount/balances
        #
        # @param subAcct [String] Sub-account name
        def subaccount_get_sub_account_balance(ms_iso8601 = remote_ms_iso8601, subAcct:)
          request_path = URI("/api/v5/account/subaccount/balances")
          query_params = { subAcct: }.compact
          request_path.query = URI.encode_www_form(query_params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-subaccount-history-of-sub-account-transfer
        #
        # GET /api/v5/asset/subaccount/bills

        # @see https://www.okx.com/docs-v5/en/#rest-api-subaccount-get-custody-trading-sub-account-list
        #
        # GET /api/v5/users/entrust-subaccount-list

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-tickers
        #
        # GET /api/v5/market/tickers
        #
        # @param instType [String] SPOT SWAP FUTURES OPTION
        # @option [String] uly Underlying, e.g. BTC-USD. Only applicable to FUTURES/SWAP/OPTION
        def market_data_get_tickers(ms_iso8601 = remote_ms_iso8601, instType:, uly: nil)
          request_path = URI("/api/v5/market/tickers")
          query_params = { instType:, uly: }.compact
          request_path.query = URI.encode_www_form(query_params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-ticker
        #
        # GET /api/v5/market/ticker
        #
        # @param instId [String] Instrument ID, e.g. BTC-USD-SWAP
        def market_data_get_ticker(ms_iso8601 = remote_ms_iso8601, instId:)
          request_path = URI("/api/v5/market/ticker")
          query_params = { instId: }.compact
          request_path.query = URI.encode_www_form(query_params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-index-tickers
        #
        # GET /api/v5/market/index-tickers

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-order-book
        #
        # GET /api/v5/market/books

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-candlesticks
        #
        # GET /api/v5/market/candles

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-candlesticks-history
        #
        # GET /api/v5/market/history-candles

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-index-candlesticks
        #
        # GET /api/v5/market/index-candles

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-mark-price-candlesticks
        #
        # GET /api/v5/market/mark-price-candles

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-trades
        #
        # GET /api/v5/market/trades

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-24h-total-volume
        #
        # GET /api/v5/market/platform-24-volume

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-oracle
        #
        # GET /api/v5/market/open-oracle

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-exchange-rate
        #
        # GET /api/v5/market/exchange-rate

        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-index-components
        #
        # GET /api/v5/market/index-components

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
