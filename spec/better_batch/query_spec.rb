# frozen_string_literal: true

require 'anbt-sql-formatter/formatter'

require 'better_batch/query'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe BetterBatch::Query do
  # modified from
  # https://github.com/sonota88/anbt-sql-formatter/blob/main/bin/anbt-sql-formatter
  def format_sql(src)
    rule = AnbtSql::Rule.new
    rule.keyword = AnbtSql::Rule::KEYWORD_LOWER_CASE
    rule.indent_string = '  '
    formatter = AnbtSql::Formatter.new(rule)
    formatter.format(src)
  end

  let(:table_name) { :the_table }
  let(:primary_key) { :the_primary_key }
  let(:columns) { %i[column_a column_b column_c] }
  let(:unique_columns) { %i[column_b column_c] }
  let(:column_types) do
    {
      column_a: 'character varying(200)',
      column_b: 'bigint',
      column_c: 'text'
    }
  end
  let(:described_instance) do
    described_class.new(
      table_name:,
      primary_key:,
      columns:,
      column_types:,
      unique_columns:
    )
  end
  let(:expected_query) { format_sql(raw_expected_query) }

  describe '#select' do
    subject { format_sql(described_instance.select) }

    let(:raw_expected_query) do
      <<~SQL
        select id from (
          select the_table.the_primary_key as id, input.column_a, input.column_b, input.column_c, ordinal
          from rows from (
            jsonb_to_recordset($1)
            as (column_a character varying(200), column_b bigint, column_c text)
          ) with ordinality as input(column_a, column_b, column_c, ordinal)
          left join the_table
          using(column_b, column_c)
        ) order by ordinal
      SQL
    end

    it('returns the select query') { is_expected.to eq(expected_query) }
  end

  describe '#upsert' do
    subject { format_sql(described_instance.upsert) }

    let(:raw_expected_query) do
      <<-SQL
        with selected as (
          select the_table.the_primary_key as id, input.column_a, input.column_b, input.column_c, ordinal
          from rows from (
            jsonb_to_recordset($1)
            as (column_a character varying(200), column_b bigint, column_c text)
          ) with ordinality as input(column_a, column_b, column_c, ordinal)
          left join the_table
          using(column_b, column_c)
        )
        ,inserted as (
          insert into the_table (column_a, column_b, column_c, created_at, updated_at)
          select distinct on (column_b, column_c)
            column_a, column_b, column_c, now() as created_at, now() as updated_at
          from selected
          where id is null
          returning id, column_b, column_c

        )
        ,updated as (
          update the_table
          set column_a = selected.column_a, updated_at = now()
          from selected where the_table.id = selected.id
        )
        select coalesce(selected.id, inserted.id) as id
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
            select the_table.the_primary_key as id, input.column_a, input.column_b, input.column_c, ordinal
            from rows from (
              jsonb_to_recordset($1)
              as (column_a character varying(200), column_b bigint, column_c text)
            ) with ordinality as input(column_a, column_b, column_c, ordinal)
            left join the_table
            using(column_a, column_b, column_c)
          )
          ,inserted as (
            insert into the_table (column_a, column_b, column_c, created_at, updated_at)
            select distinct on (column_a, column_b, column_c)
              column_a, column_b, column_c, now() as created_at, now() as updated_at
            from selected
            where id is null
            returning id, column_a, column_b, column_c
          )
          select coalesce(selected.id, inserted.id) as id
          from selected left join inserted using(column_a, column_b, column_c)
          order by selected.ordinal
        SQL
      end

      it('returns the no update query') { is_expected.to eq(expected_query) }
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
