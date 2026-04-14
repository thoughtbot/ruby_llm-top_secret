# frozen_string_literal: true

module RubyLLM
  module TopSecret
    module Patches
      # Patch for {RubyLLM::ActiveRecord::ChatMethods#complete} that persists
      # the restored response content to the database.
      #
      # When filtering is active via {RubyLLM::TopSecret.with_filtering}
      # (or automatically via {ActsAsFilteredChat}), the default
      # persistence callback (+on_end_message+) fires inside
      # {Patches::Chat#complete} before restoration occurs, saving filtered
      # content. This patch updates the persisted assistant message with the
      # restored content afterward.
      #
      # @see Patches::Chat
      # @see ActsAsFilteredChat
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
