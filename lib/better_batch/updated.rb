module BetterBatch
  class Updated
    TEMPLATE = <<~SQL
      update %<table_name>s
      set %<update_columns_text>s, updated_at = now()
      from selected where %<table_name>s.%<primary_key>s = selected.%<primary_key>s
      returning %<table_name>s.%<primary_key>s, %<table_name>s.updated_at
    SQL

    def initialize(table_name:, primary_key:, columns:, column_types:, unique_columns:, returning:)
      @table_name = table_name
      @primary_key = primary_key
      @columns = columns
      @column_types = column_types
      @unique_columns = unique_columns
      @returning = returning.nil? ? @column_types.keys : returning
    end

    def sql
      format(TEMPLATE, table_name:, primary_key:, update_columns_text:)
    end

    private

    attr_reader :table_name, :columns, :column_types, :unique_columns, :primary_key, :returning

    def update_columns
      @update_columns ||= columns - unique_columns
    end

    def update_columns_text
      @update_columns_text ||= update_columns.map { |c| "#{c} = selected.#{c}" }.join(', ')
    end
  end
end
