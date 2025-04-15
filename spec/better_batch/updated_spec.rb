require 'spec_util'

require 'better_batch/updated'

RSpec.describe BetterBatch::Updated do
  let(:spec_util) { SpecUtil.new }
  let(:described_instance) { described_class.new(spec_util.inputs) }
  let(:expected_query) { SpecUtil.format_sql(raw_expected_query) }

  describe '#sql' do
    subject { SpecUtil.format_sql(described_instance.sql) }
    let(:raw_expected_query) do
      <<-SQL
        update the_table
        set column_a = selected.column_a, updated_at = now()
        from selected
        where the_table.the_primary_key = selected.the_primary_key
        returning the_table.the_primary_key, the_table.column_b, the_table.column_c, the_table.updated_at
      SQL
    end

    it('returns update query') { is_expected.to eq(expected_query) }

    context 'updated_at is also returned explicitly' do
      before { spec_util.returning << :updated_at }
      it('does not duplicate in returning') { is_expected.to eq(expected_query) }
    end

    context 'no now_on_update' do
      before { spec_util.now_on_update = [] }
      let(:raw_expected_query) do
        <<-SQL
          update the_table
          set column_a = selected.column_a
          from selected
          where the_table.the_primary_key = selected.the_primary_key
          returning the_table.the_primary_key, the_table.column_b, the_table.column_c
        SQL
      end

      it('does not add the updated_at assignment') { is_expected.to eq(expected_query) }
    end
  end
end
