# frozen_string_literal: true

require "faraday"
require "time"
require "uri"

require_relative "base64_encoded_signature"

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

        # @see https://www.okx.com/docs/en/#spot-currency
        def trading_pairs
          public_endpoint(request_path: "/api/spot/v3/instruments")
        end

        # Private Endpoints

        # @see https://www.okx.com/docs/en/#spot-account_information
        #
        # GET /api/spot/v3/accounts
        #
        def spot_account_information(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/spot/v3/accounts", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot-singleness
        #
        # GET /api/spot/v3/accounts/<currency>
        #
        # @param :currency [String] Token symbol, e.g. 'BTC'
        def spot_currency(ms_iso8601 = remote_ms_iso8601, currency:)
          request_path = "/api/spot/v3/accounts/#{currency}"

          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot-query
        #
        # GET /api/spot/v3/accounts/<currency>/ledger
        #
        # @param currency [String] : e.g. 'BTC'
        # @option [String] :type 1.Deposit 2.Withdraw 7.Buy 8.Sell 18.From futures 19.To futures 20.To Sub-account,
        # 21.From Sub-account 22.Transaction Fee Rebate 25.OTC purchase 26.OTC Sell 29.To funding 30.From funding 31.To C2C,
        # 32.From C2C 33.To Margin 34.From Margin 35.Tokens Borrowed 36.Token Repaid 37.Market Maker Reward 39.Transfer-in Fee
        # 40.Transfer-out Fee 41.Spot Fee Paid with Loyalty Points 42.Loyalty Point Purchase 43.Loyalty Point Transfer
        # 44.Market Maker Bonus 46.From Spot 47.To Spot 48.To ETT 49.From ETT 50.To Mining 51.From Mining 52.Referral Program 53.Incentive Tokens
        # 54.Reversal 55.From Savings 56.To Savings 57.From Swap 58.To Swap 59.Repay Candy 60.Hedge Fee 61.To Hedge Account 62.From Hedge Account
        # 63.Margin Interest Paid with Loyalty Points 64.From Mining 65.To Mining 66.To Option Account 67.From Option Account
        # @option [String] :after Pagination of data to return records earlier than the requested ledger_id.
        # @option [String] :before Pagination of data to return records new than the requested ledger_id.
        # @option [String] :limit Number of results per request. The maximum is 100; the default is 100
        def spot_bill_detail(ms_iso8601 = remote_ms_iso8601, currency:, type: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/spot/v3/accounts/#{currency}/ledger")
          params = { type:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot-list
        #
        # GET /api/spot/v3/orders
        #
        # @param instrument_id [String]
        # @param state [String] -2 = Failed, -1 = Canceled, 0 = Open, 1 = Partially Filled, 2 = Fully Filled,
        # 3 = Submitting, 4 = Canceling, 6 = Incomplete (open + partially filled), 7 = Complete (canceled + fully filled)
        # @option after [String] Pagination of data to return records earlier than the requested order_id
        # @option before [String] Pagination of data to return records newer than the requested order_id
        # @option limit [String] The maximum is 100; the default is 100
        def spot_order_list(ms_iso8601 = remote_ms_iso8601, instrument_id:, state:, after: nil, before: nil, limit: "100")
          request_path = URI("/api/spot/v3/orders")
          params = { instrument_id:, state:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot-orders_pending
        #
        # GET /api/spot/v3/orders_pending
        #
        # @param instrument_id [String]
        # @option after [String] Pagination of data to return records earlier than the requested order_id
        # @option before [String] Pagination of data to return records newer than the requested order_id
        # @option limit [String] The maximum is 100; the default is 100
        def spot_order_pending(ms_iso8601 = remote_ms_iso8601, instrument_id:, after: nil, before: nil, limit: "100")
          request_path = URI("/api/spot/v3/orders_pending")
          params = { instrument_id:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot-order_information
        #
        # GET /api/spot/v3/orders/<order_id> OR GET /api/spot/v3/orders/<client_oid>
        #
        # @param instrument_id [String]
        # Either client_oid or order_id must be present.
        # @option [String] order_id
        # @option [String] client_iod
        def spot_order_detail(ms_iso8601 = remote_ms_iso8601, instrument_id:, client_iod: nil, order_id: nil)
          raise ::ArgumentError if client_iod.nil? && order_id.nil?
          raise ::ArgumentError if !client_iod.nil? && !order_id.nil?

          request_path = if client_iod.nil?
                           URI("/api/spot/v3/orders/#{order_id}")
                         else
                           URI("/api/spot/v3/orders/#{client_iod}")
                         end

          params = { instrument_id: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot-trade_fee
        #
        #  GET /api/spot/v3/trade_fee
        #
        # Choose and enter one parameter between category and instrument_id
        # @option [String] :category Fee Schedule Tier: 1：Tier 1; 2：Tier 2;4：Tier 4
        # @option [String] :instrument_id contract ID，eg：BTC-USD-SWAP
        def spot_trade_fee(ms_iso8601 = remote_ms_iso8601, category: nil, instrument_id: nil)
          raise ::ArgumentError if !category.nil? && !instrument_id.nil?

          request_path = URI("/api/spot/v3/trade_fee")
          params = { instrument_id:, category: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot-detail
        #
        # GET /api/spot/v3/fills
        #
        # @option [String] :order_id
        # @option [String] :instrument_id
        # @option [String] :after Pagination of data to return records earlier than the requested ledger_id
        # @option [String] :before Pagination of data to return records newer than the requested ledger_id
        # @option [String] :limit The maximum is 100; the default is 100
        def spot_transaction_detail(ms_iso8601 = remote_ms_iso8601, order_id: nil, instrument_id: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/spot/v3/fills")
          params = { order_id:, instrument_id:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot-algo_list
        #
        # GET /api/spot/v3/algo
        #
        # @param instrument_id [String]
        # @param order_type [String]
        # @option [String] :status Order status: 1. Pending; 2. 2. Effective; 3. Cancelled; 4. Partially effective; 5. Paused; 6. Order failed
        # @option [String] :algo_id Enquiry specific order ID
        # @option [String] :before Request page content after this ID
        # @option [String] :after Request page content before this ID
        # @option [String] :limit Default and maximum are both 100
        def spot_algo_list(ms_iso8601 = remote_ms_iso8601, instrument_id:, order_type:, status: nil, algo_id: nil, before: nil, after: nil, limit: "100")
          raise ::ArgumentError if status.nil? && algo_id.nil?

          request_path = URI("/api/swap/v3/order_algo")
          params = { instrument_id:, order_type:, status:, algo_id:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-information
        #
        # GET/api/account/v3/wallet
        def funding_account_information(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/account/v3/wallet", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-sub-account
        #
        # GET /api/account/v3/sub-account
        #
        # @param sub_account [String]: sub account name
        def funding_sub_account(ms_iso8601 = remote_ms_iso8601, sub_account:)
          request_path = URI("/api/account/v3/sub-account")
          params = { "sub-account": sub_account }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-asset-valuation
        #
        # GET /api/account/v3/asset-valuation
        #
        # @option [String] account_type: 0.Total account assets, 1.spot, 3.futures, 5.margin, 6.Funding Account, 9.swap,
        # 12：option, 14.mining account, 15: USDT-margined futures account, 16: USDT-margined perpetual swap account. Query total assets by default
        # @option [String] valuation_currency: "BTC USD CNY JPY KRW RUB" The default unit is BTC
        def funding_asset_valuation(ms_iso8601 = remote_ms_iso8601, account_type: nil, valuation_currency: nil)
          request_path = URI("/api/account/v3/asset-valuation")
          params = { account_type:, valuation_currency: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-singleness
        #
        # GET /api/account/v3/wallet/<currency>
        #
        # @option [String] currency: Token symbol, e.g. 'BTC
        def funding_currency(ms_iso8601 = remote_ms_iso8601, currency: nil)
          request_path = "/api/account/v3/wallet/#{currency}"

          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-transfer-state
        #
        # GET /api/account/v3/transfer/state
        #
        # @param transfer_id [String]
        def funding_transfer_state(ms_iso8601 = remote_ms_iso8601, transfer_id:)
          request_path = URI("/api/account/v3/transfer/state")
          params = { transfer_id: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-all-withdrawal-history
        #
        # GET /api/account/v3/withdrawal/history
        #
        def withdrawal_history(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/account/v3/withdrawal/history", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-Single-withdrawal-history
        #
        # GET /api/account/v3/withdrawal/history/<currency>
        #
        # @param currency [String]
        def withdrawal_history_currency(ms_iso8601 = remote_ms_iso8601, currency:)
          request_path = "/api/account/v3/withdrawal/history/#{currency}"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-query
        #
        # GET /api/account/v3/ledger
        #
        # @option [String] currency : e.g. 'BTC'
        # @option [String] type : 1:deposit, 2:withdrawal, 13:cancel withdrawal, 18: into futures account, 19: out of futures account, 20:into sub account,
        # 21:out of sub account, 28: claim, 29: into ETT account, 30: out of ETT account, 31: into C2C account, 32:out of C2C account, 33: into margin account,
        # 34: out of margin account, 37: into spot account, 38: out of spot account, 41: Service fees settlement, 42: Loyalty points purchase,
        # 43: Loyalty points transfer, 44: Cancel transfer of loyalty points, 47: System Reverse, 48: Get from activity, 49: Send by activity,
        # 50: Subscription allotment, 51: Subscription cost, 52: Send by red packet 53: Receive from red packet, 54: Back from red packet, 55: To: swap account,
        # 56: From: swap account, 57: To Savings Account, 58: From Savings Account, 59: From Hedging Account, 60: To Hedging Account, 61: exchange
        # 62:From: Options Account, 63:To: Options Account, 66: From Mining/Staking Account, 67: To Mining/Staking Account,
        # 68: Pass benefit redemption, 69: Pass benefit delivery, 70:From Loans Account, 71:To Loans Account
        # @option [String] :after Pagination of data to return records earlier than the requested ledger_id.
        # @option [String] :before Pagination of data to return records new than the requested ledger_id.
        # @option [String] :limit Number of results per request. The maximum is 100; the default is 100
        def funding_bill_detail(ms_iso8601 = remote_ms_iso8601, currency: nil, type: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/account/v3/ledger")
          params = { currency:, type:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-deposit-address
        #
        # GET /api/account/v3/deposit/address
        #
        # @param currency [String]
        def deposit_address(ms_iso8601 = remote_ms_iso8601, currency:)
          request_path = URI("/api/account/v3/deposit/address")
          params = { currency: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-all-deposit-history
        #
        # GET/api/account/v3/deposit/history
        #
        def deposit_history(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/account/v3/deposit/history", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-single-deposit-history
        #
        # GET /api/account/v3/deposit/history/<currency>
        #
        # @param currency [String]
        # @option [String] :after Pagination of data to return records earlier than the requested deposit_id
        # @option [String] :before Pagination of data to return records newer than the requested deposit_id
        # @option [String] :limit The maximum is 100; the default is 100
        def deposit_history_currency(ms_iso8601 = remote_ms_iso8601, currency:, after: nil, before: nil, limit: "100")
          request_path = URI("/api/account/v3/deposit/history/#{currency}")
          params = { after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-currencies
        #
        # GET /api/account/v3/currencies
        #
        def get_currency(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/account/v3/currencies", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-uid
        #
        # GET /api/account/v3/uid
        #
        def get_user_id(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/account/v3/uid", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#account-charge
        #
        # GET /api/account/v3/withdrawal/fee
        #
        # @option [String] :currency : e.g. 'BTC'
        def withdrawal_fee(ms_iso8601 = remote_ms_iso8601, currency: nil)
          request_path = URI("/api/account/v3/withdrawal/fee")
          params = { currency: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
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
        def swap_bill_detail(ms_iso8601 = remote_ms_iso8601, instrument_id:, type: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/swap/v3/accounts/#{instrument_id}/ledger")
          params = { type:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
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
          request_path = URI("/api/swap/v3/orders/#{instrument_id}")
          params = { state:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
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
          raise ::ArgumentError if !client_iod.nil? && !order_id.nil?

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
        def swap_transaction_detail(ms_iso8601 = remote_ms_iso8601, instrument_id:, order_id: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/swap/v3/fills")
          params = { instrument_id:, order_id:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#swap-swap---hold_amount
        #
        # @param instrument_id [String]
        def swap_hold_amount(ms_iso8601 = remote_ms_iso8601, instrument_id:)
          request_path = "/api/swap/v3/accounts/#{instrument_id}/holds"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#swap-swap---trade_fee
        #
        #  GET /api/swap/v3/trade_fee
        #
        # Choose and enter one parameter between category and instrument_id
        # @option [String] :category Fee Schedule Tier: 1：Tier 1; 2：Tier 2;4：Tier 4
        # @option [String] :instrument_id contract ID，eg：BTC-USD-SWAP
        def swap_trade_fee(ms_iso8601 = remote_ms_iso8601, category: nil, instrument_id: nil)
          raise ::ArgumentError if category.nil? && instrument_id.nil?

          request_path = URI("/api/swap/v3/trade_fee")
          params = { instrument_id:, category: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
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
        def swap_algo_list(ms_iso8601 = remote_ms_iso8601, instrument_id:, order_type:, status: nil, algo_id: nil, before: nil, after: nil, limit: "100")
          raise ::ArgumentError if status.nil? && algo_id.nil?

          request_path = URI("/api/swap/v3/order_algo/#{instrument_id}")
          params = { order_type:, status:, algo_id:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#option-option---position
        #
        # GET /api/option/v3/<underlying>/position
        #
        # @param underlying [String]
        # @option [String] instrument_id
        def option_position(ms_iso8601 = remote_ms_iso8601, underlying:, instrument_id: nil)
          request_path = URI("/api/option/v3/#{underlying}/position")
          params = { instrument_id: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
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
        # GET /api/option/v3/orders/<underlying>/<order_id> OR /api/option/v3/orders/<underlying>/client_oid>
        #
        # @param underlying [String]
        # Either client_oid or order_id must be present
        # @option [String] order_id
        # @option [String] client_iod
        def option_order_information(ms_iso8601 = remote_ms_iso8601, underlying:, order_id: nil, client_oid: nil)
          raise ::ArgumentError if client_iod.nil? && order_id.nil?
          raise ::ArgumentError if !client_iod.nil? && !order_id.nil?

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
          request_path = URI("/api/option/v3/orders/#{underlying}")
          params = { state:, instrument_id:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
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
          request_path = URI("/api/option/v3/fills/#{underlying}")
          params = { order_id:, instrument_id:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#option-option---ledger
        #
        # GET /api/option/v3/accounts/<underlying>/ledger
        #
        # @param underlying [String]
        # @option [String] after Pagination of data to return records earlier than the requested ledger_id
        # @option [String] before Pagination of data to return records newer than the requested ledger_id
        # @option [String] limit The maximum is 100; the default is 100
        def option_bill_detail(ms_iso8601 = remote_ms_iso8601, underlying:, after: nil, before: nil, limit: "100")
          request_path = URI("/api/option/v3/accounts/#{underlying}/ledger")
          params = { after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#option-option---trade_fee
        #
        # GET /api/option/v3/trade_fee
        #
        # Choose and enter one parameter between category and underlying
        # @option [String] category
        # @option [String] underlying
        def option_trade_fee(ms_iso8601 = remote_ms_iso8601, category: nil, underlying: nil)
          raise ::ArgumentError if !category.nil? && !underlying.nil?

          request_path = URI("/api/option/v3/trade_fee")
          params = { category:, underlying: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#futures-hold_information
        #
        # GET /api/futures/v3/position
        #
        def future_position(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/futures/v3/position", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#futures-singleness
        #
        # GET /api/futures/v3/accounts
        #
        def future_account(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/futures/v3/accounts", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#futures-list
        #
        # GET /api/futures/v3/orders/<instrument_id>
        #
        # @param instrument_id [String]
        # @param state [String] -2 = Failed, -1 = Canceled, 0 = Open, 1 = Partially Filled, 2 = Fully Filled, 3 = Submitting,
        # 4 = Canceling, 6 = Incomplete (open + partially filled), 7 = Complete (canceled + fully filled)
        # @option [String] after Pagination of data to return records earlier than the requested order_id
        # @option [String] before Pagination of data to return records new than the requested order_id
        # @option [String] limit The maximum is 100; the default is 100
        def future_order_list(ms_iso8601 = remote_ms_iso8601, instrument_id:, state:, after: nil, before: nil, limit: "100")
          request_path = URI("/api/futures/v3/orders/#{instrument_id}")
          params = { state:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#futures-order_information
        #
        # GET /api/futures/v3/orders/<instrument_id>/<order_id> OR /api/futures/v3/orders/<instrument_id>/<client_oid>
        #
        # @param instrument_id [String]
        # Either client_oid or order_id must be present
        # @option [String] order_id
        # @option [String] client_iod
        def future_order_detail(ms_iso8601 = remote_ms_iso8601, instrument_id:, order_id: nil, client_oid: nil)
          raise ::ArgumentError if client_iod.nil? && order_id.nil?
          raise ::ArgumentError if !client_iod.nil? && !order_id.nil?

          request_path = if client_oid.nil?
                           "/api/futures/v3/orders/#{instrument_id}/#{order_id}"
                         else
                           "/api/futures/v3/orders/#{instrument_id}/#{client_iod}"
                         end

          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#futures-futuresdetail
        #
        # GET /api/futures/v3/fills
        #
        # @param instrument_id [String]
        # @param order_id [String]
        # @option [String] after Pagination of data to return records earlier than the requested trade_id
        # @option [String] before Pagination of data to return records new than the requested trade_id
        # @option [String] limit The maximum is 100; the default is 100
        def future_transaction_detail(ms_iso8601 = remote_ms_iso8601, instrument_id:, order_id:, after: nil, before: nil, limit: "100")
          request_path = URI("/api/futures/v3/fills")
          params = { instrument_id:, order_id:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#futures-trade_fee
        #
        # GET /api/futures/v3/trade_fee
        #
        # Choose and enter one parameter between category and underlying
        # @option [String] category
        # @option [String] underlying
        def future_trade_fee(ms_iso8601 = remote_ms_iso8601, category: nil, underlying: nil)
          raise ::ArgumentError if !category.nil? && !underlying.nil?

          request_path = URI("/api/futures/v3/trade_fee")
          params = { category:, underlying: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#futures-hold_amount
        #
        # GET /api/futures/v3/accounts/<instrument_id>/holds
        #
        # @param instrument_id [String]
        def future_hold_amount(ms_iso8601 = remote_ms_iso8601, instrument_id:)
          request_path = "/api/futures/v3/accounts/#{instrument_id}/holds"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot_leverage-account_information
        #
        # GET /api/margin/v3/accounts
        #
        def margin_account(ms_iso8601 = remote_ms_iso8601)
          private_endpoint(request_path: "/api/margin/v3/accounts", ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot_leverage-singleness
        #
        # GET /api/margin/v3/accounts/<instrument_id>
        #
        # @param instrument_id [String]
        def margin_account_currency(ms_iso8601 = remote_ms_iso8601, instrument_id:)
          request_path = "/api/margin/v3/accounts/#{instrument_id}"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot_leverage-query
        #
        # GET /api/margin/v3/accounts/<instrument_id>/ledger
        #
        # @param instrument_id [String]
        # @option [String] after Pagination of data to return records earlier than the requested ledger_id
        # @option [String] before Pagination of data to return records newer than the requested ledger_id
        # @option [String] limit The maximum is 100; the default is 100
        # @option [String] type 3.Tokens Borrowed, 4.Tokers Repaid, 5.Interest Accrued, 7.Buy, 8.Sell, 9.From Funding, 10.From C2C,
        # 12.From Spot, 14.To Funding, 15.To C2C, 16.To Spot, 19.Auto Interest Payment, 24.Liquidation Fees, 59.Repay Candy, 61.To Margin, 62.From Margin
        def margin_bill_detail(ms_iso8601 = remote_ms_iso8601, instrument_id:, after: nil, before: nil, limit: "100", type: nil)
          request_path = URI("/api/margin/v3/accounts/#{instrument_id}/ledger")
          params = { after:, before:, limit:, type: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot_leverage-record
        #
        # GET /api/margin/v3/accounts/borrowed
        #
        # @param status [String] 0: outstanding, 1: repaid. Default: 0
        # @option [String] after Pagination of data to return records earlier than the requested borrow_id
        # @option [String] before Pagination of data to return records newer than the requested borrow_id
        # @option [String] limit The maximum is 100; the default is 100
        def margin_loan_history(ms_iso8601 = remote_ms_iso8601, status:, after: nil, before: nil, limit: "100")
          request_path = URI("/api/margin/v3/accounts/borrowed")
          params = { status:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot_leverage-list
        #
        # GET /api/margin/v3/orders
        #
        # @param instrument_id [String]
        # @param after [String] Pagination of data to return records earlier than the requested order_id
        # @param before [String] Pagination of data to return records newer than the requested order_id
        # @param limit [String] The maximum is 100; the default is 100
        # @param state [String] -2 = Failed, -1 = Canceled, 0 = Open, 1 = Partially Filled, 2 = Fully Filled,
        # 3 = Submitting, 4 = Canceling, 6 = Incomplete (open + partially filled), 7 = Complete (canceled + fully filled)
        def margin_order_list(ms_iso8601 = remote_ms_iso8601, instrument_id:, state:, after:, before:, limit: "100")
          request_path = URI("/api/margin/v3/orders")
          params = { instrument_id:, state:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot_leverage-get_leverage
        #
        # GET /api/margin/v3/accounts/<instrument_id>/leverage
        #
        # @param instrument_id [String]
        def margin_leverage(ms_iso8601 = remote_ms_iso8601, instrument_id:)
          request_path = "api/margin/v3/accounts/#{instrument_id}/leverage"
          private_endpoint(request_path:, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot_leverage-order_information
        #
        # GET /api/margin/v3/orders/<order_id> OR /api/margin/v3/orders/<client_oid>
        #
        # @param instrument_id [String]
        # Either client_oid or order_id must be present
        # @option [String] order_id
        # @option [String] client_iod
        def margin_order_detail(ms_iso8601 = remote_ms_iso8601, instrument_id:, order_id: nil, client_oid: nil)
          raise ::ArgumentError, "Either client_oid or order_id must be present" if order_id.nil? && client_oid.nil?
          raise ::ArgumentError, "The client_oid and order_id are present" if !order_id.nil? && !client_oid.nil?

          request_path = if client_oid.nil?
                           URI("/api/futures/v3/orders/#{order_id}")
                         else
                           URI("/api/futures/v3/orders/#{client_iod}")
                         end

          params = { instrument_id: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot_leverage-orders_pending
        #
        # GET /api/margin/v3/orders_pending
        #
        # @param instrument_id [String]
        # @param after [String] Pagination of data to return records earlier than the requested order_id
        # @param before [String] Pagination of data to return records newer than the requested order_id
        # @param limit [String] The maximum is 100; the default is 100
        def margin_order_pending(ms_iso8601 = remote_ms_iso8601, instrument_id:, after:, before:, limit: "100")
          request_path = URI("/api/margin/v3/orders_pending")
          params = { instrument_id:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
        end

        # @see https://www.okx.com/docs/en/#spot_leverage-detail
        #
        # GET /api/margin/v3/fills
        #
        # @param instrument_id [String]
        # @option order_id
        # @option [String] after Pagination of data to return records earlier than the requested order_id
        # @option [String] before Pagination of data to return records newer than the requested order_id
        # @option [String] limit The maximum is 100; the default is 100
        def margin_transaction_detail(ms_iso8601 = remote_ms_iso8601, instrument_id:, order_id: nil, after: nil, before: nil, limit: "100")
          request_path = URI("/api/margin/v3/fill")
          params = { instrument_id:, order_id:, after:, before:, limit: }.compact
          request_path.query = URI.encode_www_form(params)

          private_endpoint(request_path: request_path.to_s, ms_iso8601:)
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

        def sign(request_path:, ms_iso8601:)
          Base64EncodedSignature.new(secret_key:).call(request_path:, ms_iso8601:)
        end
      end
    end
  end
end
