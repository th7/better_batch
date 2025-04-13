require 'spec_util'

RSpec.describe BetterBatch::Selected do
  let(:table_name) { :the_table }
  let(:primary_key) { :the_primary_key }
  let(:columns) { %i[column_a column_b column_c] }
  let(:base_column_types) do
    {
      primary_key => 'bigint',
      column_a: 'character varying(200)',
      column_b: 'bigint',
      column_c: 'text'
    }
  end
  let(:column_types) { base_column_types }
  let(:unique_columns) { %i[column_b column_c] }
  let(:returning) { [primary_key] }
  let(:described_instance) do
    described_class.new(
      table_name:,
      primary_key:,
      columns:,
      column_types:,
      unique_columns:,
      returning:
    )
  end
  let(:expected_query) { SpecUtil.format_sql(raw_expected_query) }

  describe '#sql' do
    subject { SpecUtil.format_sql(described_instance.sql) }

    let(:raw_expected_query) do
      <<~SQL
        select the_table.the_primary_key, input.column_a, input.column_b, input.column_c, ordinal
        from rows from (
          jsonb_to_recordset($1)
          as (column_a character varying(200), column_b bigint, column_c text)
        ) with ordinality as input(column_a, column_b, column_c, ordinal)
        left join the_table
        using(column_b, column_c)
      SQL
    end

    it('returns the select query') { is_expected.to eq(expected_query) }

    context 'more column types than needed are given' do
      let(:column_types) { base_column_types.merge(unneeded: 'type') }
      it('adds only used types to query') { is_expected.to eq(expected_query) }
    end

    context 'columns and column types are given in different order' do
      let(:column_types) { base_column_types.to_a.reverse.to_h }
      it('orders types correctly in query') { is_expected.to eq(expected_query) }
    end

    context 'returning more columns' do
      let(:returning) { [primary_key, :other_column] }
      let(:raw_expected_query) do
        <<~SQL
          select the_table.the_primary_key, the_table.other_column, input.column_a, input.column_b, input.column_c, ordinal
          from rows from (
            jsonb_to_recordset($1)
            as (column_a character varying(200), column_b bigint, column_c text)
          ) with ordinality as input(column_a, column_b, column_c, ordinal)
          left join the_table
          using(column_b, column_c)
        SQL
      end
      it('returns the select query with more columns') { is_expected.to eq(expected_query) }
    end

    context 'no return specified' do
      let(:returning) { nil }
      let(:raw_expected_query) do
        <<~SQL
          select the_table.the_primary_key, input.column_a, input.column_b, input.column_c, ordinal
          from rows from (
            jsonb_to_recordset($1)
            as (column_a character varying(200), column_b bigint, column_c text)
          ) with ordinality as input(column_a, column_b, column_c, ordinal)
          left join the_table
          using(column_b, column_c)
        SQL
      end
      it('returns all columns') { is_expected.to eq(expected_query) }
    end
  end
end
