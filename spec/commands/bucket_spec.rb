# frozen_string_literal: true

require 'discordrb'

# TODO: Rework tests to not rely on multiple expectations
# rubocop:disable RSpec/MultipleExpectations
describe Discordrb::Commands::Bucket do
  describe 'rate_limited?' do
    shared_examples 'does not rate limit one request' do |bucket|
      it 'does not rate limit one request' do
        expect(bucket).not_to be_rate_limited(:a)
      end
    end

    include_examples 'does not rate limit one request', described_class.new(1, 5, 2)
    include_examples 'does not rate limit one request', described_class.new(nil, nil, 2)
    include_examples 'does not rate limit one request', described_class.new(1, 5, nil)
    include_examples 'does not rate limit one request', described_class.new(0, 1, nil)
    include_examples 'does not rate limit one request', described_class.new(0, 1_000_000_000, 500_000_000)

    it 'fails to initialize with invalid arguments' do
      expect { described_class.new(0, nil, 0) }.to raise_error(ArgumentError)
    end

    it 'fails to rate limit something invalid' do
      expect { described_class.new(1, 5, 2).rate_limited?("can't RL a string!") }.to raise_error(ArgumentError)
    end

    it 'rate limits one request over the limit' do
      b = described_class.new(1, 5, nil)
      expect(b).not_to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a)
    end

    it 'rate limits multiple requests that are over the limit' do
      b = described_class.new(3, 5, nil)
      expect(b).not_to be_rate_limited(:a)
      expect(b).not_to be_rate_limited(:a)
      expect(b).not_to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a)
    end

    it 'allows to be passed a custom increment' do
      b = described_class.new(5, 5, nil)
      expect(b).not_to be_rate_limited(:a, increment: 2)
      expect(b).not_to be_rate_limited(:a, increment: 2)
      expect(b).to be_rate_limited(:a, increment: 2)
    end

    it 'does not rate limit after the limit ran out' do
      b = described_class.new(2, 5, nil)
      expect(b).not_to be_rate_limited(:a)
      expect(b).not_to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a, Time.now + 4)
      expect(b).not_to be_rate_limited(:a, Time.now + 5)
    end

    it 'resets the limit after it runs out' do
      b = described_class.new(2, 5, nil)
      expect(b).not_to be_rate_limited(:a)
      expect(b).not_to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a)
      expect(b).not_to be_rate_limited(:a, Time.now + 5)
      expect(b).not_to be_rate_limited(:a, Time.now + 5.01)
      expect(b).to be_rate_limited(:a, Time.now + 5.02)
    end

    it 'rates the limit based on the delay' do
      b = described_class.new(nil, nil, 2)
      expect(b).not_to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a)
    end

    it 'does not rate limit after the delay runs out' do
      b = described_class.new(nil, nil, 2)
      expect(b).not_to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a)
      expect(b).not_to be_rate_limited(:a, Time.now + 2)
      expect(b).to be_rate_limited(:a, Time.now + 2)
      expect(b).not_to be_rate_limited(:a, Time.now + 4)
      expect(b).to be_rate_limited(:a, Time.now + 4)
    end

    it 'rate limits based on both the limit and the delay' do
      b = described_class.new(2, 5, 2)
      expect(b).not_to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a)
      expect(b).not_to be_rate_limited(:a, Time.now + 2)
      expect(b).to be_rate_limited(:a, Time.now + 2)
      expect(b).to be_rate_limited(:a, Time.now + 4)
      expect(b).not_to be_rate_limited(:a, Time.now + 5)
      expect(b).to be_rate_limited(:a, Time.now + 6)

      b = described_class.new(2, 5, 2)
      expect(b).not_to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a)
      expect(b).not_to be_rate_limited(:a, Time.now + 4)
      expect(b).to be_rate_limited(:a, Time.now + 4)
      expect(b).to be_rate_limited(:a, Time.now + 5)
    end

    it 'returns the correct number of times' do
      start_time = Time.now
      b = described_class.new(2, 5, 2)
      expect(b).not_to be_rate_limited(:a, start_time)
      expect(b.rate_limited?(:a, start_time).round(2)).to eq(2)
      expect(b.rate_limited?(:a, start_time + 1).round(2)).to eq(1)
      expect(b).not_to be_rate_limited(:a, start_time + 2.01)
      expect(b.rate_limited?(:a, start_time + 2).round(2)).to eq(3)
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
