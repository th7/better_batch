# frozen_string_literal: true

require 'anbt-sql-formatter/formatter'

require 'better_batch/query'
require 'better_batch/inputs'

class SpecUtil < BetterBatch::Inputs
  class << self
    PRIMARY_KEY = :the_primary_key
    DEFAULT_ARGS = {
      table_name: :the_table,
      primary_key: PRIMARY_KEY,
      input_columns: %i[column_a column_b column_c].freeze,
      column_types: {
        PRIMARY_KEY => 'bigint',
        column_a: 'character varying(200)',
        column_b: 'bigint',
        column_c: 'text',
        other_column: 'text',
        created_at: 'timestamp',
        updated_at: 'timestamp'
      }.freeze,
      now_on_insert: %i[created_at updated_at].freeze,
      now_on_update: :updated_at,
      unique_columns: %i[column_b column_c].freeze,
      returning: [PRIMARY_KEY].freeze
    }.freeze

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
      DEFAULT_ARGS.dup.transform_values(&:dup)
    end

    private

    def primary_key
      PRIMARY_KEY
    end
  end

  def initialize
    super(**self.class.default_args.dup)
  end

  def inputs
    BetterBatch::Query.new(**to_h).instance_variable_get(:@inputs)
  end

  def reverse_column_types
    self[:column_types] = column_types.to_a.reverse.to_h
  end
end
