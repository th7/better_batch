# frozen_string_literal: true

require 'spec_util'

require 'anbt-sql-formatter/formatter'

require 'better_batch/query'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe BetterBatch::Query do
  let(:spec_util) { SpecUtil.new }
  let(:described_instance) { described_class.new(**spec_util.to_h) }
  let(:expected_query) { SpecUtil.format_sql(raw_expected_query) }

  let(:selected_double) { instance_double(BetterBatch::Selected, sql: 'STUB Selected#sql') }
  let(:inserted_double) { instance_double(BetterBatch::Inserted, sql: 'STUB Inserted#sql') }
  let(:updated_double) { instance_double(BetterBatch::Updated, sql: 'STUB Updated#sql') }

  before do
    # rubocop:disable RSpec/ExpectInHook
    allow(BetterBatch::Selected).to receive(:new) do |sub_args|
      expect(sub_args).to eq(described_instance.instance_variable_get(:@inputs))
      selected_double
    end
    allow(BetterBatch::Inserted).to receive(:new) do |sub_args|
      expect(sub_args).to eq(described_instance.instance_variable_get(:@inputs))
      inserted_double
    end
    allow(BetterBatch::Updated).to receive(:new) do |sub_args|
      expect(sub_args).to eq(described_instance.instance_variable_get(:@inputs))
      updated_double
    end
    # rubocop:enable RSpec/ExpectInHook
  end

  describe '#select' do
    subject { SpecUtil.format_sql(described_instance.select) }

    let(:raw_expected_query) do
      <<~SQL
        select the_primary_key
        from (STUB Selected#sql) selected
        order by better_batch_ordinal
      SQL
    end

    it('returns the select query') { is_expected.to eq(expected_query) }

    context 'more column types than needed are given' do
      before { spec_util.column_types.merge!(unneeded: 'type') }

      it('adds only used types to query') { is_expected.to eq(expected_query) }
    end

    context 'columns and column types are given in different order' do
      before { spec_util.reverse_column_types }

      it('orders types correctly in query') { is_expected.to eq(expected_query) }
    end

    context 'returning specific columns' do
      before { spec_util.returning << :other_column }

      let(:raw_expected_query) do
        <<~SQL
          select the_primary_key, other_column
          from (STUB Selected#sql) selected
          order by better_batch_ordinal
        SQL
      end

      it('returns the select query with more columns') { is_expected.to eq(expected_query) }
    end

    context 'returning all' do
      before { spec_util.returning = '*' }

      let(:raw_expected_query) do
        <<~SQL
          select the_primary_key, column_a, column_b, column_c, other_column, created_at, updated_at
          from (STUB Selected#sql) selected
          order by better_batch_ordinal
        SQL
      end

      it('returns all columns') { is_expected.to eq(expected_query) }
    end

    context 'returning none' do
      before { spec_util.returning = nil }

      let(:raw_expected_query) do
        <<~SQL
          select the_primary_key, column_a, column_b, column_c, other_column, created_at, updated_at
          from (STUB Selected#sql) selected
          order by better_batch_ordinal
        SQL
      end

      it('raises an error') do
        expect { subject }.to raise_error(BetterBatch::Error, 'Select query returning nothing is invalid.') # rubocop:disable RSpec/NamedSubject
      end
    end
  end

  describe '#upsert' do
    subject { SpecUtil.format_sql(described_instance.upsert) }

    let(:raw_expected_query) do
      <<-SQL
        with selected as (STUB Selected#sql)
        ,inserted as (STUB Inserted#sql)
        ,updated as (STUB Updated#sql)
        select coalesce(selected.the_primary_key, inserted.the_primary_key) as the_primary_key
        from selected
        left join inserted using(column_b, column_c)
        left join updated using(column_b, column_c)
        order by selected.better_batch_ordinal
      SQL
    end

    it('returns the full upsert query') { is_expected.to eq(expected_query) }

    context 'columns and unique_columns are the same' do
      before { spec_util.unique_columns = spec_util.input_columns }

      let(:raw_expected_query) do
        <<-SQL
          with selected as (STUB Selected#sql)
          ,inserted as (STUB Inserted#sql)
          select coalesce(selected.the_primary_key, inserted.the_primary_key) as the_primary_key
          from selected
          left join inserted using(column_a, column_b, column_c)
          order by selected.better_batch_ordinal
        SQL
      end

      it('omits update') { is_expected.to eq(expected_query) }
    end

    context 'returning all' do
      before { spec_util.returning = '*' }

      let(:raw_expected_query) do
        <<-SQL
          with selected as (STUB Selected#sql)
          ,inserted as (STUB Inserted#sql)
          ,updated as (STUB Updated#sql)
          select
            coalesce(selected.the_primary_key, inserted.the_primary_key) as the_primary_key,
            selected.column_a,
            selected.column_b,
            selected.column_c,
            selected.other_column,
            coalesce(selected.created_at, inserted.created_at) as created_at,
            coalesce(inserted.updated_at, updated.updated_at, selected.updated_at) as updated_at
          from selected
          left join inserted using(column_b, column_c)
          left join updated using(column_b, column_c)
          order by selected.better_batch_ordinal
        SQL
      end

      it('returns all columns') { is_expected.to eq(expected_query) }
    end

    context 'returning none' do
      before { spec_util.returning = nil }

      let(:raw_expected_query) do
        <<-SQL
          with selected as (STUB Selected#sql)
          ,inserted as (STUB Inserted#sql)
          ,updated as (STUB Updated#sql)
          select true as done
        SQL
      end

      it('returns no columns') { is_expected.to eq(expected_query) }
    end
  end

  describe '#returning' do
    subject { described_instance.returning }

    it { is_expected.to eq(spec_util.returning) }
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
