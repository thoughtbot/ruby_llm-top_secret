# frozen_string_literal: true

RSpec.describe RubyLLM::TopSecret::Patches::Chat do
  let(:messages_url) { "https://api.anthropic.com/v1/messages" }

  before do
    stub_request(:post, messages_url)
      .to_return_json(body: {content: [{type: "text", text: "Hello!"}]})
  end

  it "does not filter when not wrapped in with_filtering" do
    chat = new_chat
    chat.ask("My email is ralph@example.com")

    expect(WebMock).to have_requested(:post, messages_url)
      .with { |req| req.body.include?("ralph@example.com") }
  end

  it "filters sensitive content before sending to the provider" do
    stub_filter_all({"My email is ralph@example.com" => "My email is [EMAIL_1]"})

    RubyLLM::TopSecret.with_filtering do
      chat = new_chat
      chat.ask("My email is ralph@example.com")
    end

    expect(WebMock).to have_requested(:post, messages_url)
      .with { |req| req.body.include?("[EMAIL_1]") && !req.body.include?("ralph@example.com") }
  end

  it "filters all messages in a multi-turn conversation" do
    stub_filter_all({"My email is ralph@example.com" => "My email is [EMAIL_1]"})
    stub_filter_all({
      "My email is ralph@example.com" => "My email is [EMAIL_1]",
      "Hello!" => "Hello!",
      "My SSN is 123-45-6789" => "My SSN is [SSN_1]"
    })

    RubyLLM::TopSecret.with_filtering do
      chat = new_chat
      chat.ask("My email is ralph@example.com")
      chat.ask("My SSN is 123-45-6789")
    end

    expect(WebMock).to have_requested(:post, messages_url).twice
      .with { |req| !req.body.include?("ralph@example.com") && !req.body.include?("123-45-6789") }
  end

  it "preserves original content in messages after the call" do
    stub_filter_all({"My email is ralph@example.com" => "My email is [EMAIL_1]"})

    chat = new_chat
    RubyLLM::TopSecret.with_filtering do
      chat.ask("My email is ralph@example.com")
    end

    user_message = chat.messages.find { |m| m.role == :user }
    expect(user_message.content).to eq("My email is ralph@example.com")
  end

  it "skips empty messages when filtering" do
    stub_filter_all({"My email is ralph@example.com" => "My email is [EMAIL_1]"})

    chat = new_chat
    chat.messages << RubyLLM::Message.new(role: :assistant, content: nil)
    RubyLLM::TopSecret.with_filtering do
      chat.ask("My email is ralph@example.com")
    end

    expect(TopSecret::Text).to have_received(:filter_all)
      .with(["My email is ralph@example.com"])
  end

  it "restores placeholders in the response" do
    stub_request(:post, messages_url)
      .to_return_json(body: {content: [{type: "text", text: "Hello [PERSON_1]"}]})

    stub_filter_all(
      {"My name is Ralph" => "My name is [PERSON_1]"},
      labels: {PERSON_1: "Ralph"}
    )

    chat = new_chat
    response = RubyLLM::TopSecret.with_filtering do
      chat.ask("My name is Ralph")
    end

    expect(response.content).to eq("Hello Ralph")
  end

  it "passes through when no sensitive content is detected" do
    stub_filter_all({"Hi" => "Hi"})

    chat = new_chat
    response = RubyLLM::TopSecret.with_filtering do
      chat.ask("Hi")
    end

    expect(response.content).to eq("Hello!")
  end

  it "wraps filtering errors in RubyLLM::TopSecret::Error" do
    allow(TopSecret::Text).to receive(:filter_all).and_raise(StandardError, "NER model missing")

    chat = new_chat

    expect {
      RubyLLM::TopSecret.with_filtering { chat.ask("Hello") }
    }.to raise_error(RubyLLM::TopSecret::Error, /NER model missing/)
  end

  it "wraps restoring errors in RubyLLM::TopSecret::Error" do
    stub_filter_all(
      {"My name is Ralph" => "My name is [PERSON_1]"},
      labels: {PERSON_1: "Ralph"}
    )
    allow(TopSecret::FilteredText).to receive(:restore).and_raise(StandardError, "restore failed")

    chat = new_chat

    expect {
      RubyLLM::TopSecret.with_filtering { chat.ask("My name is Ralph") }
    }.to raise_error(RubyLLM::TopSecret::Error, /restore failed/)
  end

  it "restores values in structured output responses" do
    stub_request(:post, messages_url)
      .to_return_json(body: {content: [{type: "text", text: '{"name":"[PERSON_1]","city":"Boston"}'}]})

    stub_filter_all(
      {"Tell me about Ralph" => "Tell me about [PERSON_1]"},
      labels: {PERSON_1: "Ralph"}
    )

    schema = {
      name: "person",
      schema: {type: "object", properties: {name: {type: "string"}, city: {type: "string"}}}
    }

    chat = new_chat
    response = RubyLLM::TopSecret.with_filtering do
      chat.with_schema(schema).ask("Tell me about Ralph")
    end

    expect(response.content).to eq({"name" => "Ralph", "city" => "Boston"})
  end

  it "uses consistent labels for the same entity across messages" do
    stub_filter_all({"My name is Ralph" => "My name is [PERSON_1]"})
    stub_filter_all({
      "My name is Ralph" => "My name is [PERSON_1]",
      "Hello!" => "Hello!",
      "Ralph lives in Boston" => "[PERSON_1] lives in [LOCATION_1]"
    })

    RubyLLM::TopSecret.with_filtering do
      chat = new_chat
      chat.ask("My name is Ralph")
      chat.ask("Ralph lives in Boston")
    end

    expect(WebMock).to have_requested(:post, messages_url).twice
      .with { |req| req.body.include?("[PERSON_1]") && !req.body.include?("Ralph") }
  end

  private

  def new_chat
    RubyLLM.config.with(anthropic_api_key: "test-key") do
      RubyLLM::Chat.new(model: "model", assume_model_exists: true, provider: :anthropic)
    end
  end

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
