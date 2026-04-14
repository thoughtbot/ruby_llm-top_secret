# frozen_string_literal: true

module RubyLLM
  module TopSecret
    # Automatically prepends {Patches::ActsAsChat} onto
    # {RubyLLM::ActiveRecord::ChatMethods} after RubyLLM's own Railtie
    # has loaded the ActiveRecord integration.
    class Railtie < Rails::Railtie
      initializer "ruby_llm_top_secret.active_record", after: "ruby_llm.active_record" do
        ActiveSupport.on_load :active_record do
          require "ruby_llm/top_secret/patches/acts_as_chat"
          require "ruby_llm/top_secret/acts_as_filtered_chat"

          RubyLLM::ActiveRecord::ChatMethods.module_eval do
            prepend RubyLLM::TopSecret::Patches::ActsAsChat
          end

          ::ActiveRecord::Base.include RubyLLM::TopSecret::ActsAsFilteredChat
        end
      end
    end
  end
end
