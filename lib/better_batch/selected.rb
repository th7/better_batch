module BetterBatch
  class Selected
    TEMPLATE = <<~SQL
      select %<selected_inner_returning>s, %<input_columns_text>s, ordinal
       from rows from (
         jsonb_to_recordset($1)
         as (%<typed_columns_text>s)
       ) with ordinality as input(%<columns_text>s, ordinal)
       left join %<table_name>s
       using(%<query_columns_text>s)
    SQL

    def initialize(table_name:, primary_key:, input_columns:, column_types:, unique_columns:, now_on_insert:, now_on_update:, returning:)
      @table_name = table_name
      @primary_key = primary_key
      @input_columns = input_columns
      @column_types = column_types
      @unique_columns = unique_columns
      @returning = returning.nil? ? @column_types.keys : returning
    end

    def sql
      params = { table_name:, primary_key:, selected_inner_returning:, input_columns_text:, typed_columns_text:, columns_text:,
                 query_columns_text: }
      format(TEMPLATE, **params)
    end

    private

    attr_reader :table_name, :input_columns, :column_types, :unique_columns, :primary_key, :returning

    def selected_inner_returning
      @selected_inner_returning ||= build_selected_inner_returning
    end

    def build_selected_inner_returning
      p([primary_key] + returning - input_columns)
      qualified_columns = ([primary_key] + returning - input_columns).uniq.zip([table_name].cycle).map do |col, table|
        "#{table}.#{col}"
      end
      qualified_columns.join(', ')
    end

    def input_columns_text
      @input_columns_text ||= input_columns.map { |c| "input.#{c}" }.join(', ')
    end

    def typed_columns_text
      @typed_columns_text ||= input_columns.map { |c| "#{c} #{column_types[c]}" }.join(', ')
    end

    # duped
    def columns_text
      @columns_text ||= input_columns.join(', ')
    end

    # duped
    def query_columns_text
      @query_columns_text ||= unique_columns.join(', ')
    end
  end
end
