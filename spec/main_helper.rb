# frozen_string_literal: true

# Load and launch SimpleCov at the very top of this spec/main_helper.rb file.
require "simplecov"
SimpleCov.start

require_relative File.join("..", "lib", "comptacrypto/sdk/okx")

require_relative "spec_helper"

Dir[File.join File.dirname(__FILE__), "support", "**", "*.rb"].each do |fname|
  require_relative fname
end
