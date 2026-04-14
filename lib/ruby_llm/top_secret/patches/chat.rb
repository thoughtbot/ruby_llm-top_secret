# frozen_string_literal: true

module RubyLLM
  module TopSecret
    module Patches
      # Middleware that intercepts {RubyLLM::Chat#complete} to filter sensitive
      # information from all messages before they are sent to the LLM provider,
      # and restore placeholders in the response with original values.
      #
      # Delegates to {Payload} for filtering and restoring content.
      # Original message content is preserved after the call via +ensure+.
      #
      # @raise [RubyLLM::TopSecret::Error] if filtering or restoring fails
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
          originals.each { |msg, content| msg.content = content }
        end
      end
    end
  end
end
