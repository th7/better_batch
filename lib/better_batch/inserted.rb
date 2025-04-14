require 'forwardable'

module BetterBatch
  class Inserted
    extend Forwardable

    TEMPLATE = <<~SQL
      insert into %<table_name>s (%<columns_text>s)
        select distinct on (%<query_columns_text>s)
          %<select_columns_text>s
        from selected
        where %<primary_key>s is null
        returning %<returning_text>s
    SQL

    def initialize(inputs)
      @inputs = inputs
    end

    def sql
      format(TEMPLATE, table_name:, primary_key:, columns_text:, query_columns_text:, select_columns_text:, returning_text:)
    end

    private

    def_delegators :@inputs, :table_name, :input_columns, :column_types, :unique_columns, :primary_key, :now_on_insert, :returning

    def columns_text
      @columns_text ||= (input_columns + now_on_insert).join(', ')
    end

    def select_columns_text
      @select_columns_text ||= (input_columns + now_as).join(', ')
    end

    # duped
    def query_columns_text
      @query_columns_text ||= unique_columns.join(', ')
    end

    def returning_text
      @returning_text ||= ((returning - input_columns) + unique_columns).join(', ')
    end

    def now_as
      @now_as ||= now_on_insert.map { |c| "now() as #{c}" }
    end
  end
end
