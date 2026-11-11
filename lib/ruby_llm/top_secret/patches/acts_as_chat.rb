# frozen_string_literal: true

module RubyLLM
  module TopSecret
    module Patches
      # Patch for {RubyLLM::ActiveRecord::ChatMethods} that persists restored
      # response content to the database.
      #
      # When filtering is active via {RubyLLM::TopSecret.with_filtering}
      # (or automatically via {ActsAsFilteredChat}), RubyLLM's +after_message+
      # persistence callback runs inside {Patches::Chat#generate} with the
      # filtered response. This patch restores the content RubyLLM saves
      # for each response, including every round of a tool loop.
      #
      # @see Patches::Chat
      # @see ActsAsFilteredChat
      module ActsAsChat
        private

        # @see RubyLLM::ActiveRecord::ChatMethods#message_attributes
        def message_attributes(message)
          attributes = super
          payload = to_llm.top_secret_payload
          return attributes if payload.nil? || attributes[:content].nil?

          attributes.merge(content: payload.restore(attributes[:content]))
        end
      end
    end
  end
end
