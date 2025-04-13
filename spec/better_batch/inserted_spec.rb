require 'better_batch/inserted'

RSpec.describe BetterBatch::Inserted do
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
        insert into the_table (column_a, column_b, column_c, created_at, updated_at)
        select distinct on (column_b, column_c)
          column_a, column_b, column_c, now() as created_at, now() as updated_at
        from selected
        where the_primary_key is null
        returning the_primary_key, column_b, column_c
      SQL
    end

    it('returns the full upsert query') { is_expected.to eq(expected_query) }

    context 'columns and unique_columns are the same' do
      let(:unique_columns) { columns }
      let(:raw_expected_query) do
        <<-SQL
          insert into the_table (column_a, column_b, column_c, created_at, updated_at)
          select distinct on (column_a, column_b, column_c)
            column_a, column_b, column_c, now() as created_at, now() as updated_at
          from selected
          where the_primary_key is null
          returning the_primary_key, column_a, column_b, column_c
        SQL
      end

      it('returns the no update query') { is_expected.to eq(expected_query) }
    end
  end
end
