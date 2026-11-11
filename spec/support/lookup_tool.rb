# frozen_string_literal: true

class LookupTool < RubyLLM::Tool
  description "Looks up where a person lives"

  def execute
    "Ralph lives in Boston"
  end
end
