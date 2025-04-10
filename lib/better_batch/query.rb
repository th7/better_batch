# frozen_string_literal: true

module BetterBatch
  class Query # rubocop:disable Metrics/ClassLength
    SELECT_TEMPLATE = <<~SQL
      select id from (%<selected_inner>s)
      order by ordinal
    SQL

    UPSERT_TEMPLATE = <<~SQL
      with selected as (
        %<selected_inner>s
      )
      ,inserted as (
        %<inserted_inner>s
      )
      %<updated_clause>s
      select coalesce(selected.id, inserted.id) as id
      from selected left join inserted using(%<query_columns_text>s)
      order by selected.ordinal
    SQL

    SELECTED_INNER_TEMPLATE = <<~SQL
      select %<table_name>s.%<primary_key>s as id, %<input_columns_text>s, ordinal
       from rows from (
         jsonb_to_recordset($1)
         as (%<typed_columns_text>s)
       ) with ordinality as input(%<columns_text>s, ordinal)
       left join %<table_name>s
       using(%<query_columns_text>s)
    SQL

    INSERTED_INNER_TEMPLATE = <<~SQL
      insert into %<table_name>s (%<columns_text>s, created_at, updated_at)
        select distinct on (%<query_columns_text>s)
          %<columns_text>s, now() as created_at, now() as updated_at
        from selected
        where id is null
        returning id, %<query_columns_text>s
    SQL

    UPDATED_INNER_TEMPLATE = <<~SQL
      update %<table_name>s
      set %<update_columns_text>s, updated_at = now()
      from selected where %<table_name>s.id = selected.id
    SQL

    def initialize(table_name:, primary_key:, columns:, column_types:, unique_columns:)
      @table_name = table_name
      @primary_key = primary_key
      @columns = columns
      @column_types = column_types
      @unique_columns = unique_columns
    end

    def select
      format(SELECT_TEMPLATE, selected_inner:)
    end

    def upsert
      params = { selected_inner:, inserted_inner:, updated_clause:, query_columns_text: }
      format(UPSERT_TEMPLATE, **params)
    end

    private

    attr_reader :table_name, :columns, :column_types, :unique_columns, :primary_key

    def selected_inner
      @selected_inner ||= build_selected_inner
    end

    def build_selected_inner
      params = { table_name:, primary_key:, input_columns_text:, typed_columns_text:, columns_text:,
                 query_columns_text: }
      format(SELECTED_INNER_TEMPLATE, **params)
    end

    def inserted_inner
      @inserted_inner ||= build_inserted_inner
    end

    def build_inserted_inner
      format(INSERTED_INNER_TEMPLATE, table_name:, columns_text:, query_columns_text:)
    end

    def updated_clause
      @updated_clause ||= build_updated_clause
    end

    def build_updated_clause
      if update_columns.empty?
        "\n"
      else
        updated_clause_template = <<~SQL
          ,updated as (
            %<updated_inner>s
          )
        SQL
        format(updated_clause_template, updated_inner:)
      end
    end

    def updated_inner
      @updated_inner ||= build_updated_inner
    end

    def build_updated_inner
      format(UPDATED_INNER_TEMPLATE, table_name:, update_columns_text:)
    end

    def input_columns_text
      @input_columns_text ||= columns.map { |c| "input.#{c}" }.join(', ')
    end

    def typed_columns_text
      @typed_columns_text ||= column_types.map { |pair| pair.join(' ') }.join(', ')
    end

    def columns_text
      @columns_text ||= columns.join(', ')
    end

    def query_columns_text
      @query_columns_text ||= unique_columns.join(', ')
    end

    def update_columns
      @update_columns ||= columns - unique_columns
    end

    def update_columns_text
      @update_columns_text ||= update_columns.map { |c| "#{c} = selected.#{c}" }.join(', ')
    end
  end
end
