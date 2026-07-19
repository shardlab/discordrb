# frozen_string_literal: true

module Discordrb
  # The locations of voice servers on Discord.
  class VoiceRegion
    # @return [String] the ID of the voice region.
    attr_reader :id

    # @return [String] the name of the voice region.
    attr_reader :name

    # @return [true, false] if the voice region is custom, e.g. for events.
    attr_reader :custom

    # @return [true, false] if the voice region is the closest to the client.
    attr_reader :optimal

    # @return [true, false] whether or not the voice region has been deprecated.
    attr_reader :deprecated

    alias_method :to_s, :id
    alias_method :custom?, :custom
    alias_method :optimal?, :optimal
    alias_method :deprecated?, :deprecated

    # @!visibility private
    def initialize(data)
      @id = data['id']
      @name = data['name']
      @custom = data['custom']
      @optimal = data['optimal']
      @deprecated = data['deprecated']
    end

    # @!visibility private
    def inspect
      "<VoiceRegion id=\"#{@id}\" name=\"#{@name}\" deprecated=#{@deprecated}>"
    end

    # @!method vip
    #   @deprecated This attribute no longer exists and will be removed in 4.0.
    #   @return [nil]
    # @!method sample_port
    #   @deprecated This attribute no longer exists and will be removed in 4.0.
    #   @return [nil]
    # @!method sample_hostname
    #   @deprecated This attribute no longer exists and will be removed in 4.0.
    #   @return [nil]
    %i[sample_hostname sample_port vip].each { |name| define_method(name) { nil } }
  end
end
