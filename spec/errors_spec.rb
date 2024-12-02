# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Errors do
  describe '.Code' do
    it 'creates a class without errors' do
      expect { described_class.Code(10_000) }.not_to raise_error
    end

    describe 'the created class' do
      it 'contains the correct code' do
        classy = described_class.Code(10_001)
        expect(classy.code).to eq(10_001)
      end

      # TODO: Rework test to not rely on multiple expectations
      # rubocop:disable RSpec/MultipleExpectations
      it 'creates an instance with the correct code' do
        classy = described_class.Code(10_002)
        error = classy.new 'random message'
        expect(error.code).to eq(10_002)
        expect(error.message).to eq 'random message'
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end

  describe 'error_class_for' do
    it 'returns the correct class for code 40001' do
      classy = described_class.error_class_for(40_001)
      expect(classy).to be(Discordrb::Errors::Unauthorized)
    end
  end

  describe Discordrb::Errors::Unauthorized do
    it 'exists' do
      expect(described_class).to be_a(Class)
    end

    it 'has the correct code' do
      instance = described_class.new('some message')
      expect(instance.code).to eq(40_001)
    end
  end
end
