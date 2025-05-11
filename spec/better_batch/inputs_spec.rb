# frozen_string_literal: true

require 'spec_util'

require 'better_batch/inputs'
require 'better_batch/word'

RSpec.describe BetterBatch::Inputs do
  let(:spec_util) { SpecUtil.new }
  let(:described_instance) { described_class.new(**spec_util.to_h) }

  describe '#preprocess!' do
    [
      [
        %i[input_columns unique_columns now_on_insert now_on_update returning],
        [nil],
        []
      ],
      [
        %i[input_columns unique_columns now_on_insert now_on_update returning],
        [%w[a b c]],
        %w[a b c].map(&BetterBatch::Word.method(:new))
        # %i[a b c]
      ],
      [
        %i[input_columns unique_columns now_on_insert now_on_update returning],
        [:col], # :col is passed to test, not [:col]
        [:col].map(&BetterBatch::Word.method(:new))
      ],
      [
        %i[table_name primary_key],
        ['make_me_a_word'],
        BetterBatch::Word.new('make_me_a_word')
      ],
      [
        %i[column_types],
        [{ 'make_me_a_word' => 'anything' }],
        { BetterBatch::Word.new('make_me_a_word') => 'anything' }
      ],
      [
        %i[returning],
        ['*', ['*']],
        SpecUtil.new.column_types.keys.map(&BetterBatch::Word.method(:new))
      ]
    ].each do |fields, initials, expected|
      fields.each do |field|
        initials.each do |initial|
          it "converts #{field.inspect} from #{initial.inspect} to #{expected.inspect}" do
            described_instance[field] = initial.dup
            expect { described_instance.preprocess! }
              .to change { described_instance[field] }
              .from(initial).to(expected)
          end
        end
      end
    end
  end
end
