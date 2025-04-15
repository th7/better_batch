require 'spec_util'

RSpec.describe BetterBatch::Query::Inputs do
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
  end

  describe '#now_on_insert' do
    subject { described_instance.now_on_insert }

    context 'when nil' do
      before { described_instance.now_on_insert = nil }
      it { is_expected.to eq([]) }
    end
  end

  describe '#now_on_update' do
    subject { described_instance.now_on_update }

    context 'when nil' do
      before { described_instance.now_on_update = nil }
      it { is_expected.to eq([]) }
    end
  end
end
