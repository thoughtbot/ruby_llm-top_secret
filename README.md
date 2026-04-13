# RubyLLM::TopSecret

Filter sensitive information from [RubyLLM](https://rubyllm.com) conversations using [Top Secret](https://github.com/thoughtbot/top_secret).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "ruby_llm-top_secret", github: "thoughtbot/ruby_llm-top_secret", branch: "main"
```

Then run:

```bash
bundle install
```

## Usage

Requiring the gem automatically patches `RubyLLM::Chat` to filter sensitive information before it reaches the LLM provider, and restore placeholders in the response.

```ruby
chat = RubyLLM.chat
response = chat.ask("My name is Ralph and my email is ralph@thoughtbot.com")

# The provider receives: "My name is [PERSON_1] and my email is [EMAIL_1]"
# The response comes back with placeholders restored:
puts response.content
# => "Nice to meet you, Ralph!"
```

### How it works

1. Before sending to the provider, all messages are filtered using `TopSecret::Text.filter_all`
2. The provider only sees placeholders like `[PERSON_1]` and `[EMAIL_1]`
3. The response is restored using `TopSecret::FilteredText.restore`
4. Original message content is always preserved locally

### Rails integration

In Rails apps with `acts_as_chat`, the gem automatically patches the persistence layer via a Railtie. The restored response is what gets saved to your database.

```ruby
chat = Chat.create!(model: "claude-sonnet-4-5")
chat.ask("My name is Ralph")

assistant_message = chat.messages.find_by(role: "assistant")
puts assistant_message.content
# => "Nice to meet you, Ralph!" (not "Nice to meet you, [PERSON_1]!")
```

### Error handling

Errors from Top Secret (filtering or restoring failures) are wrapped in `RubyLLM::TopSecret::Error`. Errors from RubyLLM itself (API failures, etc.) are passed through unchanged.

```ruby
begin
  chat.ask("Hello")
rescue RubyLLM::TopSecret::Error => e
  # Top Secret failed (e.g., NER model missing)
rescue RubyLLM::Error => e
  # RubyLLM API error
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

See the [CONTRIBUTING] document.
Thank you, [contributors]!

[CONTRIBUTING]: CONTRIBUTING.md
[contributors]: https://github.com/thoughtbot/ruby_llm-top_secret/graphs/contributors

## License

ruby_llm-top_secret is Copyright (c) thoughtbot, inc.
It is free software, and may be redistributed
under the terms specified in the [LICENSE] file.

[LICENSE]: /LICENSE.txt

<!-- START /templates/footer.md -->
## About thoughtbot

![thoughtbot](https://thoughtbot.com/thoughtbot-logo-for-readmes.svg)

This repo is maintained and funded by thoughtbot, inc.
The names and logos for thoughtbot are trademarks of thoughtbot, inc.

We love open source software!
See [our other projects][community].
We are [available for hire][hire].

[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github

<!-- END /templates/footer.md -->
