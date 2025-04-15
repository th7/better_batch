require 'spec_util'

require 'better_batch/inserted'

RSpec.describe BetterBatch::Inserted do
  let(:spec_util) { SpecUtil.new }
  let(:described_instance) { described_class.new(spec_util.inputs) }
  let(:expected_query) { SpecUtil.format_sql(raw_expected_query) }

  describe '#sql' do
    subject { SpecUtil.format_sql(described_instance.sql) }
    let(:raw_expected_query) do
      <<-SQL
        insert into the_table (column_a, column_b, column_c, created_at, updated_at)
        select distinct on (column_b, column_c)
          column_a, column_b, column_c, now() as created_at, now() as updated_at
        from selected
        where the_primary_key is null
        returning the_primary_key, column_b, column_c
      SQL
    end

    it('returns the insert query') { is_expected.to eq(expected_query) }

    context 'returning all' do
      before { spec_util.returning = '*' }
      let(:raw_expected_query) do
        <<-SQL
          insert into the_table (column_a, column_b, column_c, created_at, updated_at)
          select distinct on (column_b, column_c)
            column_a, column_b, column_c, now() as created_at, now() as updated_at
          from selected
          where the_primary_key is null
          returning the_primary_key, other_column, created_at, updated_at, column_b, column_c
        SQL
      end
      it('returns the insert query with all columns') { is_expected.to eq(expected_query) }
    end

    context 'returning none' do
      before { spec_util.returning = nil }
      let(:raw_expected_query) do
        <<-SQL
          insert into the_table (column_a, column_b, column_c, created_at, updated_at)
          select distinct on (column_b, column_c)
            column_a, column_b, column_c, now() as created_at, now() as updated_at
          from selected
          where the_primary_key is null
        SQL
      end
      it('returns the insert query with no return columns') { is_expected.to eq(expected_query) }
    end

    context 'no now_on_insert' do
      before do
        spec_util.now_on_insert = []
      end

      let(:raw_expected_query) do
        <<-SQL
          insert into the_table (column_a, column_b, column_c)
          select distinct on (column_b, column_c)
            column_a, column_b, column_c
          from selected
          where the_primary_key is null
          returning the_primary_key, column_b, column_c
        SQL
      end
      it('does not set any columns to now') { is_expected.to eq(expected_query) }
    end
  end
end
