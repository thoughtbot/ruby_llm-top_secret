# frozen_string_literal: true

require "ruby_llm"
require "top_secret"
require_relative "top_secret/version"
require_relative "top_secret/payload"
require_relative "top_secret/patches/chat"

module RubyLLM
  # Integrates Top Secret with RubyLLM to automatically filter sensitive
  # information before it is sent to LLM providers.
  module TopSecret
    # Base error class for all RubyLLM::TopSecret errors.
    class Error < StandardError; end
  end
end

RubyLLM::Chat.prepend(RubyLLM::TopSecret::Patches::Chat)

if defined?(Rails::Railtie)
  require_relative "top_secret/railtie"
end
