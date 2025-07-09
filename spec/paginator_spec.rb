# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Paginator do
  # TODO: Rework tests to not rely on multiple expectations
  # rubocop:disable RSpec/MultipleExpectations
  context 'when direction is down' do
    it 'requests all pages until empty' do
      data = [
        [1, 2, 3],
        [4, 5],
        [],
        [6, 7]
      ]

      index = 0
      paginator = described_class.new(nil, :down) do |last_page|
        expect(last_page).to eq data[index - 1] if last_page
        next_page = data[index]
        index += 1
        next_page
      end

      expect(paginator.to_a).to eq [1, 2, 3, 4, 5]
    end
  end

  context 'when direction is up' do
    it 'requests all pages until empty' do
      data = [
        [6, 7],
        [4, 5],
        [],
        [1, 2, 3]
      ]

      index = 0
      paginator = described_class.new(nil, :up) do |last_page|
        expect(last_page).to eq data[index - 1] if last_page
        next_page = data[index]
        index += 1
        next_page
      end

      expect(paginator.to_a).to eq [7, 6, 5, 4]
    end
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'only returns up to limit items' do
    data = [
      [1, 2, 3],
      [4, 5],
      []
    ]

    index = 0
    paginator = described_class.new(2, :down) do |_last_page|
      next_page = data[index]
      index += 1
      next_page
    end

    expect(paginator.to_a).to eq [1, 2]
  end
end
