# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  # @see https://relishapp.com/vcr/vcr/v/6-0-0/docs/configuration/filter-sensitive-data
  config.filter_sensitive_data("<OKX_API_KEY>")    { ENV["OKX_API_KEY"] }
  config.filter_sensitive_data("<OKX_SECRET_KEY>") { ENV["OKX_SECRET_KEY"] }
  config.filter_sensitive_data("<OKX_PASSPHRASE>") { ENV["OKX_PASSPHRASE"] }
end
