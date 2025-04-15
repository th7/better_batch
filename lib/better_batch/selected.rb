# frozen_string_literal: true

require 'forwardable'

module BetterBatch
  class Selected
    extend Forwardable
    def_delegators :@inputs, :table_name, :input_columns, :column_types, :unique_columns, :primary_key, :returning

    ORDINAL = :better_batch_ordinal

    TEMPLATE = <<~SQL
      select %<selected_returning>s
       from rows from (
         jsonb_to_recordset($1)
         as (%<typed_columns_sql>s)
       ) with ordinality as input(%<input_columns_sql>s, %<ordinal>s)
       left join %<table_name>s
       using(%<query_columns_sql>s)
    SQL

    def initialize(inputs)
      @inputs = inputs
    end

    def sql
      params = { table_name:, primary_key:, selected_returning:, typed_columns_sql:, input_columns_sql:, ordinal: ORDINAL,
                 query_columns_sql: }
      format(TEMPLATE, **params)
    end

    private

    def selected_returning
      @selected_returning ||= qualified_columns.join(', ')
    end

    def remaining_columns
      @remaining_columns ||= returning - input_columns
    end

    def typed_columns_sql
      @typed_columns_sql ||= input_columns.map { |c| "#{c} #{column_types[c]}" }.join(', ')
    end

    def input_columns_sql
      @input_columns_sql ||= input_columns.join(', ')
    end

    def query_columns_sql
      @query_columns_sql ||= unique_columns.join(', ')
    end

    def prefix_table(parts)
      parts.map { |part| "#{table_name}.#{part}" }
    end

    def prefix_input(parts)
      parts.map { |part| "input.#{part}" }
    end

    def columns
      @columns ||= {
        primary_key: [primary_key],
        input_columns: input_columns - [primary_key],
        remaining_columns: returning - [primary_key] - input_columns,
        ordinal: ORDINAL
      }
    end

    def qualified_columns
      @qualified_columns ||= \
        prefix_table(columns.fetch(:primary_key)) +
        prefix_table(columns.fetch(:remaining_columns)) +
        prefix_input(columns.fetch(:input_columns)) +
        [columns.fetch(:ordinal)]
    end
  end
end
