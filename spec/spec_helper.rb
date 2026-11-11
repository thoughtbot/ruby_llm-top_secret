# frozen_string_literal: true

require "active_support/core_ext/object/with"
require "ruby_llm/top_secret"
require "webmock/rspec"
require_relative "support/filtering_helpers"
require_relative "support/lookup_tool"

RSpec.configure do |config|
  config.include FilteringHelpers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
