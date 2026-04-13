## [Unreleased]

- Add `RubyLLM::TopSecret::Patches::Chat` middleware to redact sensitive information before sending to LLM providers
- Rehydrate placeholders in provider responses with original values via `TopSecret::FilteredText.restore`
- Preserve original message content after provider calls
- Add `RubyLLM::TopSecret::Patches::ActsAsChat` to persist rehydrated content when using `acts_as_chat`
- Add Railtie for automatic Rails integration
- Wrap redaction and rehydration errors in `RubyLLM::TopSecret::Error`

## [0.1.0] - 2026-04-13

- Initial release
