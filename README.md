# RubyLLM::TopSecret

[![Ruby](https://github.com/thoughtbot/ruby_llm-top_secret/actions/workflows/main.yml/badge.svg)](https://github.com/thoughtbot/ruby_llm-top_secret/actions/workflows/main.yml)

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

Requiring the gem patches `RubyLLM::Chat` to support filtering sensitive information before it reaches the LLM provider. Filtering is opt-in per conversation using `with_filtering`.

```ruby
RubyLLM::TopSecret.with_filtering do
  chat = RubyLLM.chat
  response = chat.ask("My name is Ralph and my email is ralph@thoughtbot.com")

  # The provider receives: "My name is [PERSON_1] and my email is [EMAIL_1]"
  # The response comes back with placeholders restored:
  puts response.content
  # => "Nice to meet you, Ralph!"
end
```

Without `with_filtering`, conversations behave normally with no filtering overhead.

### How it works

1. Wrap your conversation in `RubyLLM::TopSecret.with_filtering`
2. Before sending to the provider, all messages are filtered using `TopSecret::Text.filter_all`
3. The provider only sees placeholders like `[PERSON_1]` and `[EMAIL_1]`
4. The response is restored using `TopSecret::FilteredText.restore`
5. Original message content is always preserved locally

Filtering state is thread-isolated, so concurrent requests in a web server won't interfere with each other.

### Rails integration

In Rails apps with `acts_as_chat`, declare `acts_as_filtered_chat` on your model so that filtering works automatically — including from background jobs where a `with_filtering` block isn't possible.

```ruby
class Chat < ApplicationRecord
  acts_as_chat
  acts_as_filtered_chat
end
```

Every call to `complete` on this model will filter automatically. The restored (not filtered) response is what gets saved to your database.

> [!NOTE]
> When filtering is active, the assistant message is written to the database twice — once by RubyLLM's built-in callback (with filtered placeholders), and again by this gem (with restored content). This is a known limitation of the current architecture.

#### Per-chat filtering

To control filtering per chat, pass an `if:` condition with a Symbol or Proc. The gem does not provide a database column — your application is responsible for storing the decision and exposing it via a method on the model.

1. Add a boolean column to your chats table

    ```
    rails generate migration AddFilteredToChats filtered:boolean
    ```

2. Pass `if: :filtered?` to `acts_as_chat`

    ```ruby
    class Chat < ApplicationRecord
      acts_as_chat
      acts_as_filtered_chat if: :filtered?
    end
    ```

> [!NOTE]
> The `if:` option follows the same convention as [Rails callbacks](https://guides.rubyonrails.org/active_record_callbacks.html#conditional-callbacks) — it accepts a Symbol (method name) or a Proc:

```ruby
acts_as_filtered_chat if: -> { filtered? }
```

### Error handling

Errors from Top Secret (filtering or restoring failures) are wrapped in `RubyLLM::TopSecret::Error`. Errors from RubyLLM itself (API failures, etc.) are passed through unchanged.

```ruby
RubyLLM::TopSecret.with_filtering do
  chat.ask("Hello")
rescue RubyLLM::TopSecret::Error => e
  # Top Secret failed (e.g., NER model missing)
rescue RubyLLM::Error => e
  # RubyLLM API error
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org)

## Contributing

[Bug reports](https://github.com/thoughtbot/ruby_llm-top_secret/issues/new?template=bug_report.md) and [pull requests](https://github.com/thoughtbot/ruby_llm-top_secret/pulls) are welcome on GitHub at [https://github.com/thoughtbot/ruby_llm-top_secret](https://github.com/thoughtbot/ruby_llm-top_secret).

Please create a [new discussion](https://github.com/thoughtbot/ruby_llm-top_secret/discussions/new?category=ideas) if you want to share ideas for new features.

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
