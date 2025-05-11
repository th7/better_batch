# frozen_string_literal: true

require 'better_batch/word'

module BetterBatch
  InputsStruct = Struct.new(
    :table_name,
    :primary_key,
    :input_columns,
    :column_types,
    :unique_columns,
    :now_on_insert,
    :now_on_update,
    :returning,
    keyword_init: true
  )

  # this strange (to me) setup avoids method redefinition warnings
  module InstanceOverrides
    def preprocess!
      self[:column_types].transform_keys!(&BetterBatch::Word.method(:new))
      preprocess_returning
      ensure_lists!
      to_word_lists!
      to_word!
    end

    private

    def preprocess_returning
      case self[:returning]
      when '*', ['*']
        self[:returning] = column_types.keys
      end
    end

    def ensure_lists!
      %i[input_columns unique_columns now_on_insert now_on_update returning].each do |field|
        self[field] = Array(self[field])
      end
    end

    def to_word_lists!
      %i[input_columns unique_columns now_on_insert now_on_update returning].each do |field|
        self[field].map! do |it|
          if it.is_a?(BetterBatch::Word)
            it
          else
            BetterBatch::Word.new(it)
          end
        end
      end
    end

    def to_word!
      %i[table_name primary_key].each do |field|
        self[field] = BetterBatch::Word.new(self[field])
      end
    end
  end

  class Inputs < InputsStruct
    prepend InstanceOverrides
  end
end
