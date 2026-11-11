# frozen_string_literal: true

module RubyLLM
  module TopSecret
    # Represents the sensitive content flowing between a RubyLLM chat and
    # the LLM provider. Mirrors Top Secret's own vocabulary:
    # {#filtered_messages} filters messages before sending, and {#restore}
    # restores placeholders in the response.
    #
    # Messages are never changed. {RubyLLM::Message#content} is read-only,
    # so {#filtered_messages} and {#restored} return copies.
    #
    # @example
    #   payload = Payload.new(messages)
    #   filtered = payload.filtered_messages
    #   # ... send filtered to provider ...
    #   payload.restored(response).content
    class Payload
      # @param messages [Array<RubyLLM::Message>]
      def initialize(messages)
        @messages = messages
        @mapping = {}
      end

      # Filters sensitive content using {TopSecret::Text.filter_all} for
      # consistent labels across turns.
      #
      # @return [Array<RubyLLM::Message>] the messages in the same order,
      #   with filtered copies in place of those that have content
      def filtered_messages
        filterable = @messages.reject { |msg| blank?(msg) }
        batch_result = ::TopSecret::Text.filter_all(filterable.map(&:content))
        @mapping = batch_result.mapping

        outputs = filterable.zip(batch_result.items.map(&:output)).to_h
        @messages.map { |msg| outputs.key?(msg) ? with_content(msg, outputs[msg]) : msg }
      end

      # Restores filtered placeholders with the original values. Structured
      # output is JSON text, so it restores the same way.
      #
      # @param content [String] content received while filtering
      # @return [String] content with placeholders replaced
      def restore(content)
        ::TopSecret::FilteredText.restore(content, mapping: @mapping).output
      end

      # @param message [RubyLLM::Message] a message received while filtering
      # @return [RubyLLM::Message] a copy with restored content
      def restored(message)
        blank?(message) ? message : with_content(message, restore(message.content))
      end

      private

      def blank?(message)
        message.content.nil? || message.content.empty?
      end

      def with_content(message, content)
        message.dup.tap do |copy|
          copy.instance_variable_set(:@content, content)
          copy.remove_instance_variable(:@parsed) if copy.instance_variable_defined?(:@parsed)
        end
      end
    end
  end
end
