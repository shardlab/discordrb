# frozen_string_literal: true

require 'ffi'

module Discordrb::Voice
  # :nodoc:
  module DAVE
    extend FFI::Library

    class Error < StandardError; end
    class EncryptionError < Error; end

    libdave_path = ENV.fetch('DISCORDRB_LIBDAVE_PATH', nil)
    ffi_lib([libdave_path, 'dave', 'libdave', 'libdave.dylib', 'libdave.so'].compact)

    callback :mls_failure_callback, %i[string string pointer], :void
    callback :log_sink_callback, %i[int string int string], :void

    DAVE_CODEC_OPUS = 1
    DAVE_MEDIA_TYPE_AUDIO = 0
    DAVE_ENCRYPTOR_RESULT_CODE_SUCCESS = 0
    DAVE_LOGGING_SEVERITY_VERBOSE = 0
    DAVE_LOGGING_SEVERITY_INFO = 1
    DAVE_LOGGING_SEVERITY_WARNING = 2
    DAVE_LOGGING_SEVERITY_ERROR = 3
    DAVE_LOGGING_SEVERITY_NONE = 4

    attach_function :daveMaxSupportedProtocolVersion, [], :uint16
    attach_function :daveFree, [:pointer], :void
    attach_function :daveSessionCreate, %i[pointer string mls_failure_callback pointer], :pointer
    attach_function :daveSessionDestroy, [:pointer], :void
    attach_function :daveSessionInit, %i[pointer uint16 uint64 string], :void
    attach_function :daveSessionReset, [:pointer], :void
    attach_function :daveSessionSetProtocolVersion, %i[pointer uint16], :void
    attach_function :daveSessionGetProtocolVersion, [:pointer], :uint16
    attach_function :daveSessionSetExternalSender, %i[pointer pointer size_t], :void
    attach_function :daveSessionProcessProposals, %i[pointer pointer size_t pointer size_t pointer pointer], :void
    attach_function :daveSessionProcessCommit, %i[pointer pointer size_t], :pointer
    attach_function :daveSessionProcessWelcome, %i[pointer pointer size_t pointer size_t], :pointer
    attach_function :daveSessionGetMarshalledKeyPackage, %i[pointer pointer pointer], :void
    attach_function :daveSessionGetKeyRatchet, %i[pointer string], :pointer
    attach_function :daveKeyRatchetDestroy, [:pointer], :void
    attach_function :daveCommitResultIsFailed, [:pointer], :bool
    attach_function :daveCommitResultIsIgnored, [:pointer], :bool
    attach_function :daveCommitResultDestroy, [:pointer], :void
    attach_function :daveWelcomeResultDestroy, [:pointer], :void
    attach_function :daveEncryptorCreate, [], :pointer
    attach_function :daveEncryptorDestroy, [:pointer], :void
    attach_function :daveEncryptorSetKeyRatchet, %i[pointer pointer], :void
    attach_function :daveEncryptorSetPassthroughMode, %i[pointer bool], :void
    attach_function :daveEncryptorAssignSsrcToCodec, %i[pointer uint32 int], :void
    attach_function :daveEncryptorGetMaxCiphertextByteSize, %i[pointer int size_t], :size_t
    attach_function :daveEncryptorEncrypt, %i[pointer int uint32 pointer size_t pointer size_t pointer], :int
    attach_function :daveSetLogSinkCallback, [:log_sink_callback], :void

    class SessionHandle < FFI::AutoPointer # :nodoc:
      def self.release(ptr)
        DAVE.daveSessionDestroy(ptr)
      end
    end

    class CommitResultHandle < FFI::AutoPointer # :nodoc:
      def self.release(ptr)
        DAVE.daveCommitResultDestroy(ptr)
      end
    end

    class WelcomeResultHandle < FFI::AutoPointer # :nodoc:
      def self.release(ptr)
        DAVE.daveWelcomeResultDestroy(ptr)
      end
    end

    class KeyRatchetHandle < FFI::AutoPointer # :nodoc:
      def self.release(ptr)
        DAVE.daveKeyRatchetDestroy(ptr)
      end
    end

    class EncryptorHandle < FFI::AutoPointer # :nodoc:
      def self.release(ptr)
        DAVE.daveEncryptorDestroy(ptr)
      end
    end

    def self.max_supported_protocol_version
      daveMaxSupportedProtocolVersion
    end

    def self.log_level=(level)
      @log_level = normalize_log_level(level)
    end

    def self.log_level
      @log_level ||= normalize_log_level(ENV.fetch('DISCORDRB_LIBDAVE_LOG_LEVEL', 'warning'))
    end

    def self.install_log_sink!
      return if @log_sink_installed

      @log_sink_callback = proc do |severity, file, line, message|
        handle_log_message(severity, file, line, message)
      end
      daveSetLogSinkCallback(@log_sink_callback)
      @log_sink_installed = true
    end

    def self.normalize_log_level(level)
      {
        'verbose' => DAVE_LOGGING_SEVERITY_VERBOSE,
        'debug' => DAVE_LOGGING_SEVERITY_VERBOSE,
        'info' => DAVE_LOGGING_SEVERITY_INFO,
        'warn' => DAVE_LOGGING_SEVERITY_WARNING,
        'warning' => DAVE_LOGGING_SEVERITY_WARNING,
        'error' => DAVE_LOGGING_SEVERITY_ERROR,
        'none' => DAVE_LOGGING_SEVERITY_NONE,
        'silent' => DAVE_LOGGING_SEVERITY_NONE
      }.fetch(level.to_s.downcase, DAVE_LOGGING_SEVERITY_WARNING)
    end

    def self.handle_log_message(severity, file, line, message)
      return if severity < log_level

      logger = discordrb_logger
      return unless logger

      formatted_message = "DAVE: #{format_log_message(file, line, message)}"

      case severity
      when DAVE_LOGGING_SEVERITY_ERROR
        logger.error(formatted_message)
      when DAVE_LOGGING_SEVERITY_WARNING
        logger.warn(formatted_message)
      else
        logger.debug(formatted_message)
      end
    rescue StandardError
      nil
    end

    def self.format_log_message(_file, _line, message)
      message.to_s.strip
    end

    def self.discordrb_logger
      Discordrb::LOGGER if defined?(Discordrb::LOGGER)
    end

    def self.read_allocated_bytes
      buffer_ptr = FFI::MemoryPointer.new(:pointer)
      length_ptr = FFI::MemoryPointer.new(:size_t)
      yield buffer_ptr, length_ptr

      data_ptr = buffer_ptr.read_pointer
      return nil if data_ptr.null?

      data = data_ptr.read_string_length(length_ptr.read_ulong_long)
      daveFree(data_ptr)
      data
    end

    def self.write_bytes(bytes)
      return [FFI::Pointer::NULL, 0] if bytes.nil? || bytes.empty?

      pointer = FFI::MemoryPointer.new(:uint8, bytes.bytesize)
      pointer.put_bytes(0, bytes)
      [pointer, bytes.bytesize]
    end

    def self.write_string_array(values)
      values = Array(values)
      return [FFI::Pointer::NULL, [], 0] if values.empty?

      pointers = values.map { |value| FFI::MemoryPointer.from_string(value.to_s) }
      array = FFI::MemoryPointer.new(:pointer, pointers.length)
      pointers.each_with_index do |pointer, index|
        array.put_pointer(index * FFI.type_size(:pointer), pointer)
      end
      [array, pointers, pointers.length]
    end

    class CommitResult # :nodoc:
      def initialize(handle)
        @handle = CommitResultHandle.new(handle)
      end

      def failed?
        DAVE.daveCommitResultIsFailed(@handle)
      end

      def ignored?
        DAVE.daveCommitResultIsIgnored(@handle)
      end
    end

    class Session # :nodoc:
      attr_reader :self_user_id

      def initialize(protocol_version:, group_id:, self_user_id:, auth_session_id: nil, &failure_callback)
        @self_user_id = self_user_id.to_s
        @failure_callback = failure_callback || proc { |source, reason| raise Error, "#{source}: #{reason}" }
        @native_failure_callback = proc do |source, reason, _user_data|
          @failure_callback.call(source, reason)
        end

        handle = DAVE.daveSessionCreate(nil, auth_session_id, @native_failure_callback, nil)
        raise Error, 'Failed to create DAVE session' if handle.null?

        @handle = SessionHandle.new(handle)
        DAVE.daveSessionInit(@handle, protocol_version, group_id, @self_user_id)
      end

      def reset
        DAVE.daveSessionReset(@handle)
      end

      def protocol_version=(version)
        DAVE.daveSessionSetProtocolVersion(@handle, version)
      end

      def protocol_version
        DAVE.daveSessionGetProtocolVersion(@handle)
      end

      def external_sender=(payload)
        pointer, length = DAVE.write_bytes(payload)
        DAVE.daveSessionSetExternalSender(@handle, pointer, length)
      end

      def key_package
        DAVE.read_allocated_bytes do |buffer_ptr, length_ptr|
          DAVE.daveSessionGetMarshalledKeyPackage(@handle, buffer_ptr, length_ptr)
        end
      end

      def process_proposals(payload, recognized_user_ids)
        proposals_ptr, proposals_length = DAVE.write_bytes(payload)
        user_ids_ptr, _user_id_pointers, user_ids_length = DAVE.write_string_array(recognized_user_ids)

        DAVE.read_allocated_bytes do |buffer_ptr, length_ptr|
          DAVE.daveSessionProcessProposals(
            @handle,
            proposals_ptr,
            proposals_length,
            user_ids_ptr,
            user_ids_length,
            buffer_ptr,
            length_ptr
          )
        end
      end

      def process_commit(payload)
        commit_ptr, commit_length = DAVE.write_bytes(payload)
        handle = DAVE.daveSessionProcessCommit(@handle, commit_ptr, commit_length)
        raise Error, 'Failed to process DAVE commit' if handle.null?

        CommitResult.new(handle)
      end

      def process_welcome(payload, recognized_user_ids)
        welcome_ptr, welcome_length = DAVE.write_bytes(payload)
        user_ids_ptr, _user_id_pointers, user_ids_length = DAVE.write_string_array(recognized_user_ids)
        handle = DAVE.daveSessionProcessWelcome(@handle, welcome_ptr, welcome_length, user_ids_ptr, user_ids_length)
        raise Error, 'Failed to process DAVE welcome' if handle.null?

        WelcomeResultHandle.new(handle)
      end

      def key_ratchet(user_id = @self_user_id)
        handle = DAVE.daveSessionGetKeyRatchet(@handle, user_id.to_s)
        raise Error, "Failed to create DAVE key ratchet for user #{user_id}" if handle.null?

        KeyRatchetHandle.new(handle)
      end
    end

    class Encryptor # :nodoc:
      def initialize
        handle = DAVE.daveEncryptorCreate
        raise Error, 'Failed to create DAVE encryptor' if handle.null?

        @handle = EncryptorHandle.new(handle)
      end

      def key_ratchet=(key_ratchet)
        DAVE.daveEncryptorSetKeyRatchet(@handle, key_ratchet)
      end

      def passthrough_mode=(value)
        DAVE.daveEncryptorSetPassthroughMode(@handle, value)
      end

      def assign_audio_ssrc(ssrc)
        DAVE.daveEncryptorAssignSsrcToCodec(@handle, ssrc, DAVE_CODEC_OPUS)
      end

      def encrypt_audio_frame(ssrc, frame)
        frame_ptr, frame_length = DAVE.write_bytes(frame)
        max_size = DAVE.daveEncryptorGetMaxCiphertextByteSize(@handle, DAVE_MEDIA_TYPE_AUDIO, frame_length)
        output = FFI::MemoryPointer.new(:uint8, max_size)
        written = FFI::MemoryPointer.new(:size_t)

        result = DAVE.daveEncryptorEncrypt(
          @handle,
          DAVE_MEDIA_TYPE_AUDIO,
          ssrc,
          frame_ptr,
          frame_length,
          output,
          max_size,
          written
        )

        raise EncryptionError, "DAVE encryption failed with code #{result}" unless result == DAVE_ENCRYPTOR_RESULT_CODE_SUCCESS

        output.read_string_length(written.read_ulong_long)
      end
    end

    install_log_sink!
  end
end
