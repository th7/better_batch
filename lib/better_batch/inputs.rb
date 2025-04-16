# frozen_string_literal: true

module BetterBatch
  Inputs = Struct.new(
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
      self[:column_types].transform_keys!(&:to_sym)
      preprocess_returning
      ensure_lists!
      symbolize_lists!
      symbolize!
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

    def symbolize_lists!
      %i[input_columns unique_columns now_on_insert now_on_update returning].each do |field|
        self[field].map!(&:to_sym)
      end
    end

    def symbolize!
      %i[table_name primary_key].each do |field|
        self[field] = self[field].to_sym
      end
    end
  end

  class Inputs
    prepend InstanceOverrides
  end
end
