# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Commands::Bucket do
  describe 'rate_limited?' do
    it 'does not rate limit one request' do
      expect(described_class.new(1, 5, 2)).not_to be_rate_limited(:a)
      expect(described_class.new(nil, nil, 2)).not_to be_rate_limited(:a)
      expect(described_class.new(1, 5, nil)).not_to be_rate_limited(:a)
      expect(described_class.new(0, 1, nil)).not_to be_rate_limited(:a)
      expect(described_class.new(0, 1_000_000_000, 500_000_000)).not_to be_rate_limited(:a)
    end

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

    it 'allows a custom increment to be passed' do
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

    it 'resets the limit after it ran out' do
      b = described_class.new(2, 5, nil)
      expect(b).not_to be_rate_limited(:a)
      expect(b).not_to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a)
      expect(b).not_to be_rate_limited(:a, Time.now + 5)
      expect(b).not_to be_rate_limited(:a, Time.now + 5.01)
      expect(b).to be_rate_limited(:a, Time.now + 5.02)
    end

    it 'rate limits based on delay' do
      b = described_class.new(nil, nil, 2)
      expect(b).not_to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a)
    end

    it 'does not rate limit after the delay ran out' do
      b = described_class.new(nil, nil, 2)
      expect(b).not_to be_rate_limited(:a)
      expect(b).to be_rate_limited(:a)
      expect(b).not_to be_rate_limited(:a, Time.now + 2)
      expect(b).to be_rate_limited(:a, Time.now + 2)
      expect(b).not_to be_rate_limited(:a, Time.now + 4)
      expect(b).to be_rate_limited(:a, Time.now + 4)
    end

    it 'rate limits based on both limit and delay' do
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

    it 'returns correct times' do
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
