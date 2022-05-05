# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Logger do
  it 'logs messages' do
    stream = spy
    logger = described_class.new(false, [stream])

    logger.error('Testing')

    expect(stream).to have_received(:puts).with(something_including('Testing'))
  end

  it 'respects the log mode' do
    stream = spy
    logger = described_class.new(false, [stream])
    logger.mode = :silent

    logger.error('Testing')

    expect(stream).not_to have_received(:puts)
  end

  context 'fancy mode' do
    it 'logs messages' do
      stream = spy
      logger = described_class.new(true, [stream])

      logger.error('Testing')

      expect(stream).to have_received(:puts).with(something_including('Testing'))
    end
  end

  context 'redacted token' do
    it 'redacts the token from messages' do
      stream = spy
      logger = described_class.new(true, [stream])
      logger.token = 'asdfg'

      logger.error('this message contains a token that should be redacted: asdfg')

      expect(stream).to have_received(:puts).with(something_not_including('asdfg'))
    end
  end
end
