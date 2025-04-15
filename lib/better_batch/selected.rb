require 'forwardable'

module BetterBatch
  class Selected
    extend Forwardable
    def_delegators :@inputs, :table_name, :input_columns, :column_types, :unique_columns, :primary_key, :returning

    TEMPLATE = <<~SQL
      select %<selected_returning>s
       from rows from (
         jsonb_to_recordset($1)
         as (%<typed_columns_sql>s)
       ) %<with_ordinality>s %<as_input>s
       left join %<table_name>s
       using(%<query_columns_sql>s)
    SQL

    def initialize(inputs)
      @inputs = inputs
    end

    def sql
      params = { table_name:, primary_key:, selected_returning:, typed_columns_sql:, with_ordinality:, as_input:,
                 query_columns_sql: }
      format(TEMPLATE, **params)
    end

    private

    def selected_returning
      @selected_returning ||= build_selected_returning
    end

    def build_selected_returning
      return ([qualified_pk] + qualifed_inputs).join(', ') if returning.empty?

      ([qualified_pk] + qualified_columns + qualifed_inputs + ['ordinal']).uniq.join(', ')
    end

    def qualified_pk
      "#{table_name}.#{primary_key}"
    end

    def qualified_columns
      (returning - input_columns).map do |col|
        "#{table_name}.#{col}"
      end
    end

    def qualifed_inputs
      @input_qualified_columns ||= input_columns.map { |c| "input.#{c}" }
    end

    def typed_columns_sql
      @typed_columns_sql ||= input_columns.map { |c| "#{c} #{column_types[c]}" }.join(', ')
    end

    def with_ordinality
      @with_ordinality ||= build_with_ordinality
    end

    def build_with_ordinality
      if returning.empty?
        ''
      else
        'with ordinality'
      end
    end

    def as_input
      @as_input ||= build_as_input
    end

    def build_as_input
      if returning.empty?
        "as input(#{columns_sql})"
      else
        "as input(#{columns_sql}, ordinal)"
      end
    end

    # duped
    def columns_sql
      @columns_sql ||= input_columns.join(', ')
    end

    # duped
    def query_columns_sql
      @query_columns_sql ||= unique_columns.join(', ')
    end
  end
end
