require 'better_batch/updated'

RSpec.describe BetterBatch::Updated do
  let(:spec_util) { SpecUtil.new }
  let(:described_instance) { described_class.new(**spec_util.args) }
  let(:expected_query) { SpecUtil.format_sql(raw_expected_query) }

  describe '#sql' do
    subject { SpecUtil.format_sql(described_instance.sql) }
    let(:raw_expected_query) do
      <<-SQL
        update the_table
        set column_a = selected.column_a, updated_at = now()
        from selected where the_table.the_primary_key = selected.the_primary_key
      SQL
    end

    it('returns update query') { is_expected.to eq(expected_query) }
  end
end
