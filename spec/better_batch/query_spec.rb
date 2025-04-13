# frozen_string_literal: true

require 'spec_util'

require 'anbt-sql-formatter/formatter'

require 'better_batch/query'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe BetterBatch::Query do
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
  let(:args) do
    {
      table_name:,
      primary_key:,
      columns:,
      column_types:,
      unique_columns:,
      returning:
    }
  end
  let(:sub_args) { args.merge(returning: returning || column_types.keys) }
  let(:described_instance) { described_class.new(**args) }
  let(:selected_double) { instance_double(BetterBatch::Selected, sql: 'STUB Selected#sql') }
  let(:inserted_double) { instance_double(BetterBatch::Inserted, sql: 'STUB Inserted#sql') }
  let(:updated_double) { instance_double(BetterBatch::Updated, sql: 'STUB Updated#sql') }
  let(:expected_query) { SpecUtil.format_sql(raw_expected_query) }

  before do
    allow(BetterBatch::Selected).to receive(:new).with(**sub_args).and_return(selected_double)
    allow(BetterBatch::Inserted).to receive(:new).with(**sub_args).and_return(inserted_double)
    allow(BetterBatch::Updated).to receive(:new).with(**sub_args).and_return(updated_double)
  end

  describe '#select' do
    subject { SpecUtil.format_sql(described_instance.select) }


    let(:raw_expected_query) do
      <<~SQL
        select the_primary_key from (
          STUB Selected#sql
        ) order by ordinal
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

    context 'returning specific columns' do
      let(:returning) { [primary_key, :other_column] }
      let(:raw_expected_query) do
        <<~SQL
          select the_primary_key, other_column from (
            STUB Selected#sql
          ) order by ordinal
        SQL
      end
      it('returns the select query with more columns') { is_expected.to eq(expected_query) }
    end

    context 'no return specified' do
      let(:returning) { nil }
      let(:raw_expected_query) do
        <<~SQL
          select the_primary_key, column_a, column_b, column_c from (
            STUB Selected#sql
          ) order by ordinal
        SQL
      end
      it('returns all columns') { is_expected.to eq(expected_query) }
    end
  end

  describe '#upsert' do
    subject { SpecUtil.format_sql(described_instance.upsert) }

    let(:raw_expected_query) do
      <<-SQL
        with selected as (
          STUB Selected#sql
        )
        ,inserted as (
          STUB Inserted#sql

        )
        ,updated as (
          STUB Updated#sql
        )
        select coalesce(selected.the_primary_key, inserted.the_primary_key)
        from selected left join inserted using(column_b, column_c)
        order by selected.ordinal
      SQL
    end

    it('returns the full upsert query') { is_expected.to eq(expected_query) }

    context 'columns and unique_columns are the same' do
      let(:unique_columns) { columns }
      let(:raw_expected_query) do
        <<-SQL
          with selected as (
            STUB Selected#sql
          )
          ,inserted as (
            STUB Inserted#sql
          )
          select coalesce(selected.the_primary_key, inserted.the_primary_key)
          from selected left join inserted using(column_a, column_b, column_c)
          order by selected.ordinal
        SQL
      end

      it('omits update') { is_expected.to eq(expected_query) }
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
