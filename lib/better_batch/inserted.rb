module BetterBatch
  class Inserted
    TEMPLATE = <<~SQL
      insert into %<table_name>s (%<columns_text>s, created_at, updated_at)
        select distinct on (%<query_columns_text>s)
          %<columns_text>s, now() as created_at, now() as updated_at
        from selected
        where %<primary_key>s is null
        returning %<primary_key>s, %<query_columns_text>s
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
      format(TEMPLATE, table_name:, primary_key:, columns_text:, query_columns_text:)
    end

    private

    attr_reader :table_name, :columns, :column_types, :unique_columns, :primary_key, :returning

    # def selected_inner_returning
    #   @selected_inner_returning ||= build_selected_inner_returning
    # end

    # def build_selected_inner_returning
    #   qualified_columns = ([primary_key] + returning - columns).uniq.zip([table_name].cycle).map do |col, table|
    #     "#{table}.#{col}"
    #   end
    #   qualified_columns.join(', ')
    # end

    # def input_columns_text
    #   @input_columns_text ||= columns.map { |c| "input.#{c}" }.join(', ')
    # end

    # def typed_columns_text
    #   @typed_columns_text ||= columns.map { |c| "#{c} #{column_types[c]}" }.join(', ')
    # end

    # duped
    def columns_text
      @columns_text ||= columns.join(', ')
    end

    # duped
    def query_columns_text
      @query_columns_text ||= unique_columns.join(', ')
    end
  end
end
