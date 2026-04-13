# frozen_string_literal: true

require "active_record"
require "ruby_llm/active_record/acts_as"
ActiveRecord::Base.include RubyLLM::ActiveRecord::ActsAs

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :chats do |t|
    t.timestamps
  end

  create_table :messages do |t|
    t.references :chat
    t.references :model
    t.string :role
    t.text :content
    t.integer :input_tokens
    t.integer :output_tokens
    t.timestamps
  end

  create_table :tool_calls do |t|
    t.references :message
    t.string :tool_call_id
    t.string :name
    t.json :arguments
    t.timestamps
  end

  create_table :models do |t|
    t.string :model_id
    t.string :name
    t.string :provider
    t.string :family
    t.integer :context_window
    t.integer :max_output_tokens
    t.json :capabilities
    t.json :modalities
    t.json :pricing
    t.json :metadata
    t.timestamps
  end

  add_reference :chats, :model
end

RubyLLM.configure do |config|
  config.anthropic_api_key = "test-key"
  config.use_new_acts_as = true
end

class Chat < ActiveRecord::Base
  acts_as_chat
end

class Message < ActiveRecord::Base
  acts_as_message
end

class ToolCall < ActiveRecord::Base
  acts_as_tool_call
end

class Model < ActiveRecord::Base
  acts_as_model
end

require "ruby_llm/top_secret/patches/acts_as_chat"

RubyLLM::ActiveRecord::ChatMethods.module_eval do
  prepend RubyLLM::TopSecret::Patches::ActsAsChat
end
