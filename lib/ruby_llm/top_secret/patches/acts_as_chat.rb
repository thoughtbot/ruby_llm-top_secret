# frozen_string_literal: true

module RubyLLM
  module TopSecret
    module Patches
      # Patch for {RubyLLM::ActiveRecord::ChatMethods#complete} that persists
      # the rehydrated response content to the database.
      #
      # The default persistence callback (+on_end_message+) fires inside
      # {Patches::Chat#complete}, before rehydration occurs. This patch
      # updates the persisted assistant message with the restored content.
      #
      # @see Patches::Chat
      module ActsAsChat
        # @see RubyLLM::ActiveRecord::ChatMethods#complete
        def complete(...)
          response = super

          @message.update!(content: response.content)

          response
        end
      end
    end
  end
end
