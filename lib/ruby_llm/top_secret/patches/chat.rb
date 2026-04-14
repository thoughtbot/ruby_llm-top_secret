# frozen_string_literal: true

module RubyLLM
  module TopSecret
    module Patches
      # Middleware that intercepts {RubyLLM::Chat#complete} to filter sensitive
      # information from messages before they are sent to the LLM provider,
      # and restore placeholders in the response with original values.
      #
      # Filtering only runs when opted in via {RubyLLM::TopSecret.with_filtering}.
      # Delegates to {Payload} for filtering and restoring content.
      # Original message content is preserved after the call via +ensure+.
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
        # @see RubyLLM::Chat#complete
        def complete(&)
          return super unless RubyLLM::TopSecret.filtering?

          originals = messages.to_h { |msg| [msg, msg.content] }

          payload = Payload.new(messages)
          payload.filter

          response = super

          response.content = payload.restore(response.content)

          response
        rescue RubyLLM::Error
          raise
        rescue => e
          raise RubyLLM::TopSecret::Error, e.message
        ensure
          originals&.each { |msg, content| msg.content = content }
        end
      end
    end
  end
end
