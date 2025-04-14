module BetterBatch
  class Inserted
    TEMPLATE = <<~SQL
      insert into %<table_name>s (%<columns_text>s, created_at, updated_at)
        select distinct on (%<query_columns_text>s)
          %<columns_text>s, now() as created_at, now() as updated_at
        from selected
        where %<primary_key>s is null
        returning %<returning_text>s
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
      format(TEMPLATE, table_name:, primary_key:, columns_text:, query_columns_text:, returning_text:)
    end

    private

    attr_reader :table_name, :columns, :column_types, :unique_columns, :primary_key, :returning

    # duped
    def columns_text
      @columns_text ||= columns.join(', ')
    end

    # duped
    def query_columns_text
      @query_columns_text ||= unique_columns.join(', ')
    end

    def returning_text
      @returning_text ||= ((returning - columns) + unique_columns).join(', ')
    end
  end
end
