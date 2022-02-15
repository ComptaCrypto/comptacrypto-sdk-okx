# ComptaCrypto SDK OKX

ComptaCrypto's OKX SDK.

## Status

[![CI](https://github.com/ComptaCrypto/comptacrypto-sdk-okx/workflows/CI/badge.svg?branch=main)](https://github.com/ComptaCrypto/comptacrypto-sdk-okx/actions?query=workflow%3Aci+branch%3Amain)
[![RuboCop](https://github.com/ComptaCrypto/comptacrypto-sdk-okx/workflows/RuboCop/badge.svg?branch=main)](https://github.com/ComptaCrypto/comptacrypto-sdk-okx/actions?query=workflow%3Arubocop+branch%3Amain)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "comptacrypto-sdk-okx", github: "ComptaCrypto/comptacrypto-sdk-okx"
```

And then execute:

```sh
bundle install
```

## Usage

```ruby
require "comptacrypto/sdk/okx"

# Initialization of a client v3
client_v3 = Comptacrypto::Sdk::Okx::ClientV3.new(
  api_key: ENV.fetch("OKX_API_KEY", "42"),
  secret_key: ENV.fetch("OKX_SECRET_KEY", "secret"),
  passphrase: ENV.fetch("OKX_PASSPHRASE", "secret")
)

# Send a request to query server time
client_v3.time # => #<Faraday::Response:0x00007f74e3a758f0>
client_v3.time.body # => {"iso"=>"2022-02-07T21:40:25.791Z", "epoch"=>"1644270025.791"}

# Send a request to query withdrawal history
client_v3.withdrawal_history.body
# =>  [
#       {
#         "amount" => 0.094,
#         "withdrawal_id" => "4703879",
#         "fee" => "0.01000000eth",
#         "txid" => "0x62477bac6509a04512819bb1455e923a60dea5966c7caeaa0b24eb8fb0432b85",
#         "currency" => "ETH",
#         "chain" => "ETH-TRC20",
#         "from" => "13426335357",
#         "to" => "0xA41446125D0B5b6785f6898c9D67874D763A1519",
#         "timestamp" => "2018-04-22T23:09:45.000Z",
#         "status" => "2"
#       },
#       {
#         "amount" => 0.01,
#         "withdrawal_id" => "4703879",
#         "fee" => "0.00000000btc",
#         "txid" => "",
#         "currency" => "BTC",
#         "chain" => "BTC-TRC20",
#         "from" => "13426335357",
#         "to" => "13426335357",
#         "timestamp" => "2018-05-17T02:43:08.000Z",
#         "status" => "2"
#       }
#     ]

# Initialization of a client v5
client_v5 = Comptacrypto::Sdk::Okx::ClientV5.new(
  api_key: ENV.fetch("OKX_API_KEY", "42"),
  secret_key: ENV.fetch("OKX_SECRET_KEY", "secret"),
  passphrase: ENV.fetch("OKX_PASSPHRASE", "secret")
)

# Send a request to query server time
client_v5.public_data_get_system_time # => #<Faraday::Response:0x00007f74e3a758f0>
client_v5.public_data_get_system_time.body # => {"code"=>"0", "data"=>[{"ts"=>"1644499170774"}], "msg"=>""}
```

## Test

To ensure tests & style are okay, we can execute:

```bash
bundle exec rake
```

Note: RuboCop will automatically try to correct any style errors if it finds any. :cop:

## How to refresh VCR cassettes

It is possible (and recommended) to update the VCR cassettes from time to time.
This allows us to make sure that our tests use fresh payloads.

To update cassettes, simply:

* run the task: `bundle exec rake delete_all_remote_exchange_data_in_test`
* fill credentials on the `.env.test.local` file (this file MUST NOT be versioned)
* run tests: `bundle exec rspec`

## How to use environment variables

It is not necessary to use environment variables.

However, environment variables are convenient for creating cassettes from the testing environment.
Thanks to environment variables, API secrets are not stored in the code.
Also, VCR will take care to remove any secret codes present in the cassettes.

This makes it possible to version all the files while ignoring sensitive data.

The `.env.test.local` file which is not versioned can be created from the `.env.test.local.example` example file.

## Versioning

__Comptacrypto::Sdk::Okx__ uses [Semantic Versioning 2.0.0](https://semver.org/)
