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

        # Get system time
        #
        # @note Retrieve API server time.
        #
        #   GET /api/v5/public/time
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-public-data-get-system-time
        def public_data_get_system_time
          get!("/api/v5/public/time")
        end

        # Get instruments
        #
        # @note Retrieve a list of instruments with open contracts.
        #
        #   GET /api/v5/public/instruments
        #
        # @param inst_type  [String] Instrument type
        # @param uly        [String] Underlying
        # @param inst_id    [String] Instrument ID
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-public-data-get-instruments
        def public_data_get_instruments(inst_type:, uly: nil, inst_id: nil)
          instrument_types = %w[
            SPOT
            MARGIN
            SWAP
            FUTURES
            OPTION
          ].freeze

          raise ::ArgumentError unless instrument_types.include?(inst_type)

          if uly.nil?
            # Required for OPTION.
            raise ::ArgumentError if inst_type == instrument_types.fetch(-1)
          else
            # Only applicable to FUTURES/SWAP/OPTION.
            raise ::ArgumentError unless instrument_types.last(3).include?(inst_type)
          end

          get!("/api/v5/public/instruments", inst_type:, uly:, inst_id:)
        end

        # Get delivery/exercise history
        #
        # @note Retrieve the estimated delivery price of the last 3 months,
        #       which will only have a return value one hour before the delivery/exercise.
        #
        #   GET /api/v5/public/delivery-exercise-history
        #
        # @param inst_type  [String] Instrument type. FUTURES, OPTION
        # @param uly        [String] Underlying
        # @param after      [Integer] Pagination of data to return records earlier than the requested ts
        # @param before     [Integer] Pagination of data to return records newer than the requested ts
        # @param limit      [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-public-data-get-delivery-exercise-history
        def get_delivery_exercise_history(inst_type:, uly:, after: nil, before: nil, limit: nil)
          instrument_types = %w[
            FUTURES
            OPTION
          ].freeze

          raise ::ArgumentError unless instrument_types.include?(inst_type)

          raise ::ArgumentError if uly.nil?

          get!("/api/v5/public/delivery-exercise-history", inst_type:, uly:, after:, before:, limit:)
        end

        # Get funding rate history
        #
        # @note Retrieve funding rate history. This endpoint can retrieve data from the last 3 months.
        #
        #   GET /api/v5/public/funding-rate-history
        #
        # @param inst_id   [String] Instrument ID, e.g. BTC-USD-SWAP. Only applicable to SWAP
        # @param after    [Integer] Pagination of data to return records newer than the requested `fundingTime`
        # @param before   [Integer] Pagination of data to return records earlier than the requested `fundingTime``
        # @param limit    [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-public-data-get-funding-rate-history
        def get_funding_rate_history(inst_id:, after: nil, before: nil, limit: nil)
          raise ::ArgumentError unless inst_id.include?("SWAP")

          get!("/api/v5/public/funding-rate-history", inst_id:, after:, before:, limit:)
        end

        # Private Endpoints

        # Get order details
        #
        # @note Retrieve order details.
        #
        #   GET /api/v5/trade/order
        #
        # @note Either `ord_id` or `cl_ord_id` is required.
        #   If both are passed, `ord_id` will be the main one.
        #
        # @param inst_id    [String] Instrument ID, e.g. "BTC-USD-190927"
        # @param ord_id     [String] Order ID
        # @param cl_ord_id  [String] Client-supplied order ID
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-order-details
        def trade_get_order_details(ms_iso8601 = remote_ms_iso8601, inst_id:, ord_id: nil, cl_ord_id: nil)
          raise ::ArgumentError if ord_id.nil? && cl_ord_id.nil?

          get!("/api/v5/trade/order", ms_iso8601, inst_id:, ord_id:, cl_ord_id:)
        end

        # Get order List
        #
        # @note Retrieve all incomplete orders under the current account.
        #
        #   GET /api/v5/trade/orders-pending
        #
        # @param inst_type  [String] Instrument type
        # @param uly        [String] Underlying
        # @param inst_id    [String] Instrument ID, e.g. "BTC-USD-200927"
        # @param ord_type   [String] Order type
        # @param state      [String] State
        # @param after      [String] Pagination of data to return records earlier than the requested ordId
        # @param before     [String] Pagination of data to return records newer than the requested ordId
        # @param limit      [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-order-list
        def trade_get_order_list(ms_iso8601 = remote_ms_iso8601, inst_type: nil, uly: nil, inst_id: nil, ord_type: nil, state: nil, after: nil, before: nil, limit: nil)
          unless inst_type.nil?
            instrument_types = %w[
              SPOT
              MARGIN
              SWAP
              FUTURES
              OPTION
            ].freeze

            raise ::ArgumentError unless instrument_types.include?(inst_type)
          end

          unless ord_type.nil?
            order_types = %w[
              market
              limit
              post_only
              fok
              ioc
              Optimal_limit_ioc
            ].freeze

            raise ::ArgumentError unless order_types.include?(ord_type)
          end

          unless state.nil?
            states = %w[
              live
              partially_filled
            ].freeze

            raise ::ArgumentError unless states.include?(state)
          end

          get!("/api/v5/trade/orders-pending", ms_iso8601, inst_type:, uly:, inst_id:, ord_type:, state:, after:, before:, limit:)
        end

        # Get order history (last 7 days)
        #
        # @note Retrieve the completed order data for the last 7 days, and the incomplete orders that have been cancelled are only reserved for 2 hours.
        #
        #   GET /api/v5/trade/orders-history
        #
        # @param inst_type  [String] Instrument type
        # @param uly        [String] Underlying
        # @param inst_id    [String] Instrument ID, e.g. "BTC-USD-190927"
        # @param ord_type   [String] Order type
        # @param state      [String] State
        # @param category   [String] Category
        # @param after      [String] Pagination of data to return records earlier than the requested ordId
        # @param before     [String] Pagination of data to return records newer than the requested ordId
        # @param limit      [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-order-history-last-7-days
        def trade_get_order_history_last_7_days(ms_iso8601 = remote_ms_iso8601, inst_type:, uly: nil, inst_id: nil, ord_type: nil, state: nil, category: nil, after: nil, before: nil, limit: nil)
          instrument_types = %w[
            SPOT
            MARGIN
            SWAP
            FUTURES
            OPTION
          ].freeze

          raise ::ArgumentError unless instrument_types.include?(inst_type)

          unless ord_type.nil?
            order_types = %w[
              market
              limit
              post_only
              fok
              ioc
              optimal_limit_ioc
            ].freeze

            raise ::ArgumentError unless order_types.include?(ord_type)
          end

          unless state.nil?
            states = %w[
              canceled
              filled
            ].freeze

            raise ::ArgumentError unless states.include?(state)
          end

          unless category.nil?
            categories = %w[
              twap
              adl
              full_liquidation
              partial_liquidation
              delivery
              ddh
            ].freeze

            raise ::ArgumentError unless categories.include?(category)
          end

          get!("/api/v5/trade/orders-history", ms_iso8601, inst_type:, uly:, inst_id:, ord_type:, state:, category:, after:, before:, limit:)
        end

        # Get order history (last 3 months)
        #
        # @note Retrieve the completed order data of the last 3 months.
        #
        #   GET /api/v5/trade/orders-history-archive
        #
        # @param inst_type  [String] Instrument type
        # @param uly        [String] Underlying
        # @param inst_id    [String] Instrument ID, e.g. "BTC-USD-200927"
        # @param ord_type   [String] Order type
        # @param state      [String] State
        # @param category   [String] Category
        # @param after      [String] Pagination of data to return records earlier than the requested ordId
        # @param before     [String] Pagination of data to return records newer than the requested ordId
        # @param limit      [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-order-history-last-3-months
        def trade_get_order_history_last_3_months(ms_iso8601 = remote_ms_iso8601, inst_type:, uly: nil, inst_id: nil, ord_type: nil, state: nil, category: nil, after: nil, before: nil, limit: nil)
          instrument_types = %w[
            SPOT
            MARGIN
            SWAP
            FUTURES
            OPTION
          ].freeze

          raise ::ArgumentError unless instrument_types.include?(inst_type)

          unless ord_type.nil?
            order_types = %w[
              market
              limit
              post_only
              fok
              ioc
              optimal_limit_ioc
            ].freeze

            raise ::ArgumentError unless order_types.include?(ord_type)
          end

          unless state.nil?
            states = %w[
              canceled
              filled
            ].freeze

            raise ::ArgumentError unless states.include?(state)
          end

          unless category.nil?
            categories = %w[
              twap
              adl
              full_liquidation
              partial_liquidation
              delivery
              ddh
            ].freeze

            raise ::ArgumentError unless categories.include?(category)
          end

          get!("/api/v5/trade/orders-history-archive", ms_iso8601, inst_type:, uly:, inst_id:, ord_type:, state:, category:, after:, before:, limit:)
        end

        # Get transaction details (last 3 days)
        #
        # @note Retrieve recently-filled transaction details in the last 3 day.
        #
        #   GET /api/v5/trade/fills
        #
        # @param inst_type  [String] Instrument type
        # @param uly        [String] Underlying
        # @param inst_id    [String] Instrument ID, e.g. "BTC-USD-190927"
        # @param ord_id     [String] Order ID
        # @param after      [String] Pagination of data to return records earlier than the requested billId
        # @param before     [String] Pagination of data to return records newer than the requested billId
        # @param limit      [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-transaction-details-last-3-days
        def trade_get_transaction_details_last_3_days(ms_iso8601 = remote_ms_iso8601, inst_type: nil, uly: nil, inst_id: nil, ord_id: nil, after: nil, before: nil, limit: nil)
          unless inst_type.nil?
            instrument_types = %w[
              SPOT
              MARGIN
              SWAP
              FUTURES
              OPTION
            ].freeze

            raise ::ArgumentError unless instrument_types.include?(inst_type)
          end

          get!("/api/v5/trade/fills", ms_iso8601, inst_type:, uly:, inst_id:, ord_id:, after:, before:, limit:)
        end

        # Get transaction details (last 3 months)
        #
        # @note Retrieve recently-filled transaction details in the last 3 months.
        #
        #   GET /api/v5/trade/fills-history
        #
        # @param inst_type  [String] Instrument type
        # @param uly        [String] Underlying
        # @param inst_id    [String] Instrument ID, e.g. "BTC-USD-190927"
        # @param ord_id     [String] Order ID
        # @param after      [String] Pagination of data to return records earlier than the requested billId
        # @param before     [String] Pagination of data to return records newer than the requested billId
        # @param limit      [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-transaction-details-last-3-months
        def trade_get_transaction_details_last_3_months(ms_iso8601 = remote_ms_iso8601, inst_type:, uly: nil, inst_id: nil, ord_id: nil, after: nil, before: nil, limit: nil)
          instrument_types = %w[
            SPOT
            MARGIN
            SWAP
            FUTURES
            OPTION
          ].freeze

          raise ::ArgumentError unless instrument_types.include?(inst_type)

          get!("/api/v5/trade/fills-history", ms_iso8601, inst_type:, uly:, inst_id:, ord_id:, after:, before:, limit:)
        end

        # Get algo order list
        #
        # @note Retrieve a list of untriggered Algo orders under the current account.
        #
        #   GET /api/v5/trade/orders-algo-pending
        #
        # @param ord_type   [String] Order type
        # @param algo_id    [String] Algo ID
        # @param inst_type  [String] Instrument type
        # @param inst_id    [String] Instrument ID, e.g. "BTC-USD-190927"
        # @param after      [String] Pagination of data to return records earlier than the requested algoId
        # @param before     [String] Pagination of data to return records newer than the requested algoId
        # @param limit      [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-algo-order-list
        def trade_get_algo_order_list(ms_iso8601 = remote_ms_iso8601, ord_type:, algo_id: nil, inst_type: nil, inst_id: nil, after: nil, before: nil, limit: nil)
          order_types = %w[
            conditional
            oco
            trigger
            move_order_stop
            iceberg
            twap
          ].freeze

          raise ::ArgumentError unless order_types.include?(ord_type)

          unless inst_type.nil?
            instrument_types = %w[
              SPOT
              SWAP
              FUTURES
              MARGIN
            ].freeze

            raise ::ArgumentError unless instrument_types.include?(inst_type)
          end

          get!("/api/v5/trade/orders-algo-pending", ms_iso8601, after:, before:, limit:, ord_type:, algo_id:, inst_type:, inst_id:)
        end

        # Get algo order history
        #
        # @note Retrieve a list of all algo orders under the current account in the last 3 months.
        #
        #   GET /api/v5/trade/orders-algo-history
        #
        # @note Either `state` or `algo_id` is required.
        #
        # @param ord_type   [String] Order type
        # @param state      [String] State
        # @param algo_id    [String] Algo ID
        # @param inst_type  [String] Instrument type
        # @param inst_id    [String] Instrument ID, e.g. "BTC-USD-190927"
        # @param after      [String] Pagination of data to return records earlier than the requested algoId
        # @param before     [String] Pagination of data to return records newer than the requested algoId
        # @param limit      [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trade-get-algo-order-history
        def trade_get_algo_order_history(ms_iso8601 = remote_ms_iso8601, ord_type:, state: nil, algo_id: nil, inst_type: nil, inst_id: nil, after: nil, before: nil, limit: nil)
          order_types = %w[
            conditional
            oco
            trigger
            move_order_stop
            iceberg
            twap
          ].freeze

          raise ::ArgumentError unless order_types.include?(ord_type)

          unless state.nil?
            states = %w[
              effective
              canceled
              order_failed
            ].freeze

            raise ::ArgumentError unless states.include?(state)
          end

          raise ::ArgumentError if state.nil? && algo_id.nil?

          unless inst_type.nil?
            instrument_types = %w[
              SPOT
              SWAP
              FUTURES
              MARGIN
            ].freeze

            raise ::ArgumentError unless instrument_types.include?(inst_type)
          end

          get!("/api/v5/trade/orders-algo-history", ms_iso8601, after:, before:, limit:, ord_type:, state:, algo_id:, inst_type:, inst_id:)
        end

        # Get currencies
        #
        # @note Retrieve a list of all currencies.
        #
        #   GET /api/v5/asset/currencies
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-currencies
        def funding_get_currencies(ms_iso8601 = remote_ms_iso8601)
          get!("/api/v5/asset/currencies", ms_iso8601)
        end

        # Get balance
        #
        # Retrieve the balances of all the assets and the amount that is available or on hold.
        #
        #   GET /api/v5/asset/balances
        #
        # @param ccy [String] Single currency or multiple currencies (no more than 20) separated with comma, e.g. "BTC" or "BTC,ETH".
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-balance
        def funding_get_balance(ms_iso8601 = remote_ms_iso8601, ccy: nil)
          get!("/api/v5/asset/balances", ms_iso8601, ccy:)
        end

        # Get account asset valuation
        #
        # @note View account asset valuation.
        #
        #   GET /api/v5/asset/asset-valuation
        #
        # @param ccy [String] Asset valuation calculation unit. The default is the valuation in "BTC".
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-account-asset-valuation
        def funding_get_account_asset_valuation(ms_iso8601 = remote_ms_iso8601, ccy: nil)
          get!("/api/v5/asset/asset-valuation", ms_iso8601, ccy:)
        end

        # Get funds transfer state
        #
        # @note
        #   GET /api/v5/asset/transfer-state
        #
        # @param trans_id [String] Transfer ID
        # @param type     [Integer, nil] Transfer type. The default is `0`.
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-funds-transfer-state
        def funding_get_funds_transfer_state(ms_iso8601 = remote_ms_iso8601, trans_id:, type: nil)
          unless type.nil?
            types = [0, 1, 2]
            raise ::ArgumentError unless types.include?(type)
          end

          get!("/api/v5/asset/transfer-state", ms_iso8601, trans_id:, type:)
        end

        # Asset bills details
        #
        # @note Query the billing record, you can get the latest 1 month historical data.
        #
        #   GET /api/v5/asset/bills
        #
        # @param ccy    [String] Currency
        # @param type   [String] Bill type
        # @param after  [Integer, nil] Pagination of data to return records earlier than the requested ts
        # @param before [Integer, nil] Pagination of data to return records newer than the requested ts
        # @param limit  [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-asset-bills-details
        def funding_asset_bills_details(ms_iso8601 = remote_ms_iso8601, ccy: nil, type: nil, after: nil, before: nil, limit: nil)
          unless type.nil?
            types = [
              1, # Deposit
              2, # Withdrawal
              13, # Canceled withdrawal
              18, # Transfer to futures
              19, # Transfer from futures
              20, # Transfer to Sub account
              21, # Transfer from Sub account
              28, # Claim
              33, # Transfer to margin
              34, # Transfer from margin
              37, # Transfer to spot
              38, # Transfer from spot
              41, # Trading fees settled by loyalty points
              42, # Loyalty points purchase
              47, # System reversal
              48, # Received from activities
              49, # Given away to activities
              50, # Received from appointments
              51, # Deducted from appointments
              52, # Red packet sent
              53, # Red packet snatched
              54, # Red packet refunded
              55, # Transfer to perpetual
              56, # Transfer from perpetual
              59, # Transfer from hedging account
              60, # Transfer to hedging account
              61, # Conversion
              63, # Transfer to options
              62, # Transfer from options
              68, # Claim rebate card
              69, # Distribute rebate card
              72, # Token received
              73, # Token given away
              74, # Token refunded
              75, # Subscription to savings
              76, # Redemption to savings
              77, # Distribute
              78, # Lock up
              79, # Node voting
              80, # Staking
              81, # Vote redemption
              82, # Staking redemption
              83, # Staking yield
              84, # Violation fee
              85, # PoW mining yield
              86, # Cloud mining pay
              87, # Cloud mining yield
              88, # Subsidy
              89, # Staking
              90, # Staking subscription
              91, # staking redemption
              92, # Add collateral
              93, # Redeem collateral
              94, # Investment
              95, # Borrower borrows
              96, # Principal transferred in
              97, # Borrower transferred loan out
              98, # Borrower transferred interest out
              99, # Investor transferred interest in
              102, # Prepayment penalty transferred in
              103, # Prepayment penalty transferred out
              104, # Fee transferred in
              105, # Fee transferred out
              106, # Overdue fee transferred in
              107, # Overdue fee transferred out
              108, # Overdue interest transferred out
              109, # Overdue interest transferred in
              110, # Collateral for closed position transferred in
              111, # Collateral for closed position transferred out
              112, # Collateral for liquidation transferred in
              113, # Collateral for liquidation transferred out
              114, # Insurance fund transferred in
              115, # Insurance fund transferred out
              116, # Place an order
              117, # Fulfill an order
              118, # Cancel an order
              119, # Merchants unlock deposit
              120, # Merchants add deposit
              121, # FiatGateway Place an order
              122, # FiatGateway Cancel an order
              123, # FiatGateway Fulfill an order
              124, # Jumpstart unlocking
              125, # Manual deposit
              126, # Interest deposit
              127, # Investment fee transferred in
              128, # Investment fee transferred out
              129, # Rewards transferred in
              130, # Transferred from unified account
              131, # Transferred to unified account
              150, # Affiliate commission
              151  # Referral reward
            ].freeze

            raise ::ArgumentError unless types.include?(type)
          end

          get!("/api/v5/asset/bills", ms_iso8601, ccy:, type:, after:, before:, limit:)
        end

        # Lightning deposits
        #
        # @note Users can create up to 100 different invoices within 24 hours.
        #
        #   GET /api/v5/asset/deposit-lightning
        #
        # @note This API function service is only open to some users.
        #
        # @param ccy  [String]  Token symbol. Currently only "BTC" is supported.
        # @param amt  [Float]   Deposit amount between `0.000001` and `0.1`
        # @param to   [Integer] Receiving account.
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-lightning-deposits
        def funding_lightning_deposits(ms_iso8601 = remote_ms_iso8601, ccy:, amt:, to: nil)
          raise ::ArgumentError unless (0.000001..0.1).cover?(amt)

          unless to.nil?
            accounts = [
              6, # funding account (default)
              1  # spot account
            ].freeze

            raise ::ArgumentError unless accounts.include?(to)
          end

          get!("/api/v5/asset/deposit-lightning", ms_iso8601, amt:, to:, ccy:)
        end

        # Get deposit address
        #
        # @note Retrieve the deposit addresses of currencies, including previously-used addresses.
        #
        #   GET /api/v5/asset/deposit-address
        #
        # @param ccy [String] Currency, e.g. "BTC"
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-deposit-address
        def funding_get_deposit_address(ms_iso8601 = remote_ms_iso8601, ccy:)
          get!("/api/v5/asset/deposit-address", ms_iso8601, ccy:)
        end

        # Get deposit history
        #
        # @note Retrieve the deposit records according to the currency,
        #   withdrawal status, and time range in reverse chronological order.
        #   The 100 most recent records are returned by default.
        #
        #   GET /api/v5/asset/deposit-history
        #
        # @param ccy    [String] Currency, e.g. "BTC"
        # @param tx_id  [String] Hash record of the deposit
        # @param state  [String] Status of deposit
        # @param after  [Integer, nil] Pagination of data to return records earlier than the requested ts
        # @param before [Integer, nil] Pagination of data to return records newer than the requested ts
        # @param limit  [Integer, nil] The maximum is 100; The default is 100
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-deposit-history
        def funding_get_deposit_history(ms_iso8601 = remote_ms_iso8601, ccy: nil, tx_id: nil, state: nil, after: nil, before: nil, limit: nil)
          unless state.nil?
            deposit_statuses = [
              0, # waiting for confirmation
              1, # deposit credited
              2  # deposit successful
            ].freeze

            raise ::ArgumentError unless deposit_statuses.include?(state)
          end

          get!("/api/v5/asset/deposit-history", ms_iso8601, ccy:, tx_id:, state:, after:, before:, limit:)
        end

        # Get withdrawal history
        #
        # @note Retrieve the withdrawal records according to the currency, withdrawal
        #   status, and time range in reverse chronological order.
        #   The 100 most recent records are returned by default.
        #
        #   GET /api/v5/asset/withdrawal-history
        #
        # @param ccy    [String] Currency, e.g. "`BTC`"
        # @param tx_id  [String] Hash record of the deposit
        # @param state  [Integer, nil] Status of withdrawal (from "`-3`" to "`5`")
        # @param after  [Integer, nil] Pagination of data to return records earlier than the requested ts, e.g. `1597026383085`
        # @param before [Integer, nil] Pagination of data to return records newer than the requested ts, e.g. `1597026383085`
        # @param limit  [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-withdrawal-history
        def funding_get_withdrawal_history(ms_iso8601 = remote_ms_iso8601, ccy: nil, tx_id: nil, state: nil, after: nil, before: nil, limit: nil)
          unless state.nil?
            withdrawal_statuses = [
              -3, # pending cancel
              -2, # canceled
              -1, # failed
              0,  # pending
              1,  # sending
              2,  # sent
              3,  # awaiting email verification
              4,  # awaiting manual verification
              5   # awaiting identity verification
            ].freeze

            raise ::ArgumentError unless withdrawal_statuses.include?(state)
          end

          get!("/api/v5/asset/withdrawal-history", ms_iso8601, ccy:, tx_id:, state:, after:, before:, limit:)
        end

        # Get saving balance
        #
        # @note
        #   GET /api/v5/asset/saving-balance
        #
        # @param ccy [String] Currency, e.g. "BTC"
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-saving-balance
        def funding_get_saving_balance(ms_iso8601 = remote_ms_iso8601, ccy: nil)
          get!("/api/v5/asset/saving-balance", ms_iso8601, ccy:)
        end

        # Get lending history
        #
        # @!visibility private
        #
        # @note
        #   GET /api/v5/asset/lending-history
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-lending-history
        def funding_get_lending_history
          raise ::NotImplementedError
        end

        # Get public borrow info (public)
        #
        # @!visibility private
        #
        # @note
        #   GET /api/v5/asset/lending-rate-summary
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-public-borrow-info-public
        def funding_get_public_borrow_info_public
          raise ::NotImplementedError
        end

        # Get public borrow history (public)
        #
        # @!visibility private
        #
        # @note Authentication is not required for this public endpoint.
        #
        #   GET /api/v5/asset/lending-rate-history
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-funding-get-public-borrow-history-public
        def funding_get_public_borrow_history_public
          raise ::NotImplementedError
        end

        # Get balance
        #
        # @note Retrieve a list of assets (with non-zero balance), remaining balance, and available amount in the account.
        #
        #   GET /api/v5/account/balance
        #
        # @param ccy [String] Single currency or multiple currencies (no more than 20) separated with comma, e.g. "BTC" or "BTC,ETH".
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-balance
        def account_get_balance(ms_iso8601 = remote_ms_iso8601, ccy: nil)
          get!("/api/v5/account/balance", ms_iso8601, ccy:)
        end

        # Get positions
        #
        # @note Retrieve information on your positions.
        #   When the account is in `net` mode, `net` positions will be displayed, and when the account is in `long/short` mode, `long` or `short` positions will be displayed.
        #
        #   GET /api/v5/account/positions
        #
        # @param inst_type  [String] Instrument type
        # @param inst_id    [String] Instrument ID, e.g. "BTC-USD-190927-5000-C".
        # @param pos_id     [String] Single position ID or multiple position IDs (no more than 20) separated with comma
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-positions
        def account_get_positions(ms_iso8601 = remote_ms_iso8601, inst_type: nil, inst_id: nil, pos_id: nil)
          unless inst_type.nil?
            instrument_types = %w[
              MARGIN
              SWAP
              FUTURES
              OPTION
            ].freeze

            raise ::ArgumentError unless instrument_types.include?(inst_type)
          end

          get!("/api/v5/account/positions", ms_iso8601, inst_type:, inst_id:, pos_id:)
        end

        # Get account and position risk
        #
        # @!visibility private
        #
        # @note Get account and position risk.
        #
        #   GET /api/v5/account/account-position-risk
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-account-and-position-risk
        def account_get_account_and_position_risk
          raise ::NotImplementedError
        end

        # Get bills details (last 7 days)
        #
        # @note Retrieve the bills of the account.
        #   The bill refers to all transaction records that result in changing the balance of an account.
        #   Pagination is supported, and the response is sorted with the most recent first.
        #   This endpoint can retrieve data from the last 7 days.
        #
        #   GET /api/v5/account/bills
        #
        # @param inst_type  [String] Instrument type
        # @param ccy        [String] Currency
        # @param mgn_mode   [String] Margin mode
        # @param ct_type    [String] Contract type
        # @param type       [Integer, nil] Bill type
        # @param sub_type   [Integer, nil] Bill subtype
        # @param after      [String] Pagination of data to return records earlier than the requested bill ID.
        # @param before     [String] Pagination of data to return records newer than the requested bill ID.
        # @param limit      [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-bills-details-last-7-days
        def account_get_bills_details_last_7_days(ms_iso8601 = remote_ms_iso8601, inst_type: nil, ccy: nil, mgn_mode: nil, ct_type: nil, type: nil, sub_type: nil, after: nil, before: nil, limit: nil)
          unless inst_type.nil?
            instrument_types = %w[
              SPOT
              MARGIN
              SWAP
              FUTURES
              OPTION
            ].freeze

            raise ::ArgumentError unless instrument_types.include?(inst_type)
          end

          unless mgn_mode.nil?
            margin_modes = %w[
              isolated
              cross
            ].freeze

            raise ::ArgumentError unless margin_modes.include?(mgn_mode)
          end

          unless ct_type.nil?
            contract_types = %w[
              linear
              inverse
            ].freeze

            raise ::ArgumentError unless contract_types.include?(ct_type)
          end

          unless type.nil?
            bill_types = [
              1,  # Transfer
              2,  # Trade
              3,  # Delivery
              4,  # Auto token conversion
              5,  # Liquidation
              6,  # Margin transfe
              7,  # Interest deduction
              8,  # Funding fee
              9,  # ADL
              10, # Clawback
              11, # System token conversion
              12, # Strategy transfer
              13  # ddh
            ].freeze

            raise ::ArgumentError unless bill_types.include?(type)
          end

          unless sub_type.nil?
            bill_subtypes = [
              1,   # Buy
              2,   # Sell
              3,   # Open long
              4,   # Open short
              5,   # Close long
              6,   # Close short
              9,   # Interest deduction for Market loans
              11,  # Transfer in
              12,  # Transfer out
              14,  # Interest deduction for VIP loans
              160, # Manual margin increase
              161, # Manual margin decrease
              162, # Auto margin increase
              110, # Auto buy
              111, # Auto sell
              118, # System token conversion transfer in
              119, # System token conversion transfer out
              100, # Partial liquidation close long
              101, # Partial liquidation close short
              102, # Partial liquidation buy
              103, # Partial liquidation sell
              104, # Liquidation long
              105, # Liquidation short
              106, # Liquidation buy
              107, # Liquidation sell
              110, # Liquidation transfer in
              111, # Liquidation transfer out
              125, # ADL close long
              126, # ADL close short
              127, # ADL buy
              128, # ADL sell
              131, # ddh buy
              132, # ddh sell
              170, # Exercised
              171, # Counterparty exercised
              172, # Expired OTM
              112, # Delivery long
              113, # Delivery short
              117, # Delivery/Exercise clawback
              173, # Funding fee expense
              174, # Funding fee income
              200, # System transfer in
              201, # Manually transfer in
              202, # System transfer out
              203  # Manually transfer out
            ].freeze

            raise ::ArgumentError unless bill_subtypes.include?(sub_type)
          end

          get!("/api/v5/account/bills", ms_iso8601, inst_type:, ccy:, mgn_mode:, ct_type:, type:, sub_type:, after:, before:, limit:)
        end

        # Get bills details (last 3 months)
        #
        # @note Retrieve the account’s bills.
        #   The bill refers to all transaction records that result in changing the balance of an account.
        #   Pagination is supported, and the response is sorted with most recent first.
        #   This endpoint can retrieve data from the last 3 months.
        #
        #   GET /api/v5/account/bills-archive
        #
        # @param inst_type  [String] Instrument type
        # @param ccy        [String] Currency
        # @param mgn_mode   [String] Margin mode
        # @param ct_type    [String] Contract type
        # @param type       [String] Bill type
        # @param sub_type   [String] Bill subtype
        # @param after      [String] Pagination of data to return records earlier than the requested bill ID.
        # @param before     [String] Pagination of data to return records newer than the requested bill ID.
        # @param limit      [Integer, nil] Number of results per request. The maximum is `100`; the default is `100`
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-bills-details-last-3-months
        def account_get_bills_details_last_3_months(ms_iso8601 = remote_ms_iso8601, inst_type: nil, ccy: nil, mgn_mode: nil, ct_type: nil, type: nil, sub_type: nil, after: nil, before: nil, limit: nil)
          unless inst_type.nil?
            instrument_types = %w[
              SPOT
              MARGIN
              SWAP
              FUTURES
              OPTION
            ].freeze

            raise ::ArgumentError unless instrument_types.include?(inst_type)
          end

          unless mgn_mode.nil?
            margin_modes = %w[
              isolated
              cross
            ].freeze

            raise ::ArgumentError unless margin_modes.include?(mgn_mode)
          end

          unless ct_type.nil?
            contract_types = %w[
              linear
              inverse
            ].freeze

            raise ::ArgumentError unless contract_types.include?(ct_type)
          end

          unless type.nil?
            bill_types = [
              1,  # Transfer
              2,  # Trade
              3,  # Delivery
              4,  # Auto token conversion
              5,  # Liquidation
              6,  # Margin transfe
              7,  # Interest deduction
              8,  # Funding fee
              9,  # ADL
              10, # Clawback
              11, # System token conversion
              12, # Strategy transfer
              13  # ddh
            ].freeze

            raise ::ArgumentError unless bill_types.include?(type)
          end

          unless sub_type.nil?
            bill_subtypes = [
              1,   # Buy
              2,   # Sell
              3,   # Open long
              4,   # Open short
              5,   # Close long
              6,   # Close short
              9,   # Interest deduction for Market loans
              11,  # Transfer in
              12,  # Transfer out
              14,  # Interest deduction for VIP loans
              160, # Manual margin increase
              161, # Manual margin decrease
              162, # Auto margin increase
              110, # Auto buy
              111, # Auto sell
              118, # System token conversion transfer in
              119, # System token conversion transfer out
              100, # Partial liquidation close long
              101, # Partial liquidation close short
              102, # Partial liquidation buy
              103, # Partial liquidation sell
              104, # Liquidation long
              105, # Liquidation short
              106, # Liquidation buy
              107, # Liquidation sell
              110, # Liquidation transfer in
              111, # Liquidation transfer out
              125, # ADL close long
              126, # ADL close short
              127, # ADL buy
              128, # ADL sell
              131, # ddh buy
              132, # ddh sell
              170, # Exercised
              171, # Counterparty exercised
              172, # Expired OTM
              112, # Delivery long
              113, # Delivery short
              117, # Delivery/Exercise clawback
              173, # Funding fee expense
              174, # Funding fee income
              200, # System transfer in
              201, # Manually transfer in
              202, # System transfer out
              203  # Manually transfer out
            ].freeze

            raise ::ArgumentError unless bill_subtypes.include?(sub_type)
          end

          get!("/api/v5/account/bills-archive", ms_iso8601, inst_type:, ccy:, mgn_mode:, ct_type:, type:, sub_type:, after:, before:, limit:)
        end

        # Get account configuration
        #
        # @!visibility private
        #
        # @note Retrieve current account configuration.
        #
        #   GET /api/v5/account/config
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-account-configuration
        def account_get_account_configuration
          raise ::NotImplementedError
        end

        # Get maximum buy/sell amount or open amount
        #
        # @!visibility private
        #
        # @note
        #   GET /api/v5/account/max-size
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-maximum-buy-sell-amount-or-open-amount
        def account_get_maximum_buy_sell_amount_or_open_amount
          raise ::NotImplementedError
        end

        # Get maximum available tradable amount
        #
        # @!visibility private
        #
        # @note
        #   GET /api/v5/account/max-avail-size
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-maximum-available-tradable-amount
        def account_get_maximum_available_tradable_amount
          raise ::NotImplementedError
        end

        # Get leverage
        #
        # @!visibility private
        #
        # @note
        #   GET /api/v5/account/leverage-info
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-leverage
        def account_get_leverage
          raise ::NotImplementedError
        end

        # Get the maximum loan of instrument
        #
        # @!visibility private
        #
        # @note
        #   GET /api/v5/account/max-loan
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-the-maximum-loan-of-instrument
        def account_get_the_maximum_loan_of_instrument
          raise ::NotImplementedError
        end

        # Get fee rates
        #
        # @!visibility private
        #
        # @note
        #   GET /api/v5/account/trade-fee
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-fee-rates
        def account_get_fee_rates
          raise ::NotImplementedError
        end

        # Get interest accrued data
        #
        # @!visibility private
        #
        # @note
        #   GET /api/v5/account/interest-accrued
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-interest-accrued-data
        def account_get_interest_accrued_data
          raise ::NotImplementedError
        end

        # Get interest rate
        #
        # @!visibility private
        #
        # @note Get the user's current leveraged currency borrowing interest rate.
        #
        #   GET /api/v5/account/interest-rate
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-interest-rate
        def account_get_interest_rate
          raise ::NotImplementedError
        end

        # Get maximum withdrawals
        #
        # @!visibility private
        #
        # @note Retrieve the maximum transferable amount.
        #
        #   GET /api/v5/account/max-withdrawal
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-maximum-withdrawals
        def account_get_maximum_withdrawals
          raise ::NotImplementedError
        end

        # Get account risk state
        #
        # @!visibility private
        #
        # @note Only applicable to Portfolio margin account.
        #
        #   GET /api/v5/account/risk-state
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-account-risk-state
        def account_get_account_risk_state
          raise ::NotImplementedError
        end

        # Get borrow and repay history for VIP loans
        #
        # @!visibility private
        #
        # @note
        #   GET /api/v5/account/borrow-repay-history
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-borrow-and-repay-history-for-vip-loans
        def account_get_borrow_and_repay_history_for_vip_loans
          raise ::NotImplementedError
        end

        # Get borrow interest and limit
        #
        # @!visibility private
        #
        # @note
        #   GET /api/v5/account/interest-limits
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-borrow-interest-and-limit
        def account_get_borrow_interest_and_limit
          raise ::NotImplementedError
        end

        # Get Greeks
        #
        # @!visibility private
        #
        # @note Retrieve a greeks list of all assets in the account.
        #
        #   GET /api/v5/account/greeks
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-account-get-greeks
        def account_get_greeks
          raise ::NotImplementedError
        end

        # View sub-account list
        #
        # @note Applies to master accounts only.
        #
        #   GET /api/v5/users/subaccount/list
        #
        # @param enable   [String, nil] Sub-account status
        # @param sub_acct [String, nil] Sub-account name
        # @param after    [Integer, nil] If you query the data prior to the requested creation time ID
        # @param before   [Integer, nil] If you query the data after the requested creation time ID
        # @param limit    [Integer, nil] The maximum is 100; The default is 100
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-subaccount-view-sub-account-list
        def subaccount_view_sub_account_list(ms_iso8601 = remote_ms_iso8601, enable: nil, sub_acct: nil, after: nil, before: nil, limit: nil)
          raise ::ArgumentError unless [nil, "true", "false"].include?(enable)

          get!("/api/v5/users/subaccount/list", ms_iso8601, enable:, sub_acct:, after:, before:, limit:)
        end

        # Query the APIKey of a sub-account
        #
        # @!visibility private
        #
        # @note Applies to master accounts only.
        #
        #   GET /api/v5/users/subaccount/apikey
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-subaccount-query-the-apikey-of-a-sub-account
        def subaccount_query_the_apikey_of_a_sub_account
          raise ::NotImplementedError
        end

        # Get sub-account balance
        #
        # @note Query detailed balance info of Trading Account of a sub-account via the master account (applies to master accounts only).
        #
        #   GET /api/v5/account/subaccount/balances
        #
        # @param sub_acct [String] Sub-account name
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-subaccount-get-sub-account-balance
        def subaccount_get_sub_account_balance(ms_iso8601 = remote_ms_iso8601, sub_acct:)
          get!("/api/v5/account/subaccount/balances", ms_iso8601, sub_acct:)
        end

        # History of sub-account transfer
        #
        # @!visibility private
        #
        # @note Applies to master accounts only.
        #
        #   GET /api/v5/asset/subaccount/bills
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-subaccount-history-of-sub-account-transfer
        def subaccount_history_of_sub_account_transfer
          raise ::NotImplementedError
        end

        # Get custody trading sub-account list
        #
        # @!visibility private
        #
        # @note The trading team uses this interface to view the list of sub-accounts currently under escrow.
        #
        #   GET /api/v5/users/entrust-subaccount-list
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-subaccount-get-custody-trading-sub-account-list
        def subaccount_get_custody_trading_sub_account_list
          raise ::NotImplementedError
        end

        # Get tickers
        #
        # @note Retrieve the latest price snapshot, best bid/ask price, and trading volume in the last 24 hours.
        #
        #   GET /api/v5/market/tickers
        #
        # @param inst_type  [String] Instrument type
        # @param uly        [String] Underlying, e.g. "BTC-USD"
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-tickers
        def market_data_get_tickers(ms_iso8601 = remote_ms_iso8601, inst_type:, uly: nil)
          instrument_types = %w[
            SPOT
            SWAP
            FUTURES
            OPTION
          ].freeze

          raise ::ArgumentError unless instrument_types.include?(inst_type)

          get!("/api/v5/market/tickers", ms_iso8601, inst_type:, uly:)
        end

        # Get ticker
        #
        # @note Retrieve the latest price snapshot, best bid/ask price, and trading volume in the last 24 hours.
        #
        #   GET /api/v5/market/ticker
        #
        # @param inst_id [String] Instrument ID, e.g. "BTC-USD-SWAP"
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-ticker
        def market_data_get_ticker(ms_iso8601 = remote_ms_iso8601, inst_id:)
          get!("/api/v5/market/ticker", ms_iso8601, inst_id:)
        end

        # Get index tickers
        #
        # @!visibility private
        #
        # @note Retrieve index tickers.
        #
        #   GET /api/v5/market/index-tickers
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-index-tickers
        def market_data_get_index_tickers
          raise ::NotImplementedError
        end

        # Get order book
        #
        # @!visibility private
        #
        # @note Retrieve order book of the instrument.
        #
        #   GET /api/v5/market/books
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-order-book
        def market_data_get_order_book
          raise ::NotImplementedError
        end

        # Get candlesticks
        #
        # @!visibility private
        #
        # @note Retrieve the candlestick charts.
        #   This endpoint can retrieve the latest 1,440 data entries.
        #   Charts are returned in groups based on the requested bar.
        #
        #   GET /api/v5/market/candles
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-candlesticks
        def market_data_get_candlesticks
          raise ::NotImplementedError
        end

        # Get candlesticks history
        #
        # @!visibility private
        #
        # @note Retrieve history candlestick charts from recent years.
        #
        #   GET /api/v5/market/history-candles
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-candlesticks-history
        def market_data_get_candlesticks_history
          raise ::NotImplementedError
        end

        # Get index candlesticks
        #
        # @!visibility private
        #
        # @note Retrieve the candlestick charts of the index.
        #   This endpoint can retrieve the latest 1,440 data entries.
        #   Charts are returned in groups based on the requested bar.
        #
        #   GET /api/v5/market/index-candles
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-index-candlesticks
        def market_data_get_index_candlesticks
          raise ::NotImplementedError
        end

        # Get mark price candlesticks
        #
        # @!visibility private
        #
        # @note Retrieve the candlestick charts of mark price.
        #   This endpoint can retrieve the latest 1,440 data entries.
        #   Charts are returned in groups based on the requested bar.
        #
        #   GET /api/v5/market/mark-price-candles
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-mark-price-candlesticks
        def market_data_get_mark_price_candlesticks
          raise ::NotImplementedError
        end

        # Get trades
        #
        # @!visibility private
        #
        # @note Retrieve the recent transactions of an instrument.
        #
        #   GET /api/v5/market/trades
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-trades
        def market_data_get_trades
          raise ::NotImplementedError
        end

        # Get 24H total volume
        #
        # @!visibility private
        #
        # @note The 24-hour trading volume is calculated on a rolling basis, using USD as the pricing unit.
        #
        #   GET /api/v5/market/platform-24-volume
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-24h-total-volume
        def market_data_get_24h_total_volume
          raise ::NotImplementedError
        end

        # Get oracle
        #
        # @!visibility private
        #
        # @note Get the crypto price of signing using Open Oracle smart contract.
        #
        #   GET /api/v5/market/open-oracle
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-oracle
        def market_data_get_oracle
          raise ::NotImplementedError
        end

        # Get exchange rate
        #
        # @!visibility private
        #
        # @note This interface provides the average exchange rate data for 2 weeks.
        #
        #   GET /api/v5/market/exchange-rate
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-exchange-rate
        def market_data_get_exchange_rate
          raise ::NotImplementedError
        end

        # Get index components
        #
        # @!visibility private
        #
        # @note Get the index component information data on the market.
        #
        #   GET /api/v5/market/index-components
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-market-data-get-index-components
        def market_data_get_index_components
          raise ::NotImplementedError
        end

        # Get support coin
        #
        # @!visibility private
        #
        # @note Retrieve the currencies supported by the trading data endpoints.
        #
        #   GET /api/v5/rubik/stat/trading-data/support-coin
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trading-data-get-support-coin
        def trading_data_get_support_coin
          raise ::NotImplementedError
        end

        # Get taker volume
        #
        # @!visibility private
        #
        # @note Retrieve the taker volume for both buyers and sellers.
        #
        #   GET /api/v5/rubik/stat/taker-volume
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trading-data-get-taker-volume
        def trading_data_get_taker_volume
          raise ::NotImplementedError
        end

        # Get margin lending ratio
        #
        # @!visibility private
        #
        # @note Retrieve the ratio of cumulative amount between currency margin quote currency and base currency.
        #
        #   GET /api/v5/rubik/stat/margin/loan-ratio
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trading-data-get-margin-lending-ratio
        def trading_data_get_margin_lending_ratio
          raise ::NotImplementedError
        end

        # Get contracts open interest and volume
        #
        # @!visibility private
        #
        # @note Retrieve the open interest and trading volume for futures and perpetual swaps.
        #
        #   GET /api/v5/rubik/stat/contracts/long-short-account-ratio
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trading-data-get-long-short-ratio
        def trading_data_get_long_short_ratio
          raise ::NotImplementedError
        end

        # Get contracts open interest and volume
        #
        # @!visibility private
        #
        # @note Retrieve the open interest and trading volume for futures and perpetual swaps.
        #
        #   GET /api/v5/rubik/stat/contracts/open-interest-volume
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trading-data-get-contracts-open-interest-and-volume
        def trading_data_get_contracts_open_interest_and_volume
          raise ::NotImplementedError
        end

        # Get options open interest and volume
        #
        # @!visibility private
        #
        # @note Retrieve the open interest and trading volume for options.
        #
        #   GET /api/v5/rubik/stat/option/open-interest-volume
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trading-data-get-options-open-interest-and-volume
        def trading_data_get_options_open_interest_and_volume
          raise ::NotImplementedError
        end

        # Get put/call ratio
        #
        # @!visibility private
        #
        # @note Retrieve the open interest ration and trading volume ratio of calls vs puts.
        #
        #   GET /api/v5/rubik/stat/option/open-interest-volume-ratio
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trading-data-get-put-call-ratio
        def trading_data_get_put_call_ratio
          raise ::NotImplementedError
        end

        # Get open interest and volume (expiry)
        #
        # @!visibility private
        #
        # @note Retrieve the open interest and trading volume of calls and puts for each upcoming expiration.
        #
        #   GET /api/v5/rubik/stat/option/open-interest-volume-expiry
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trading-data-get-open-interest-and-volume-expiry
        def trading_data_get_open_interest_and_volume_expiry
          raise ::NotImplementedError
        end

        # Get open interest and volume (strike)
        #
        # @!visibility private
        #
        # @note Retrieve the taker volume for both buyers and sellers of calls and puts.
        #
        #   GET /api/v5/rubik/stat/option/open-interest-volume-strike
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trading-data-get-open-interest-and-volume-strike
        def trading_data_get_open_interest_and_volume_strike
          raise ::NotImplementedError
        end

        # Get taker flow
        #
        # @!visibility private
        #
        # @note This shows the relative buy/sell volume for calls and puts.
        #   It shows whether traders are bullish or bearish on price and volatility.
        #
        #   GET /api/v5/rubik/stat/option/taker-block-volume
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-trading-data-get-taker-flow
        def trading_data_get_taker_flow
          raise ::NotImplementedError
        end

        # Status
        #
        # @!visibility private
        #
        # @note Get event status of system upgrade
        #
        #   GET /api/v5/system/status
        #
        # @see https://www.okx.com/docs-v5/en/#rest-api-status
        def status
          raise ::NotImplementedError
        end

        private

        def get!(request_path, sign_with_ms_iso8601 = nil, **params)
          request_path = URI(request_path)
          request_path.query = uri_query(**params.compact)

          if sign_with_ms_iso8601.nil?
            conn.get(request_path)
          else
            conn.get(request_path) do |req|
              req.headers["OK-ACCESS-KEY"]        = api_key
              req.headers["OK-ACCESS-SIGN"]       = sign(request_path:, ms_iso8601: sign_with_ms_iso8601)
              req.headers["OK-ACCESS-TIMESTAMP"]  = sign_with_ms_iso8601
              req.headers["OK-ACCESS-PASSPHRASE"] = passphrase
            end
          end
        end

        def remote_ms_iso8601
          ms_ts_str = public_data_get_system_time.body.fetch("data").fetch(0).fetch("ts")
          ::Time.strptime(ms_ts_str, "%Q").utc.iso8601(3)
        end

        def sign(request_path:, ms_iso8601:)
          Base64EncodedSignature.new(secret_key:).call(request_path:, ms_iso8601:)
        end

        # @example
        #   snake_case_to_lower_camel_case(:foo_bar) # => "fooBar"
        def snake_case_to_lower_camel_case(text)
          first_word, *other_words = String(text).split("_")
          first_word + other_words.map(&:capitalize).join
        end

        def uri_query(**params)
          return if params.empty?

          ::URI.encode_www_form(**params.transform_keys { |key| snake_case_to_lower_camel_case(key).to_sym })
        end
      end
    end
  end
end
