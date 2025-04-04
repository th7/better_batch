require 'anbt-sql-formatter/formatter'

require 'better_batch/query'


RSpec.describe BetterBatch::Query do
  # modified from
  # https://github.com/sonota88/anbt-sql-formatter/blob/main/bin/anbt-sql-formatter
  def format_sql(src)
    rule = AnbtSql::Rule.new
    rule.keyword = AnbtSql::Rule::KEYWORD_LOWER_CASE
    # %w(count sum substr date).each{|func_name|
    #   rule.function_names << func_name.upcase
    # }
    rule.indent_string = "  "
    formatter = AnbtSql::Formatter.new(rule)
    formatter.format(src)
  end

  let(:table_name) { :the_table }
  let(:primary_key) { :the_primary_key }
  let(:columns) { %i[column_a column_b column_c] }
  let(:unique_columns) { %i[column_b column_c] }
  let(:column_types) do
    {
      column_a: 'character varying(200)',
      column_b: 'bigint',
      column_c: 'text'
    }
  end
  let(:described_instance) do
    described_class.new(
      table_name:,
      primary_key:,
      columns:,
      column_types:,
      unique_columns:
    )
  end
  let(:expected_query) { format_sql(raw_expected_query) }

  describe '#select' do
    subject { format_sql(described_instance.select) }

    let(:raw_expected_query) do
      <<~SQL
        select the_table.the_primary_key as id, input.column_a, input.column_b, input.column_c, ordinal
        from rows from (
          jsonb_to_recordset($1)
          as (column_a character varying(200), column_b bigint, column_c text)
        ) with ordinality as input(column_a, column_b, column_c, ordinal)
        left join the_table
        using(column_b, column_c)
      SQL
    end


    it 'returns the expected select query' do
      is_expected.to eq(expected_query)
    end
  end
end
