# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "comptacrypto-sdk-okx"
  spec.version       = File.read("VERSION.semver").chomp
  spec.author        = "ComptaCrypto"
  spec.email         = "contact@comptacrypto.com"
  spec.summary       = "ComptaCrypto's OKX SDK."
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/ComptaCrypto/comptacrypto-sdk-okx"
  spec.license       = "MIT"
  spec.files         = Dir["LICENSE.md", "README.md", "lib/**/*"]
  spec.required_ruby_version = ::Gem::Requirement.new(">= 3.1.0")

  spec.add_dependency "faraday"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop-md"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "rubocop-thread_safety"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "yard"

  spec.metadata["rubygems_mfa_required"] = "true"
end
