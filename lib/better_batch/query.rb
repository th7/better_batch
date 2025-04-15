# frozen_string_literal: true

require 'forwardable'

require 'anbt-sql-formatter/formatter'

require 'better_batch'
require 'better_batch/query/inputs'
require 'better_batch/selected'
require 'better_batch/inserted'
require 'better_batch/updated'

module BetterBatch
  class Query # rubocop:disable Metrics/ClassLength
    extend Forwardable

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

    UPSERT_NO_RETURN_TEMPLATE = <<~SQL
      with selected as (
        %<selected_inner>s
      )
      ,inserted as (
        %<inserted_inner>s
      )
      %<updated_clause>s
      select true as done
    SQL

    UPDATED_CLAUSE_TEMPLATE = <<~SQL
      ,updated as (
        %<updated_inner>s
      )
    SQL

    def initialize(**)
      @inputs = Inputs.new(**)
    end

    def select
      raise Error.new('Select query returning nothing is invalid.') if returning.empty?

      format(SELECT_TEMPLATE, selected_returning:, selected_inner:)
    end

    def select_formatted
      format_sql(select)
    end

    def upsert
      if returning.empty?
        upsert_no_return
      else
        upsert_normal
      end
    end

    def upsert_normal
      params = { selected_inner:, inserted_inner:, updated_clause:, upsert_returning:, primary_key:, query_columns_text:, updated_join_clause: }
      format(UPSERT_TEMPLATE, **params)
    end

    def upsert_no_return
      params = { selected_inner:, inserted_inner:, updated_clause: }
      format(UPSERT_NO_RETURN_TEMPLATE, **params)
    end

    def upsert_formatted
      format_sql(upsert)
    end

    def inspect
      @inputs.inspect
    end

    private

    def_delegators :@inputs, :table_name, :input_columns, :column_types, :unique_columns, :primary_key, :now_on_insert, :now_on_update, :returning

    def selected_returning
      @selected_returning ||= Array(returning).join(', ')
    end

    def selected_inner
      @selected_inner ||= build_selected_inner
    end

    def build_selected_inner
      Selected.new(@inputs).sql
    end

    def inserted_inner
      @inserted_inner ||= build_inserted_inner
    end

    def build_inserted_inner
      Inserted.new(@inputs).sql
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
      Updated.new(@inputs).sql
    end

    def upsert_returning
      returning.map do |col|
        if col == primary_key
          "coalesce(selected.#{col}, inserted.#{col}) as #{col}"
        elsif Array(now_on_insert).include?(col) && !Array(now_on_update).include?(col)#col == :created_at
          "coalesce(selected.#{col}, inserted.#{col}) as #{col}"
        elsif Array(now_on_insert).include?(col) && Array(now_on_update).include?(col)
          "coalesce(inserted.#{col}, updated.#{col}, selected.#{col}) as #{col}"
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
      @update_columns ||= input_columns - unique_columns
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
