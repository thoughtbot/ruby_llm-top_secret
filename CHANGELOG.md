## [Unreleased]

- Support RubyLLM 2.x and drop RubyLLM 1.x. Stay on 0.1.0 for RubyLLM 1.x.
- Filter each provider request (`RubyLLM::Chat#generate`), so every round of a tool loop is filtered, including completions requested after `ask_later`.
- Filter copies of messages instead of changing them, since message content is read-only in RubyLLM 2.x.
- Persist restored content for every assistant message in a tool loop, written once instead of twice.
- Structured output is restored as JSON text. Read the Hash with `response.parsed`.

## [0.1.0] - 2026-04-14

- Initial release
