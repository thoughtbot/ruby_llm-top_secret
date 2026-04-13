# frozen_string_literal: true

module RubyLLM
  module TopSecret
    module Patches
      # Middleware that intercepts {RubyLLM::Chat#complete} to redact sensitive
      # information from all messages before they are sent to the LLM provider,
      # and rehydrates placeholders in the response with original values.
      #
      # Uses {TopSecret::Text.filter_all} for batch redaction, ensuring
      # consistent labels across messages in multi-turn conversations.
      # Uses {TopSecret::FilteredText.restore} to replace placeholders in the
      # provider's response with the original sensitive values.
      #
      # Original message content is preserved after the call via +ensure+.
      #
      # @raise [RubyLLM::TopSecret::Error] if redaction or rehydration fails
      #
      # @example
      #   chat = RubyLLM.chat
      #   chat.ask("My name is Ralph")
      #   # => Provider receives "My name is [PERSON_1]"
      #   # => Response "[PERSON_1] is a great name" becomes "Ralph is a great name"
      module Chat
        # @see RubyLLM::Chat#complete
        def complete(&)
          originals = messages.to_h { |msg| [msg, msg.content] }

          redactable = messages.reject { |msg| msg.content.nil? || msg.content.empty? }
          contents = redactable.map(&:content)
          batch_result = ::TopSecret::Text.filter_all(contents)
          redactable.zip(batch_result.items).each { |msg, item| msg.content = item.output }

          response = super

          restored = ::TopSecret::FilteredText.restore(response.content, mapping: batch_result.mapping)
          response.content = restored.output

          response
        rescue RubyLLM::Error
          raise
        rescue => e
          raise RubyLLM::TopSecret::Error, e.message
        ensure
          originals.each { |msg, content| msg.content = content }
        end
      end
    end
  end
end
