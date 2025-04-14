require 'anbt-sql-formatter/formatter'

require 'better_batch/query'

class SpecUtil
  class << self
    # modified from
    # https://github.com/sonota88/anbt-sql-formatter/blob/main/bin/anbt-sql-formatter
    def format_sql(sql)
      rule = AnbtSql::Rule.new
      rule.keyword = AnbtSql::Rule::KEYWORD_LOWER_CASE
      rule.indent_string = '  '
      formatter = AnbtSql::Formatter.new(rule)
      formatter.format(sql)
    end

    def default_args
      {
        table_name: :the_table,
        primary_key:,
        input_columns: %i[column_a column_b column_c],
        column_types: {
          primary_key => 'bigint',
          column_a: 'character varying(200)',
          column_b: 'bigint',
          column_c: 'text',
          other_column: 'text',
          created_at: 'timestamp',
          updated_at: 'timestamp'
        },
        now_on_insert: %i[created_at updated_at],
        now_on_update: :updated_at,
        unique_columns: %i[column_b column_c],
        returning: [primary_key]
      }
    end

    private

    def primary_key
      :the_primary_key
    end
  end

  attr_reader :args

  def initialize
    @args = self.class.default_args
  end

  def inputs
    BetterBatch::Query.new(**args).instance_variable_get(:@inputs)
  end

  def column_types
    args.fetch(:column_types)
  end

  def returning
    args.fetch(:returning)
  end

  def input_columns
    args.fetch(:input_columns)
  end

  def unique_columns=(new_unique_columns)
    args[:unique_columns] = new_unique_columns
  end

  def reverse_column_types
    args[:column_types] = column_types.to_a.reverse.to_h
  end

  def returning=(new_returning)
    args[:returning] = new_returning
  end

  def primary_key
    args[:primary_key]
  end

  def now_on_insert=(new_now_on_insert)
    args[:now_on_insert] = new_now_on_insert
  end

  def now_on_update=(new_now_on_update)
    args[:now_on_update] = new_now_on_update
  end
end
