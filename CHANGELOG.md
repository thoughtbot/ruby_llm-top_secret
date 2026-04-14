## [Unreleased]

- Add `RubyLLM::TopSecret::Patches::Chat` middleware to filter sensitive information before sending to LLM providers
- Restore placeholders in provider responses with original values via `TopSecret::FilteredText.restore`
- Preserve original message content after provider calls
- Add `RubyLLM::TopSecret::Patches::ActsAsChat` to persist restored content when using `acts_as_chat`
- Add Railtie for automatic Rails integration
- Wrap filtering and restoring errors in `RubyLLM::TopSecret::Error`

## [0.1.0] - 2026-04-13

- Initial release
