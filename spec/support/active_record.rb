# frozen_string_literal: true

require "active_record"
require "rails"
require "ruby_llm/railtie"
require "ruby_llm/top_secret/railtie"

[RubyLLM::Railtie, RubyLLM::TopSecret::Railtie].each do |railtie|
  railtie.initializers.find { |initializer| initializer.name.end_with?(".active_record") }.run
end

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

# Mirrors the tables RubyLLM's install generator creates, covering every
# column from 2.0 through the latest 2.x so one schema serves each version.
ActiveRecord::Schema.define do
  create_table :ruby_llm_models do |t|
    t.string :model_id, null: false
    t.string :name, null: false
    t.string :provider, null: false
    t.string :family
    t.datetime :model_created_at
    t.integer :context_window
    t.integer :max_output_tokens
    t.date :knowledge_cutoff
    t.datetime :unlisted_at
    t.json :modalities, default: {}
    t.json :capabilities, default: []
    t.json :pricing, default: {}
    t.json :metadata, default: {}
    t.timestamps
    t.index [:provider, :model_id], unique: true
  end

  create_table :chats do |t|
    t.references :ruby_llm_model, null: false
    t.boolean :cancelled, null: false, default: false
    t.string :claim_token
    t.datetime :claimed_until
    t.timestamps
  end

  create_table :messages do |t|
    t.references :chat, null: false
    t.string :role, null: false
    t.text :content
    t.boolean :cache_until_here, null: false, default: false
    t.string :cache_ttl
    t.text :thinking_text
    t.text :thinking_signature
    t.json :citations
    t.json :server_tool_calls
    t.json :raw_content
    t.json :raw_reasoning
    t.string :phase
    t.text :continuation
    t.string :finish_reason
    t.timestamps
  end

  create_table :ruby_llm_tool_calls do |t|
    t.references :message, polymorphic: true, null: false
    t.references :result, polymorphic: true
    t.string :tool_call_id, null: false
    t.string :provider_call_id
    t.string :namespace
    t.string :name, null: false
    t.text :thought_signature
    t.string :approval
    t.boolean :remote, default: false, null: false
    t.datetime :claimed_until
    t.json :arguments, default: {}
    t.json :mcp_state
    t.json :mcp_result
    t.timestamps
    t.index :tool_call_id, unique: true
  end

  create_table :ruby_llm_usages do |t|
    t.references :chat, polymorphic: true
    t.references :message, polymorphic: true
    t.references :owner, polymorphic: true
    t.string :operation, null: false
    t.string :provider, null: false
    t.string :model, null: false
    t.string :status, null: false
    t.integer :input_tokens
    t.integer :output_tokens
    t.integer :cache_read_tokens
    t.integer :cache_write_tokens
    t.integer :thinking_tokens
    t.integer :characters
    t.decimal :audio_seconds, precision: 16, scale: 6
    t.integer :search_units
    t.json :server_tool_use
    t.decimal :input_cost, precision: 16, scale: 10
    t.decimal :output_cost, precision: 16, scale: 10
    t.decimal :cache_read_cost, precision: 16, scale: 10
    t.decimal :cache_write_cost, precision: 16, scale: 10
    t.decimal :thinking_cost, precision: 16, scale: 10
    t.decimal :characters_cost, precision: 16, scale: 10
    t.decimal :audio_seconds_cost, precision: 16, scale: 10
    t.decimal :search_units_cost, precision: 16, scale: 10
    t.decimal :total_cost, precision: 16, scale: 10
    t.string :workflow_id
    t.string :workflow_name
    t.string :workflow_step_id
    t.string :workflow_step_name
    t.timestamps
  end

  create_table :ruby_llm_queued_messages do |t|
    t.references :chat, polymorphic: true, null: false
    t.references :sender, polymorphic: true
    t.text :content
    t.boolean :steer, default: true, null: false
    t.timestamps
  end
end

RubyLLM.configure do |config|
  config.anthropic_api_key = "test-key"
end

class Chat < ActiveRecord::Base
  acts_as_chat
end

class Message < ActiveRecord::Base
  acts_as_message
end
