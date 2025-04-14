module BetterBatch
  class Inserted
    TEMPLATE = <<~SQL
      insert into %<table_name>s (%<columns_text>s)
        select distinct on (%<query_columns_text>s)
          %<select_columns_text>s
        from selected
        where %<primary_key>s is null
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
      format(TEMPLATE, table_name:, primary_key:, columns_text:, query_columns_text:, select_columns_text:, returning_text:)
    end

    private

    attr_reader :table_name, :columns, :column_types, :unique_columns, :primary_key, :now_on_insert, :returning

    def columns_text
      @columns_text ||= (columns + now_on_insert).join(', ')
    end

    def select_columns_text
      @select_columns_text ||= (columns + now_as).join(', ')
    end

    # duped
    def query_columns_text
      @query_columns_text ||= unique_columns.join(', ')
    end

    def returning_text
      @returning_text ||= ((returning - columns) + unique_columns).join(', ')
    end

    def now_as
      @now_as ||= now_on_insert.map { |c| "now() as #{c}" }
    end
  end
end
