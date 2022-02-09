# frozen_string_literal: true

require "base64"
require "openssl"

module Comptacrypto
  module Sdk
    module Okx
      # Signing Messages
      #
      # @see https://www.okx.com/docs/en/#signing-messages
      # @see https://www.okx.com/docs-v5/en/#rest-api-authentication-signature
      class Base64EncodedSignature
        attr_reader :secret_key

        def initialize(secret_key:)
          @secret_key = secret_key
        end

        # @note Given the JS implementation example from the official doc,
        #
        #     var hash = CryptoJS.HmacSHA256("message", "secret");
        #     // => { words: [ -1956689808, 697680217, -1940439631, -501717335, -1205480281, -1798215209, 101319520, 1469462027 ], sigBytes: 32 }
        #
        #     var hashInBase64 = CryptoJS.enc.Base64.stringify(hash);
        #     // => 'i19IcCmVwVmMVz2x4hhmqbgl1KeU0WnXBgoDYFeWNgs='
        #
        #   the equivalent Ruby implementation should be:
        #
        #     hash = OpenSSL::HMAC.digest("SHA256", "secret", "message")
        #     # => "\x8B_Hp)\x95\xC1Y\x8CW=\xB1\xE2\x18f\xA9\xB8%\xD4\xA7\x94\xD1i\xD7\x06\n\x03`W\x966\v"
        #
        #     Base64.strict_encode64(hash)
        #     # => "i19IcCmVwVmMVz2x4hhmqbgl1KeU0WnXBgoDYFeWNgs="
        def call(request_path:, ms_iso8601:)
          message = "#{ms_iso8601}GET#{request_path}"
          hash = ::OpenSSL::HMAC.digest("SHA256", secret_key, message)
          ::Base64.strict_encode64(hash)
        end
      end
    end
  end
end
