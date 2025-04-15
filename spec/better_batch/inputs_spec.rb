# frozen_string_literal: true

require 'spec_util'

require 'better_batch/inputs'

RSpec.describe BetterBatch::Inputs do
  let(:spec_util) { SpecUtil.new }
  let(:described_instance) { described_class.new(**spec_util.to_h) }

  describe '#returning' do
    subject { described_instance.returning }

    context 'when nil' do
      before { described_instance.returning = nil }

      it { is_expected.to eq([]) }
    end

    context 'when "*"' do
      before { described_instance.returning = '*' }

      it { is_expected.to eq(described_instance.column_types.keys) }
    end

    context 'when ["*"]' do
      before { described_instance.returning = ['*'] }

      it { is_expected.to eq(described_instance.column_types.keys) }
    end
  end

  describe '#now_on_insert' do
    subject { described_instance.now_on_insert }

    context 'when nil' do
      before { described_instance.now_on_insert = nil }

      it { is_expected.to eq([]) }
    end

    context 'when symbol' do
      before { described_instance.now_on_insert = :col }

      it { is_expected.to eq([:col]) }
    end
  end

  describe '#now_on_update' do
    subject { described_instance.now_on_update }

    context 'when nil' do
      before { described_instance.now_on_update = nil }

      it { is_expected.to eq([]) }
    end

    context 'when symbol' do
      before { described_instance.now_on_update = :col }

      it { is_expected.to eq([:col]) }
    end
  end
end
