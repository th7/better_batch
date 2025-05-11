# frozen_string_literal: true

require 'better_batch/postgresql_reserved'

module BetterBatch
  class Word
    attr_reader :input, :hash

    def initialize(input)
      @input = input.to_sym
      @input_str = input.to_s.freeze
      downcased = @input_str.downcase
      @output = if POSTGRESQL_RESERVED.include?(downcased) || @input_str != downcased
                  "\"#{@input_str}\"".freeze
                else
                  @input_str
                end
      @hash = @input.hash
    end

    def to_s
      @output
    end

    def ==(other)
      case other
      when self.class
        input == other.input
      else
        raise "Did not know how to compare to #{other.inspect}."
      end
    end
    # needed for list subtraction and hash keys
    alias eql? ==

    def inspect
      "#<BetterBatch::Word @output=#{@output.inspect}>"
    end
  end
end
