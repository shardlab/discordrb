# frozen_string_literal: true

require 'ffi'
require 'securerandom'

module Discordrb::Voice
  # @!visibility private
  module Sodium
    extend FFI::Library
    ffi_lib 'sodium'

    # @!group Constants

    # Initializes libsodium
    # @return [Integer] 0 on success
    attach_function :sodium_init, [], :int

    # Returns the key size (in bytes)
    # @return [Integer]
    attach_function :crypto_aead_xchacha20poly1305_ietf_keybytes, [], :size_t

    # Returns the nonce size (in bytes)
    # @return [Integer]
    attach_function :crypto_aead_xchacha20poly1305_ietf_npubbytes, [], :size_t

    # Returns the authentication tag size (in bytes)
    # @return [Integer]
    attach_function :crypto_aead_xchacha20poly1305_ietf_abytes, [], :size_t

    # @!endgroup

    # @!group AEAD Encrypt/Decrypt

    # Performs authenticated encryption using XChaCha20-Poly1305
    #
    # @param c [FFI::Pointer] output buffer for ciphertext
    # @param clen_p [FFI::Pointer] output pointer for ciphertext length
    # @param m [FFI::Pointer] input message pointer
    # @param mlen [Integer] length of the message
    # @param ad [FFI::Pointer] pointer to associated data
    # @param adlen [Integer] length of associated data
    # @param nsec [FFI::Pointer, nil] (not used, must be nil)
    # @param npub [FFI::Pointer] nonce pointer
    # @param k [FFI::Pointer] key pointer
    # @return [Integer] 0 on success
    attach_function :crypto_aead_xchacha20poly1305_ietf_encrypt, [
      :pointer, :pointer, :pointer, :ulong_long,
      :pointer, :ulong_long,
      :pointer, :pointer, :pointer
    ], :int

    # Decrypts XChaCha20-Poly1305 AEAD-encrypted data
    #
    # @param m [FFI::Pointer] output buffer for decrypted message
    # @param mlen_p [FFI::Pointer] output pointer for decrypted length
    # @param nsec [FFI::Pointer, nil] (not used, must be nil)
    # @param c [FFI::Pointer] ciphertext pointer
    # @param clen [Integer] length of ciphertext
    # @param ad [FFI::Pointer] pointer to associated data
    # @param adlen [Integer] length of associated data
    # @param npub [FFI::Pointer] nonce pointer
    # @param k [FFI::Pointer] key pointer
    # @return [Integer] 0 on success
    attach_function :crypto_aead_xchacha20poly1305_ietf_decrypt, [
      :pointer, :pointer, :pointer, :pointer, :ulong_long,
      :pointer, :ulong_long, :pointer, :pointer
    ], :int

    # @!endgroup
  end

  Sodium.sodium_init

  # High-level wrapper class
  class XChaCha20AEAD
    KEY_BYTES = Sodium.crypto_aead_xchacha20poly1305_ietf_keybytes
    NONCE_BYTES = Sodium.crypto_aead_xchacha20poly1305_ietf_npubbytes
    TAG_BYTES = Sodium.crypto_aead_xchacha20poly1305_ietf_abytes

    # Generates a random key
    # @return [String] binary key
    def self.generate_key
      SecureRandom.random_bytes(KEY_BYTES)
    end

    # Generates a random nonce
    # @return [String] binary nonce
    def self.generate_nonce
      SecureRandom.random_bytes(NONCE_BYTES)
    end

    # Encrypts a message using XChaCha20-Poly1305
    #
    # @param message [String] plaintext to encrypt
    # @param key [String] 32-byte encryption key
    # @param nonce [String] 24-byte nonce
    # @param ad [String] optional associated data
    # @return [String] ciphertext (includes the auth tag)
    def self.encrypt(message, ad, nonce, key)
      raise ArgumentError, "Invalid key size" unless key.bytesize == KEY_BYTES
      raise ArgumentError, "Invalid nonce size" unless nonce.bytesize == NONCE_BYTES

      message_ptr = FFI::MemoryPointer.from_string(message)
      ad_ptr = FFI::MemoryPointer.from_string(ad)

      c_len = message.bytesize + TAG_BYTES
      ciphertext = FFI::MemoryPointer.new(:uchar, c_len)
      clen_p = FFI::MemoryPointer.new(:ulong_long)

      result = Sodium.crypto_aead_xchacha20poly1305_ietf_encrypt(
        ciphertext, clen_p,
        message_ptr, message.bytesize,
        ad_ptr, ad.bytesize,
        nil,
        FFI::MemoryPointer.from_string(nonce),
        FFI::MemoryPointer.from_string(key)
      )

      raise "Encryption failed" unless result.zero?

      ciphertext.read_string(clen_p.read_ulong_long)
    end

    # Decrypts a ciphertext using XChaCha20-Poly1305
    #
    # @param ciphertext [String] the encrypted data (with tag)
    # @param key [String] 32-byte decryption key
    # @param nonce [String] 24-byte nonce
    # @param ad [String] optional associated data
    # @return [String] decrypted plaintext
    def self.decrypt(ciphertext, nonce, ad, key)
      raise ArgumentError, "Invalid key size" unless key.bytesize == KEY_BYTES
      raise ArgumentError, "Invalid nonce size" unless nonce.bytesize == NONCE_BYTES

      c_ptr = FFI::MemoryPointer.from_string(ciphertext)
      ad_ptr = FFI::MemoryPointer.from_string(ad)

      m_ptr = FFI::MemoryPointer.new(:uchar, ciphertext.bytesize - TAG_BYTES)
      mlen_p = FFI::MemoryPointer.new(:ulong_long)

      result = Sodium.crypto_aead_xchacha20poly1305_ietf_decrypt(
        m_ptr, mlen_p,
        nil,
        c_ptr, ciphertext.bytesize,
        ad_ptr, ad.bytesize,
        FFI::MemoryPointer.from_string(nonce),
        FFI::MemoryPointer.from_string(key)
      )

      raise "Decryption failed" unless result.zero?

      m_ptr.read_string(mlen_p.read_ulong_long)
    end
  end
end
