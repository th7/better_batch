require 'spec_util'

require 'better_batch/selected'

RSpec.describe BetterBatch::Selected do
  let(:spec_util) { SpecUtil.new }
  let(:described_instance) { described_class.new(**spec_util.args) }
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
      before { spec_util.column_types.merge!(unneeded: 'type') }
      it('does not add additional columns to query') { is_expected.to eq(expected_query) }
    end

    context 'columns and column types are given in different order' do
      before { spec_util.reverse_column_types }
      it('maintains correct column ordering') { is_expected.to eq(expected_query) }
    end

    context 'returning more columns' do
      before { spec_util.returning << :other_column }
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
  end
end
