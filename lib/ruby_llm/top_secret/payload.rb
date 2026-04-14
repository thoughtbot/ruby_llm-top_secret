# frozen_string_literal: true

module RubyLLM
  module TopSecret
    # Represents the sensitive content flowing between a RubyLLM chat and
    # the LLM provider. Mirrors Top Secret's own vocabulary:
    # {#filter} filters messages before sending, and {#restore} restores
    # placeholders in the response.
    #
    # @example
    #   payload = Payload.new(messages)
    #   payload.filter
    #   # ... send to provider ...
    #   restored_content = payload.restore(response.content)
    class Payload
      # @param messages [Array<RubyLLM::Message>]
      def initialize(messages)
        @messages = messages
        @mapping = {}
      end

      # Filters sensitive content from messages in place using
      # {TopSecret::Text.filter_all} for consistent labels across turns.
      # @return [void]
      def filter
        filterable = @messages.reject { |msg| msg.content.nil? || msg.content.empty? }
        contents = filterable.map(&:content)
        batch_result = ::TopSecret::Text.filter_all(contents)

        filterable.zip(batch_result.items).each { |msg, item| msg.content = item.output }
        @mapping = batch_result.mapping
      end

      # Restores filtered placeholders in the response content with original
      # values. Handles both String and Hash (structured output) content.
      #
      # @param content [String, Hash] the response content to restore
      # @return [String, Hash] content with placeholders replaced
      def restore(content)
        if content.is_a?(Hash)
          json = JSON.generate(content)
          restored = ::TopSecret::FilteredText.restore(json, mapping: @mapping)
          JSON.parse(restored.output)
        else
          ::TopSecret::FilteredText.restore(content, mapping: @mapping).output
        end
      end
    end
  end
end
