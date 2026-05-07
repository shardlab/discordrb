# frozen_string_literal: true

require 'discordrb/voice/sodium'

describe Discordrb::Voice::Sodium do
  def rand_bytes(size)
    bytes = Array.new(size) { rand(256) }
    bytes.pack('C*')
  end

  describe Discordrb::Voice::XChaCha20AEAD do
    it 'encrypts round trip' do
      key = rand_bytes(Discordrb::Voice::XChaCha20AEAD::KEY_BYTES)
      nonce = rand_bytes(Discordrb::Voice::XChaCha20AEAD::NONCE_BYTES)
      message = rand_bytes(20)

      ct = Discordrb::Voice::XChaCha20AEAD.encrypt(message, '', nonce, key)
      pt = Discordrb::Voice::XChaCha20AEAD.decrypt(ct, '', nonce, key)
      expect(pt).to eq message
    end

    describe '#decrypt' do
      it 'raises on invalid nonce length' do
        rand_bytes(Discordrb::Voice::XChaCha20AEAD::KEY_BYTES)
        nonce = rand_bytes(Discordrb::Voice::XChaCha20AEAD::NONCE_BYTES - 1)
        expect { Discordrb::Voice::XChaCha20AEAD.decrypt(nonce, '') }.to raise_error(ArgumentError)
      end
    end
  end
end
