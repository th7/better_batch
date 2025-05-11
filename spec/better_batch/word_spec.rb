# frozen_string_literal: true

require 'better_batch/word'

RSpec.describe BetterBatch::Word do
  let(:described_instance) { described_class.new(input) }

  describe 'array subtraction' do
    let(:input) { 'something' }

    it 'is removed by a matching word' do
      expect([described_instance] - [described_class.new(input.to_sym)]).to eq([])
    end

    it 'does not get removed by a non-matching word' do
      expect([described_instance] - [described_class.new(:something_else)]).to eq([described_instance])
    end
  end

  describe 'hash keys' do
    let(:input) { 'something' }
    let(:hash) { { described_instance => :value } }

    it 'is treated as the same key as a matching word' do
      expect(hash[described_class.new(:something)]).to eq(:value)
    end
  end

  describe '#.to_s' do
    subject { described_instance.to_s }

    let(:input) { 'default' }

    it { is_expected.to be_frozen }

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

    context "same'ish input" do
      let(:input) { 'something' }
      let(:other_input) { :something }

      it { is_expected.to be(true) }
    end

    context 'different input' do
      let(:input) { 'something' }
      let(:other_input) { 'something_else' }

      it { is_expected.to be(false) }
    end
  end
end
