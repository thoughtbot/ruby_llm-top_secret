# frozen_string_literal: true

RSpec.describe RubyLLM::TopSecret::Patches::Chat do
  let(:messages_url) { "https://api.anthropic.com/v1/messages" }

  before do
    stub_request(:post, messages_url)
      .to_return_json(body: {content: [{type: "text", text: "Hello!"}]})
  end

  it "redacts sensitive content before sending to the provider" do
    stub_filter_all("My email is ralph@example.com" => "My email is [EMAIL_1]")

    chat = new_chat
    chat.ask("My email is ralph@example.com")

    expect(WebMock).to have_requested(:post, messages_url)
      .with { |req| req.body.include?("[EMAIL_1]") && !req.body.include?("ralph@example.com") }
  end

  it "redacts all messages in a multi-turn conversation" do
    stub_filter_all("My email is ralph@example.com" => "My email is [EMAIL_1]")
    stub_filter_all(
      "My email is ralph@example.com" => "My email is [EMAIL_1]",
      "Hello!" => "Hello!",
      "My SSN is 123-45-6789" => "My SSN is [SSN_1]"
    )

    chat = new_chat
    chat.ask("My email is ralph@example.com")
    chat.ask("My SSN is 123-45-6789")

    expect(WebMock).to have_requested(:post, messages_url).twice
      .with { |req| !req.body.include?("ralph@example.com") && !req.body.include?("123-45-6789") }
  end

  it "preserves original content in messages after the call" do
    stub_filter_all("My email is ralph@example.com" => "My email is [EMAIL_1]")

    chat = new_chat
    chat.ask("My email is ralph@example.com")

    user_message = chat.messages.find { |m| m.role == :user }
    expect(user_message.content).to eq("My email is ralph@example.com")
  end

  it "uses consistent labels for the same entity across messages" do
    stub_filter_all("My name is Ralph" => "My name is [PERSON_1]")
    stub_filter_all(
      "My name is Ralph" => "My name is [PERSON_1]",
      "Hello!" => "Hello!",
      "Ralph lives in Boston" => "[PERSON_1] lives in [LOCATION_1]"
    )

    chat = new_chat
    chat.ask("My name is Ralph")
    chat.ask("Ralph lives in Boston")

    expect(WebMock).to have_requested(:post, messages_url).twice
      .with { |req| req.body.include?("[PERSON_1]") && !req.body.include?("Ralph") }
  end

  private

  def new_chat
    RubyLLM.config.with(anthropic_api_key: "test-key") do
      RubyLLM::Chat.new(model: "model", assume_model_exists: true, provider: :anthropic)
    end
  end

  def stub_filter_all(mapping)
    items = mapping.map do |input, output|
      TopSecret::Text::Result.new(input, output, {})
    end
    batch = TopSecret::Text::BatchResult.new(mapping: {}, items: items)

    @filter_all_responses ||= []
    @filter_all_responses << batch
    allow(TopSecret::Text).to receive(:filter_all).and_return(*@filter_all_responses)
  end
end
