require 'better_batch/inserted'

RSpec.describe BetterBatch::Inserted do
  let(:spec_util) { SpecUtil.new }
  let(:described_instance) { described_class.new(**spec_util.args) }
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
        returning the_primary_key
      SQL
    end

    it('returns the insert query') { is_expected.to eq(expected_query) }

    context 'no returning specified' do
      before { spec_util.returning = nil }
      let(:raw_expected_query) do
        <<-SQL
          insert into the_table (column_a, column_b, column_c, created_at, updated_at)
          select distinct on (column_b, column_c)
            column_a, column_b, column_c, now() as created_at, now() as updated_at
          from selected
          where the_primary_key is null
          returning the_primary_key, other_column, created_at, updated_at
        SQL
      end
      it('returns the insert query with all columns') { is_expected.to eq(expected_query) }
    end
  end
end
