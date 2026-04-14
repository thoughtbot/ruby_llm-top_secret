# frozen_string_literal: true

require "active_support/concern"

module RubyLLM
  module TopSecret
    # Provides the +acts_as_filtered_chat+ class method for ActiveRecord
    # models that use +acts_as_chat+. Declaring it automatically wraps
    # +complete+ in {RubyLLM::TopSecret.with_filtering}, so filtering
    # works across job boundaries without a manual block.
    #
    # The gem does not provide a database column. Your application is
    # responsible for storing the per-chat filtering decision (e.g. a
    # +filtered+ boolean column) and exposing it via a predicate method.
    #
    # @example Filter all chats for this model
    #   class Chat < ApplicationRecord
    #     acts_as_chat
    #     acts_as_filtered_chat
    #   end
    #
    # @example Filter per-chat with a symbol condition
    #   class Chat < ApplicationRecord
    #     acts_as_chat
    #     acts_as_filtered_chat if: :filtered?
    #   end
    #
    # @example Filter per-chat with a Proc condition
    #   class Chat < ApplicationRecord
    #     acts_as_chat
    #     acts_as_filtered_chat if: -> { filtered? }
    #   end
    module ActsAsFilteredChat
      extend ActiveSupport::Concern

      class_methods do
        # Enables automatic filtering for this model's chat completions.
        #
        # @param options [Hash]
        # @option options [Symbol, Proc] :if A method name or lambda that
        #   determines whether filtering is active for a given chat instance.
        #   When omitted, all chats for this model are filtered.
        def acts_as_filtered_chat(**options)
          class_attribute :filter_condition, instance_writer: false
          self.filter_condition = options[:if]

          prepend AutoFiltering
        end
      end
    end

    # @api private
    module AutoFiltering
      def complete(...)
        condition = filter_condition
        should_filter = if condition
          case condition
          when Symbol then send(condition)
          when Proc then instance_exec(&condition)
          end
        else
          true
        end

        if should_filter
          RubyLLM::TopSecret.with_filtering { super }
        else
          super
        end
      end
    end
  end
end
