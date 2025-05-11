# frozen_string_literal: true

require 'better_batch/word'

RSpec.describe BetterBatch::Word do
  let(:described_instance) { described_class.new(input) }

  describe 'list subtraction' do
    let(:input) { 'something' }
    it 'will be removed by a matching symbol' do
      expect([described_instance] - [:something]).to eq([])
    end

    it 'will not be removed by a non-matching symbol' do
      expect([described_instance] - [:something_else]).to eq([described_instance])
    end
  end

  describe '#.to_s' do
    subject { described_instance.to_s }

    context 'matches a Postgres reserved word' do
      let(:input) { 'order' }

      it { is_expected.to eq('"order"') }
    end

    context 'includes capital letters' do
      let(:input) { 'SomeThing' }

      it { is_expected.to eq('"SomeThing"') }
    end

    context 'does not match a Postgres reserved word' do
      let(:input) { 'something' }

      it { is_expected.to eq('something') }
    end

    context 'input is a symbol' do
      let(:input) { :something }

      it { is_expected.to eq('something') }
    end
  end

  describe '#==' do
    subject { described_instance == other }

    let(:other) { described_class.new(other_input) }

    context 'same input' do
      let(:input) { 'something' }
      let(:other_input) { input }

      it { is_expected.to be(true) }
    end

    context 'different input' do
      let(:input) { 'something' }
      let(:other_input) { 'something_else' }

      it { is_expected.to be(false) }
    end

    context 'compared to string matching input' do
      let(:input) { 'something' }
      let(:other) { 'something' }

      it { is_expected.to be(true) }
    end

    context 'compared to symbol matching input' do
      let(:input) { 'something' }
      let(:other) { :something }

      it { is_expected.to be(true) }
    end
  end
end
