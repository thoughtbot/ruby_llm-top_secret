# frozen_string_literal: true

module RubyLLM
  module TopSecret
    module Patches
      # Middleware that intercepts {RubyLLM::Chat#complete} to redact sensitive
      # information from all messages before they are sent to the LLM provider.
      #
      # Uses {TopSecret::Text.filter_all} for batch redaction, ensuring
      # consistent labels across messages in multi-turn conversations.
      #
      # @example
      #   chat = RubyLLM.chat
      #   chat.ask("My email is ralph@example.com")
      #   # => Provider receives "My email is [EMAIL_1]"
      module Chat
        # @see RubyLLM::Chat#complete
        def complete(&)
          originals = messages.to_h { |msg| [msg, msg.content] }

          contents = messages.map(&:content)
          batch_result = ::TopSecret::Text.filter_all(contents)
          messages.zip(batch_result.items).each { |msg, item| msg.content = item.output }

          super
        ensure
          originals.each { |msg, content| msg.content = content }
        end
      end
    end
  end
end
