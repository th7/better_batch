# frozen_string_literal: true

require 'anbt-sql-formatter/formatter'

require 'better_batch/selected'
require 'better_batch/inserted'
require 'better_batch/updated'

module BetterBatch
  class Query # rubocop:disable Metrics/ClassLength
    SELECT_TEMPLATE = <<~SQL
      select %<selected_returning>s from (%<selected_inner>s)
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
      select %<upsert_returning>s
      from selected
      left join inserted using(%<query_columns_text>s)
      %<updated_join_clause>s
      order by selected.ordinal
    SQL

    UPDATED_CLAUSE_TEMPLATE = <<~SQL
      ,updated as (
        %<updated_inner>s
      )
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

    def select
      format(SELECT_TEMPLATE, selected_returning:, selected_inner:)
    end

    def select_formatted
      format_sql(select)
    end

    def upsert
      params = { selected_inner:, inserted_inner:, updated_clause:, upsert_returning:, primary_key:, query_columns_text:, updated_join_clause: }
      format(UPSERT_TEMPLATE, **params)
    end

    def upsert_formatted
      format_sql(upsert)
    end

    def inspect
      vars = [
        :@table_name,
        :@primary_key,
        :@columns,
        :@column_types,
        :@unique_columns,
        :@returning
      ].map { |var| "#{var}=#{instance_variable_get(var).inspect}" }
      "#<#{self.class.name}:#{vars.join(', ')}>"
    end

    private

    attr_reader :table_name, :columns, :column_types, :unique_columns, :primary_key, :now_on_insert, :now_on_update, :returning

    def selected_returning
      @selected_returning ||= returning.join(', ')
    end

    def selected_inner
      @selected_inner ||= build_selected_inner
    end

    def build_selected_inner
      Selected.new(table_name:, primary_key:, columns:, column_types:, unique_columns:, now_on_insert:, now_on_update:, returning:).sql
    end

    def inserted_inner
      @inserted_inner ||= build_inserted_inner
    end

    def build_inserted_inner
      Inserted.new(table_name:, primary_key:, columns:, column_types:, unique_columns:, now_on_insert:, now_on_update:, returning:).sql
    end

    def updated_clause
      @updated_clause ||= build_updated_clause
    end

    def build_updated_clause
      return '' if update_columns.empty?

      format(UPDATED_CLAUSE_TEMPLATE, updated_inner:)
    end

    def updated_inner
      @updated_inner ||= build_updated_inner
    end

    def build_updated_inner
      Updated.new(table_name:, primary_key:, columns:, column_types:, unique_columns:, now_on_insert:, now_on_update:, returning:).sql
    end

    def upsert_returning
      returning.map do |col|
        if col == primary_key
          "coalesce(selected.#{col}, inserted.#{col})"
        elsif Array(now_on_insert).include?(col) && !Array(now_on_update).include?(col)#col == :created_at
          "coalesce(selected.#{col}, inserted.#{col})"
        elsif Array(now_on_insert).include?(col) && Array(now_on_update).include?(col)
          "coalesce(inserted.#{col}, updated.#{col}, selected.#{col})"
        else
          "selected.#{col}"
        end
      end.join(', ')
    end

    # duped Selected, Inserted
    def query_columns_text
      @query_columns_text ||= unique_columns.join(', ')
    end

    # duped Updated
    def update_columns
      @update_columns ||= columns - unique_columns
    end

    def updated_join_clause
      return '' if update_columns.empty?

      "left join updated using(#{query_columns_text})"
    end

    # modified from
    # https://github.com/sonota88/anbt-sql-formatter/blob/main/bin/anbt-sql-formatter
    def format_sql(src)
      rule = AnbtSql::Rule.new
      rule.keyword = AnbtSql::Rule::KEYWORD_LOWER_CASE
      rule.indent_string = '  '
      formatter = AnbtSql::Formatter.new(rule)
      formatter.format(src)
    end
  end
end
