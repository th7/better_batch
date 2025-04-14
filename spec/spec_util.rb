require 'anbt-sql-formatter/formatter'

require 'better_batch/query'
require 'better_batch/query/inputs'

class SpecUtil < BetterBatch::Query::Inputs
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

  def initialize
    super(**self.class.default_args)
  end

  def inputs
    BetterBatch::Query.new(**self.to_h).instance_variable_get(:@inputs)
  end

  def reverse_column_types
    self[:column_types] = self.column_types.to_a.reverse.to_h
  end
end
