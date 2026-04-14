# frozen_string_literal: true

RSpec.describe RubyLLM::TopSecret do
  it "has a version number" do
    expect(RubyLLM::TopSecret::VERSION).not_to be nil
  end

  describe ".with_filtering" do
    it "is not filtering after the block raises" do
      RubyLLM::TopSecret.with_filtering { raise "boom" }
    rescue
      nil
    ensure
      expect(RubyLLM::TopSecret).not_to be_filtering
    end

    it "preserves filtering when nested" do
      outer_filtering_after_inner = nil

      RubyLLM::TopSecret.with_filtering do
        RubyLLM::TopSecret.with_filtering do
          # inner block
        end
        outer_filtering_after_inner = RubyLLM::TopSecret.filtering?
      end

      expect(outer_filtering_after_inner).to be true
    end

    it "isolates filtering state to the current thread" do
      filtering_in_other_thread = nil

      RubyLLM::TopSecret.with_filtering do
        thread = Thread.new { filtering_in_other_thread = RubyLLM::TopSecret.filtering? }
        thread.join
      end

      expect(filtering_in_other_thread).to be false
    end
  end
end
