# frozen_string_literal: true

require 'forwardable'

require 'anbt-sql-formatter/formatter'

require 'better_batch'
require 'better_batch/inputs'
require 'better_batch/selected'
require 'better_batch/inserted'
require 'better_batch/updated'

module BetterBatch
  class Query # rubocop:disable Metrics/ClassLength
    extend Forwardable
    def_delegators :@inputs, :table_name, :input_columns, :column_types, :unique_columns, :primary_key, :now_on_insert, :now_on_update, :returning

    SELECT_TEMPLATE = <<~SQL
      select %<selected_returning>s
      from (%<selected_sql>s) selected
      order by %<ordinal>s
    SQL

    UPSERT_TEMPLATE = <<~SQL
      with %<with_sql>s
      select %<upsert_returning>s
      from selected
      %<join_sql>s
      order by selected.%<ordinal>s
    SQL

    UPSERT_NO_RETURN_TEMPLATE = <<~SQL
      with %<with_sql>s
      select true as done
    SQL

    def initialize(**)
      @inputs = Inputs.new(**)
    end

    def select
      raise Error.new('Select query returning nothing is invalid.') if returning.empty?

      format(SELECT_TEMPLATE, selected_returning:, selected_sql: selected.sql, ordinal: Selected::ORDINAL)
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

    def upsert_formatted
      format_sql(upsert)
    end

    def inspect
      @inputs.inspect
    end

    private

    def upsert_no_return
      format(UPSERT_NO_RETURN_TEMPLATE, with_sql:)
    end

    def upsert_normal
      params = { with_sql:, upsert_returning:, join_sql:, ordinal: Selected::ORDINAL }
      format(UPSERT_TEMPLATE, **params)
    end

    def with_sql
      @with_sql ||= build_with_sql
    end

    def build_with_sql
      with_parts.map { |name, sql| "#{name} as (#{sql})" }.join(', ')
    end

    def with_parts
      if update_columns.empty?
        { selected: selected.sql, inserted: inserted.sql }
      else
        { selected: selected.sql, inserted: inserted.sql, updated: updated.sql }
      end
    end

    def selected
      @selected ||= Selected.new(@inputs)
    end

    def inserted
      @inserted ||= Inserted.new(@inputs)
    end

    def updated
      @updated ||= Updated.new(@inputs)
    end

    def selected_returning
      @selected_returning ||= returning.join(', ')
    end

    def upsert_returning
      returning.map do |col|
        if col == primary_key
          "coalesce(selected.#{col}, inserted.#{col}) as #{col}"
        elsif now_on_insert.include?(col) && !now_on_update.include?(col)#col == :created_at
          "coalesce(selected.#{col}, inserted.#{col}) as #{col}"
        elsif now_on_insert.include?(col) && now_on_update.include?(col)
          "coalesce(inserted.#{col}, updated.#{col}, selected.#{col}) as #{col}"
        else
          "selected.#{col}"
        end
      end.join(', ')
    end

    def join_sql
      @join_sql ||= build_join_sql
    end

    def build_join_sql
      join_parts.map { |name| "left join #{name} #{using_sql}" }.join(' ')
    end

    def join_parts
      if update_columns.empty?
        [:inserted]
      else
        [:inserted, :updated]
      end
    end

    def using_sql
      "using (#{query_columns_text})"
    end

    def query_columns_text
      @query_columns_text ||= unique_columns.join(', ')
    end

    def update_columns
      @update_columns ||= input_columns - unique_columns
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
