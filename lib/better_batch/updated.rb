module BetterBatch
  class Updated
    TEMPLATE = <<~SQL
      update %<table_name>s
      set %<set_sql>s
      from selected where %<table_name>s.%<primary_key>s = selected.%<primary_key>s
      returning %<returning_text>s
    SQL

    def initialize(table_name:, primary_key:, columns:, column_types:, unique_columns:, now_on_insert:, now_on_update:, returning:)
      @table_name = table_name
      @primary_key = primary_key
      @columns = columns
      @column_types = column_types
      @unique_columns = unique_columns
      @now_on_insert = now_on_insert
      @now_on_update = now_on_update
      @returning = returning.nil? ? @column_types.keys : returning
    end

    def sql
      format(TEMPLATE, table_name:, primary_key:, set_sql:, returning_text:)
    end

    private

    attr_reader :table_name, :columns, :column_types, :unique_columns, :primary_key, :now_on_update, :returning

    def set_sql
      (update_columns_sql + now_as_sql).join(', ')
    end

    def update_columns
      @update_columns ||= columns - unique_columns
    end

    def update_columns_sql
      @update_columns_text ||= update_columns.map { |c| "#{c} = selected.#{c}" }
    end

    def now_as_sql
      @now_as_sql ||= Array(now_on_update).map { |c| "#{c} = now()" }
    end

    def returning_text
      @returning_text ||= ((returning - columns) + unique_columns + Array(now_on_update)).map { |c| "#{table_name}.#{c}" }.join(', ')
    end
  end
end
