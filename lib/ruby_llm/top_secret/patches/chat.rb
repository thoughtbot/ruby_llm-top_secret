# frozen_string_literal: true

module RubyLLM
  module TopSecret
    module Patches
      # Middleware that intercepts {RubyLLM::Chat#generate}, the single
      # provider request behind +ask+ and +complete+, to filter sensitive
      # information from messages before they are sent to the LLM provider,
      # and restore placeholders in the response with original values.
      #
      # Filtering only runs when opted in via {RubyLLM::TopSecret.with_filtering}.
      # Delegates to {Payload} for filtering and restoring content.
      #
      # While the request runs, the chat holds filtered copies of its
      # messages, so anything wrapped inside this patch, such as tracing,
      # only sees placeholders. Afterwards the chat holds the original
      # messages again, followed by restored copies of the new ones.
      #
      # @raise [RubyLLM::TopSecret::Error] if filtering or restoring fails
      #
      # @example
      #   RubyLLM::TopSecret.with_filtering do
      #     chat = RubyLLM.chat
      #     chat.ask("My name is Ralph")
      #     # => Provider receives "My name is [PERSON_1]"
      #     # => Response "[PERSON_1] is a great name" becomes "Ralph is a great name"
      #   end
      module Chat
        # @return [Payload, nil] the payload of the request in flight, which
        #   {ActsAsChat} reads to persist restored content
        attr_reader :top_secret_payload

        # Only the outermost call filters when the patch is prepended more
        # than once, so instrumentation can sit between two copies of it.
        #
        # @see RubyLLM::Chat#generate
        def generate(&)
          return super if !RubyLLM::TopSecret.filtering? || top_secret_payload

          with_filtered_messages { super }
        end

        private

        def with_filtered_messages
          @top_secret_payload = Payload.new(messages)
          originals_by_copy = @top_secret_payload.filtered_messages.zip(messages).to_h
          @messages = originals_by_copy.keys

          response = yield

          restored = @messages.to_h { |msg| [msg, originals_by_copy.fetch(msg) { @top_secret_payload.restored(msg) }] }
          @messages = restored.values
          restored.fetch(response, response)
        rescue RubyLLM::Error
          raise
        rescue => e
          raise RubyLLM::TopSecret::Error, e.message
        ensure
          @messages = @messages.map { |msg| originals_by_copy.fetch(msg, msg) } if originals_by_copy
          @top_secret_payload = nil
        end
      end
    end
  end
end
