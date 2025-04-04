module BetterBatch
  class Query
    def initialize(table_name:, primary_key:, columns:, column_types:, unique_columns:)
      @table_name = table_name
      @primary_key = primary_key
      @columns = columns
      @column_types = column_types
      @unique_columns = unique_columns
    end

    def select
      selected_inner
    end

    private

    attr_reader :table_name, :columns, :column_types, :unique_columns, :primary_key

    def selected_inner
      @selected_inner ||= build_selected_inner
    end

    def build_selected_inner
      selected_inner_template = <<~SQL
        select %<table_name>s.%<primary_key>s as id, %<input_columns_text>s, ordinal
         from rows from (
           jsonb_to_recordset($1)
           as (%<typed_columns_text>s)
         ) with ordinality as input(%<columns_text>s, ordinal)
         left join %<table_name>s
         using(%<query_columns_text>s)
      SQL
      format(selected_inner_template, table_name:, primary_key:, input_columns_text:, typed_columns_text:, columns_text:,
                                      query_columns_text:)
    end

    def input_columns_text
      @input_columns_text ||= columns.map { |c| "input.#{c}" }.join(', ')
    end

    def typed_columns_text
      @typed_columns_text ||= column_types.map { |pair| pair.join(' ') }.join(', ')
    end

    def columns_text
      @columns_text ||= columns.join(', ')
    end

    def query_columns_text
      @query_columns_text ||= unique_columns.join(', ')
    end
  end
end
