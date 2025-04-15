require 'forwardable'

module BetterBatch
  class Inserted
    extend Forwardable
    def_delegators :@inputs, :table_name, :input_columns, :unique_columns, :primary_key, :now_on_insert, :returning

    TEMPLATE = <<~SQL
      insert into %<table_name>s (%<input_columns_sql>s)
        select distinct on (%<query_columns_sql>s)
          %<select_columns_sql>s
        from selected
        where %<primary_key>s is null
        %<returning_sql>s
    SQL

    def initialize(inputs)
      @inputs = inputs
    end

    def sql
      format(TEMPLATE, table_name:, primary_key:, input_columns_sql:, query_columns_sql:, select_columns_sql:, returning_sql:)
    end

    private

    def input_columns_sql
      @input_columns_sql ||= (input_columns + now_on_insert).join(', ')
    end

    def select_columns_sql
      @select_columns_sql ||= (input_columns + now_as).join(', ')
    end

    def query_columns_sql
      @query_columns_sql ||= unique_columns.join(', ')
    end

    def returning_sql
      @returning_sql ||= build_returning_sql
    end

    def build_returning_sql
      return '' if returning.empty?

      'returning ' + ((returning - input_columns) + unique_columns).join(', ')
    end

    def now_as
      @now_as ||= now_on_insert.map { |c| "now() as #{c}" }
    end
  end
end
