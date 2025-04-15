# BetterBatch

BetterBatch is a SQL query builder that allows upserting batches of data to a database and always getting ids in the result in the order the data was given. Using a BetterBatch query makes working with your data easier and less error prone.

The gem requires lots of information about your database to build queries. I may create `better_batch-active_record` for a more streamlined interface, but you may still find this more direct example useful.

For now, only Postgres is supported.

## Installation

In your Gemfile:
```ruby
source 'https://rubygems.org'
gem 'better_batch'
```
Then:
`bundle`

## Usage

If you're using ActiveRecord, you'll want to use [better_batch-active_record](https://github.com/th7/better_batch-active_record).

```ruby
table_name = :the_table
primary_key = :the_primary_key
input_columns = %i[column_a column_b column_c]
column_types = {
  column_a: 'character varying(200)',
  column_b: 'bigint',
  column_c: 'text'
}
unique_columns = %i[column_b column_c]
now_on_insert = %i[created_at updated_at]
now_on_update = %i[updated_at]
returning = %i[id]
query = BetterBatch::Query.new(
  table_name:,
  primary_key:,
  input_columns:,
  column_types:,
  unique_columns:,
  now_on_insert:,
  now_on_update:,
  returning:
)

data = [
  { column_a: 'column_a data 1', column_b: 1, column_c: 'column_c data 1'},
  { column_a: 'column_a data 2', column_b: 2, column_c: 'column_c data 2'},
]
json_data = JSON.generate(data)
conn = PG.connect(dbname: 'mydb')
p conn.exec_params(query.select, [json_data]).values
p conn.exec_params(query.upsert, [json_data]).values
p conn.exec_params(query.select, [json_data]).values

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/th7/better_batch. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/th7/better_batch/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BetterBatch project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/th7/better_batch/blob/master/CODE_OF_CONDUCT.md).
