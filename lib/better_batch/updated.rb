require 'forwardable'

module BetterBatch
  class Updated
    extend Forwardable
    def_delegators :@inputs, :table_name, :input_columns, :column_types, :unique_columns, :primary_key, :now_on_update, :returning

    TEMPLATE = <<~SQL
      update %<table_name>s
      set %<set_sql>s
      from selected where %<table_name>s.%<primary_key>s = selected.%<primary_key>s
      returning %<returning_sql>s
    SQL

    def initialize(inputs)
      @inputs = inputs
    end

    def sql
      format(TEMPLATE, table_name:, primary_key:, set_sql:, returning_sql:)
    end

    private


    def set_sql
      (update_columns_sql + now_as_sql).join(', ')
    end

    def update_columns
      @update_columns ||= input_columns - unique_columns
    end

    def update_columns_sql
      @update_columns_text ||= update_columns.map { |c| "#{c} = selected.#{c}" }
    end

    def now_as_sql
      @now_as_sql ||= Array(now_on_update).map { |c| "#{c} = now()" }
    end

    def returning_sql
      @returning_sql ||= (returning_cols).map { |c| "#{table_name}.#{c}" }.join(', ')
    end

    def returning_cols
      (returning - input_columns - now_on_update) + unique_columns + now_on_update
    end
  end
end
