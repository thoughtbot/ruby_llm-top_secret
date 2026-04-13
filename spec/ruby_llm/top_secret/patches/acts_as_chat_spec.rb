# frozen_string_literal: true

require_relative "../../../support/active_record"

RSpec.describe "acts_as_chat persistence" do
  let(:messages_url) { "https://api.anthropic.com/v1/messages" }

  before do
    stub_request(:post, messages_url)
      .to_return_json(body: {content: [{type: "text", text: "Hello [PERSON_1]"}]})
  end

  it "persists the rehydrated response in the database" do
    stub_filter_all(
      {"My name is Ralph" => "My name is [PERSON_1]"},
      labels: {PERSON_1: "Ralph"}
    )

    Model.find_or_create_by!(model_id: "model", name: "Model", provider: "anthropic")
    chat = Chat.create!(model: "model", provider: "anthropic", assume_model_exists: true)
    chat.ask("My name is Ralph")

    assistant_message = chat.messages.find_by(role: "assistant")
    expect(assistant_message.content).to eq("Hello Ralph")
  end

  private

  def stub_filter_all(mapping, labels: {})
    items = mapping.map do |input, output|
      TopSecret::Text::Result.new(input, output, {})
    end
    batch = TopSecret::Text::BatchResult.new(mapping: labels, items: items)

    @filter_all_responses ||= []
    @filter_all_responses << batch
    allow(TopSecret::Text).to receive(:filter_all).and_return(*@filter_all_responses)
  end
end
