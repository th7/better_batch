# frozen_string_literal: true

require 'better_batch/postgresql_reserved'

module BetterBatch
  class Word
    attr_reader :input

    def initialize(input)
      @input = input.to_s
      downcased = input.downcase
      @output = if POSTGRESQL_RESERVED.include?(downcased) || input != downcased
                  "\"#{@input}\""
                else
                  @input
                end
    end

    def to_s
      @output
    end

    def ==(other)
      case other
      when self.class
        input == other.input
      when String
        input == other
      when Symbol
        input == other.to_s
      else
        raise "Did not know how to compare to #{other.inspect}."
      end
    end

    # needed for list subtraction
    alias :eql? :==
  end
end
