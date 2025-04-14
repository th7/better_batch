module BetterBatch
  class Query
    Inputs = Struct.new(
      :table_name,
      :input_columns,
      :column_types,
      :unique_columns,
      :primary_key,
      :now_on_insert,
      :now_on_update,
      :returning,
      keyword_init: true
    ) do
      def returning
        self[:returning] ||= column_types.keys
      end
    end
  end
end
