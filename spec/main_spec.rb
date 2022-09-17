# frozen_string_literal: true

require 'discordrb'

class SimpleIDObject
  include Discordrb::IDObject

  def initialize(id)
    @id = id
  end
end

describe Discordrb do
  it 'splits messages correctly' do
    split = described_class.split_message('a' * 5234)
    expect(split).to eq(['a' * 2000, 'a' * 2000, 'a' * 1234])

    split_on_space = described_class.split_message("#{'a' * 1990} #{'b' * 2000}")
    expect(split_on_space).to eq(["#{'a' * 1990} ", 'b' * 2000])

    # regression test
    # there had been an issue where this would have raised an error,
    # and (if it hadn't raised) produced incorrect results
    split = described_class.split_message("#{'a' * 800}\n" * 6)
    expect(split).to eq([
                          "#{'a' * 800}\n#{'a' * 800}\n",
                          "#{'a' * 800}\n#{'a' * 800}\n",
                          "#{'a' * 800}\n#{'a' * 800}"
                        ])
  end

  describe Discordrb::IDObject do
    describe '#==' do
      it 'matches identical values' do
        ido = SimpleIDObject.new(123)
        expect(ido == SimpleIDObject.new(123)).to be(true)
        expect(ido == 123).to be(true)
        expect(ido == '123').to be(true)
      end

      it 'does not match different values' do
        ido = SimpleIDObject.new(123)
        expect(ido == SimpleIDObject.new(124)).to be(false)
        expect(ido == 124).to be(false)
        expect(ido == '124').to be(false)
      end
    end

    describe '#creation_time' do
      it 'returns the correct time' do
        ido = SimpleIDObject.new(175_928_847_299_117_063)
        time = Time.new(2016, 4, 30, 11, 18, 25.796, 0)
        expect(ido.creation_time.utc).to be_within(0.0001).of(time)
      end
    end

    describe '.synthesise' do
      it 'matches a precalculated time' do
        snowflake = 175_928_847_298_985_984
        time = Time.new(2016, 4, 30, 11, 18, 25.796, 0)
        expect(described_class.synthesise(time)).to eq(snowflake)
      end

      it 'matches #creation_time' do
        time = Time.new(2016, 4, 30, 11, 18, 25.796, 0)
        ido = SimpleIDObject.new(described_class.synthesise(time))
        expect(ido.creation_time).to be_within(0.0001).of(time)
      end
    end
  end
end
