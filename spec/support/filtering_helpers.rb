# frozen_string_literal: true

module FilteringHelpers
  ANTHROPIC_MESSAGES_URL = "https://api.anthropic.com/v1/messages"

  def stub_filter_all(mapping, labels: {})
    items = mapping.map do |input, output|
      TopSecret::Text::Result.new(input, output, {})
    end
    batch = TopSecret::Text::BatchResult.new(mapping: labels, items: items)

    @filter_all_responses ||= []
    @filter_all_responses << batch
    allow(TopSecret::Text).to receive(:filter_all).and_return(*@filter_all_responses)
  end

  def stub_filter_by_replacing(replacements)
    allow(TopSecret::Text).to receive(:filter_all) do |contents|
      items = contents.map do |content|
        output = replacements.reduce(content) { |text, (value, label)| text.gsub(value, label) }
        TopSecret::Text::Result.new(content, output, {})
      end
      detected = replacements.select { |value, _| contents.any? { |content| content.include?(value) } }
      labels = detected.to_h { |value, label| [label.delete("[]").to_sym, value] }
      TopSecret::Text::BatchResult.new(mapping: labels, items: items)
    end
  end

  def stub_tool_loop
    stub_request(:post, ANTHROPIC_MESSAGES_URL).to_return(
      anthropic_response(
        content: [
          {type: "text", text: "Looking up [PERSON_1]"},
          {type: "tool_use", id: "toolu_1", name: "lookup", input: {}}
        ],
        stop_reason: "tool_use"
      ),
      anthropic_response(content: [{type: "text", text: "[PERSON_1] lives in Boston"}])
    )
  end

  private

  def anthropic_response(body)
    {status: 200, headers: {"Content-Type" => "application/json"}, body: body.to_json}
  end
end
