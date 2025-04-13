require 'better_batch/updated'

RSpec.describe BetterBatch::Updated do
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
      <<-SQL
        update the_table
        set column_a = selected.column_a, updated_at = now()
        from selected where the_table.the_primary_key = selected.the_primary_key
      SQL
    end

    it('returns the full upsert query') { is_expected.to eq(expected_query) }
  end
end
