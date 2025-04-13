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
        returning the_primary_key, column_b, column_c
      SQL
    end

    it('returns the insert query') { is_expected.to eq(expected_query) }
  end
end
