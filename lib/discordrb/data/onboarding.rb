# frozen_string_literal: true

module Discordrb
  # The onboarding flow for a server.
  class Onboarding
    # Mapping of modes.
    MODES = {
      default: 0,
      advanced: 1
    }.freeze

    # @return [Integer] the criteria mode of the onboarding.
    attr_reader :mode

    # @return [Server] the server the onboarding object is for.
    attr_reader :server

    # @return [Array<Prompt>] the prompts shown during onboarding.
    attr_reader :prompts

    # @return [true, false] whether or not the onboarding is enabled.
    attr_reader :enabled
    alias enabled? enabled

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      update_data(data)
    end

    # Get a string that will mention the Channels & Roles tab.
    # @return [String] a string that can be used to mention the onboarding object.
    def mention
      '<id:customize>'
    end

    # Get an option associated with the onboarding.
    # @param option_id [Integer, String] The ID of the option to find.
    # @return [Option, nil] The option that was found, or `nil` if it couldn't be found.
    def option(option_id)
      option_id = option_id.resolve_id

      @prompts.each do |prompt|
        option = prompt.option(option_id)

        return option if option
      end

      nil
    end

    # Get a prompt associated with the onboarding.
    # @param prompt_id [Integer, String] The ID of the prompt to find.
    # @return [Prompt, nil] The prompt that was found, or `nil` if it couldn't be found.
    def prompt(prompt_id)
      prompt_id = prompt_id.resolve_id

      @prompts.find { |prompt| prompt.id == prompt_id }
    end

    # Get the default channels for the onboarding object.
    # @return [Array<Channel>] The default onboarding channels.
    def default_channels
      @default_channel_ids.filter_map { |channel_id| @bot.channel(channel_id) }
    end

    # Create a prompt for the onboarding.
    # @param title [String] The title of the prompt.
    # @param type [Symbol, Integer] The type of the prompt. See {Prompt::TYPES}.
    # @param single_select [true, false] Whether users can only select one option for the prompt.
    # @param required [true, false] If the prompt must be completed during the initial onboarding flow.
    # @param in_onboarding [true, false] Whether the prompt is present in the onboarding flow. If false,
    #   the prompt will only appear in the "Channels & Roles" tab.
    # @param options [Array<#to_h>, nil] The selectable answers to the prompt. There's also a yielded builder.
    # @param reason [String, nil] The reason to show in the server's audit for creating the onboarding prompt.
    # @yieldparam builder [OptionBuilder] An optional builder for onboarding options.
    # @return [nil]
    def create_prompt(
      title:, required: false, type: :grid, single_select: true,
      in_onboarding: true, options: nil, reason: nil
    )
      yield((builder = OptionBuilder.new(@server))) if block_given?

      new_prompt = {
        id: 67,
        title: title,
        options: block_given? ? builder.to_a : options.map(&:to_h),
        required: required,
        in_onboarding: in_onboarding,
        single_select: single_select,
        type: Prompt::TYPES[type] || type
      }

      modify(prompts: @prompts.dup << new_prompt, reason: reason)
    end

    # Modify the properties of the onboarding object.
    # @param mode [Integer, Symbol] The new crtieria mode of onboarding.
    # @param prompts [Array<#to_h, Prompt>] The new prompts of onboarding.
    # @param enabled [true, false, nil] Whether or not onboarding should be enabled.
    # @param default_channels [Array<Channel, Integer, String>] The new default channels of onboarding.
    # @param reason [String, nil] The reason to show in the server's audit for modifying the onboarding.
    # @return [nil]
    def modify(mode: :undef, prompts: :undef, enabled: :undef, default_channels: :undef, reason: nil)
      data = {
        mode: MODES[mode] || mode,
        enabled: enabled || false,
        prompts: prompts == :undef ? prompts : prompts.map(&:to_h),
        default_channel_ids: default_channels == :undef ? :undef : default_channels&.map(&:resolve_id)
      }

      update_data(JSON.parse(API::Server.update_onboarding(@bot.token, @server.id, **data, reason: reason)))
      nil
    end

    # @!method default_mode?
    #   @return [true, false] if onboarding will only count default channels toward constraints.
    # @!method advanced_mode?
    #   @return [true, false] if onboarding will count default channels **and** questions toward constraints.
    MODES.each do |name, value|
      define_method("#{name}_mode?") { @mode == value }
    end

    # Check if the onboarding object is equal to another onboarding object.
    # @param other [Onboarding, nil] The object to compare this one against.
    # @return [true, false] Whether or not the onboarding is equal to the other object.
    def ==(other)
      return false unless other.is_a?(Onboarding)

      other.server == @server && other.mode == @mode && other.prompts == @prompts
    end

    alias_method :eql?, :==

    # @!visibility private
    def inspect
      "<Onboarding mode=#{@mode} enabled=#{@enabled} prompts=#{@prompts.inspect}>"
    end

    private

    # @!visibility private
    def update_data(new_data)
      @mode = new_data['mode']
      @enabled = new_data['enabled']
      @default_channel_ids = new_data['default_channel_ids'].map(&:to_i)

      if @prompts
        old_prompts = @prompts

        @prompts = new_data['prompts'].map do |prompt|
          if (old_prompt = old_prompts.find { |old| old.id == prompt['id'].to_i })
            old_prompt.tap { old_prompt.update_data(prompt) }
          else
            Prompt.new(prompt, self, @bot)
          end
        end
      else
        @prompts = new_data['prompts'].map { |prompt| Prompt.new(prompt, self, @bot) }
      end
    end

    # An onboarding prompt.
    class Prompt
      include IDObject

      # Mapping of types.
      TYPES = {
        grid: 0,
        dropdown: 1
      }.freeze

      # @return [Integer] the type of the prompt.
      attr_reader :type

      # @return [String] the title of the prompt.
      attr_reader :title

      # @return [Server] the server of the prompt.
      attr_reader :server

      # @return [Array<Option>] the options of the prompt.
      attr_reader :options

      # @return [true, false] whether or not the user must answer the prompt.
      attr_reader :required
      alias required? required

      # @return [true, false] whether or not only a single option can be selected.
      attr_reader :single_select
      alias single_select? single_select

      # @return [true, false] whether or not the prompt is initially visible during onboarding.
      attr_reader :in_onboarding
      alias in_onboarding? in_onboarding

      # @!visibility private
      def initialize(data, flow, bot)
        @bot = bot
        @onboarding = flow
        @server = flow.server
        @id = data['id'].to_i
        update_data(data)
      end

      # Get an option associated with the prompt.
      # @param option_id [Integer, String] The ID of the option to find.
      # @return [Option, nil] The option that was found, or `nil` if it couldn't be found.
      def option(option_id)
        option_id = option_id.resolve_id

        @options.find { |option| option.id == option_id }
      end

      # Modify the onboarding prompt.
      # @param type [Integer, Symbol] The new type of the prompt.
      # @param title [String, Symbol] The new title of the prompt.
      # @param options [Array<#to_h, Option>] The options to set for the prompt.
      # @param single_select [true, false] Whether or not only a single answer can be selected.
      # @param required [true, false] Whether or not users must provide an answer to the prompt.
      # @param in_onboarding [true, false] Whether or not the prompt should be shown in the initial flow.
      # @param reason [String, nil] The reason to show in the server's audit log for modifying the prompt.
      # @return [nil]
      def modify(
        type: :undef, title: :undef, options: :undef, single_select: :undef,
        required: :undef, in_onboarding: :undef, reason: nil
      )
        data = {
          id: @id,
          type: type == :undef ? @type : TYPES[type] || type,
          title: title == :undef ? @title : title,
          options: options == :undef ? @options.map(&:to_h) : options.map(&:to_h),
          single_select: single_select == :undef ? @single_select : single_select,
          required: required == :undef ? @required : required,
          in_onboarding: in_onboarding == :undef ? @in_onboarding : in_onboarding
        }

        prompts = @onboarding.prompts.dup.tap { |array| array.delete(@id) }

        @onboarding.modify(prompts: (prompts.map(&:to_h) << data), reason: reason)
      end

      # Create an option for the prompt.
      # @param title [String] The title of the option.
      # @param description [String, nil] The description of the option.
      # @param emoji [Emoji, Integer, String, nil] The emoji of the option.
      # @param roles [Array<Integer, Role, String>] The roles of the option.
      # @param channels [Array<Integer, Channel, String>] The channels of the option.
      # @param reason [String, nil] The reason to show in the audit log for creating the option.
      # @return [nil]
      def create_option(
        title:, description: nil, emoji: nil, roles: [], channels: [], reason: nil
      )
        data = {
          title: title,
          description: description,
          role_ids: roles ? [*roles].map(&:resolve_id) : [],
          channel_ids: channels ? [*channels].map(&:resolve_id) : [],
          **(emoji ? Option.convert_emoji(emoji) : {})
        }

        modify(options: @options.dup << data, reason: reason)
      end

      # Delete the onboarding prompt.
      # @param reason [String, nil] The reason to show in the server's audit log for deleting the prompt.
      # @return [nil]
      def delete(reason: nil)
        @onboarding.modify(prompts: @onboarding.prompts.dup.tap { |array| array.delete(@id) }, reason: reason)
      end

      # @!method dropdown?
      #   @return [true, false] whether or not the prompt is rendered as a dropdown; similar to a select menu.
      # @!method multiple_choice?
      #   @return [true, false] whether or not the prompt is rendered as a clickable grip of answers; MCQ style.
      TYPES.each do |name, value|
        define_method("#{name}?") do
          @type == value
        end
      end

      # @!visibility private
      def to_h
        {
          id: @id,
          type: @type,
          title: @title,
          required: @required,
          options: @options.map(&:to_h),
          single_select: @single_select,
          in_onboarding: @in_onboarding
        }
      end

      # @!visibility private
      def inspect
        "<Prompt id=#{@id} type=#{@type} title=\"#{@title}\" required=#{@required}>"
      end

      # @!visibility private
      def update_data(new_data)
        @type = new_data['type']
        @title = new_data['title']
        @required = new_data['required']
        @single_select = new_data['single_select']
        @in_onboarding = new_data['in_onboarding']

        if @options
          old_options = @options

          @options = new_data['options'].map do |option|
            if (old_opt = old_options.find { |old| old.id == option['id'].to_i })
              old_opt.tap { old_opt.update_data(option) }
            else
              Option.new(option, self, @bot)
            end
          end
        else
          @options = new_data['options'].map { |opt| Option.new(opt, self, @bot) }
        end
      end
    end

    # An onboarding option.
    class Option
      include IDObject

      # @return [String] the title of the option.
      attr_reader :title

      # @return [String] the description of the option.
      attr_reader :description

      # @!visibility private
      def initialize(data, prompt, bot)
        @bot = bot
        @prompt = prompt
        @id = data['id'].to_i
        update_data(data)
      end

      # Get the emoji for the option.
      # @return [Emoji, nil] The emoji of the option.
      def emoji
        @emoji&.id ? @prompt.server.emojis[@emoji.id] : @emoji
      end

      # Get the roles that will be given to a user who selects the option.
      # @return [Array<Role>] The roles that are given when the option is selected.
      def roles
        @role_ids.filter_map { |role_id| @prompt.server.role(role_id) }
      end

      # Get the channels that will be made visible to a user who selects the option.
      # @return [Array<Role>] The channels that are made visible when the option is selected.
      def channels
        @channel_ids.filter_map { |channel_id| @bot.channel(channel_id) }
      end

      # Modify the prompt option.
      # @param title [String] The new title of the prompt.
      # @param description [String] The new description of the prompt.
      # @param emoji [Emoji, Integer, String, nil] The new emoji of the prompt.
      # @param roles [Array<Role, Integer, String>] The new roles of the prompt.
      # @param channels [Array<Channel, Integer, String>] The new channels of the prompt.
      # @param reason [String, nil] The reason to show in the audit log for modifying the prompt.
      # @return [nil]
      def modify(
        title: :undef, description: :undef, emoji: :undef, roles: :undef,
        channels: :undef, reason: nil
      )
        data = {
          id: @id,
          title: title == :undef ? @title : title,
          description: description == :undef ? @description : description,
          channel_ids: channels == :undef ? @channel_ids : Array(channels).map(&:resolve_id),
          role_ids: roles == :undef ? @role_ids : Array(roles).map(&:resolve_id),
          **(emoji == :undef ? Option.convert_emoji(@emoji) : Option.convert_emoji(emoji, @prompt.server))
        }

        options = @prompt.options.dup.tap { |array| array.delete(@id) }

        @prompt.modify(options: (options.map(&:to_h) << data), reason: reason)
      end

      # Delete the prompt option.
      # @param reason [String, nil] The reason to show in the server's audit log for deleting the option.
      # @return [nil]
      def delete(reason: nil)
        @prompt.modify(options: @prompt.options.dup.tap { |array| array.delete(@id) }, reason: reason)
      end

      # @!visibility private
      def to_h
        {
          id: @id,
          title: @title,
          description: @description,
          role_ids: roles.map(&:id),
          channel_ids: channels.map(&:id),
          **Option.convert_emoji(@emoji)
        }
      end

      # @!visibility private
      def inspect
        "<Option id=#{@id} title=\"#{@title}\" description=\"#{@description}\">"
      end

      # @!visibility private
      def update_data(new_data)
        @title = new_data['title']
        @description = new_data['description']
        @role_ids = new_data['role_ids'].map(&:to_i)
        @channel_ids = new_data['channel_ids'].map(&:to_i)
        @emoji = new_data['emoji']&.values&.any? ? Discordrb::Emoji.new(new_data['emoji'], @bot) : nil
      end

      # @!visibility private
      def self.convert_emoji(data, server = nil)
        if data.is_a?(NilClass)
          {
            emoji_id: nil,
            emoji_name: nil,
            emoji_animated: false
          }
        elsif data.is_a?(Emoji)
          {
            emoji_id: data.id,
            emoji_name: data.name,
            emoji_animated: data.animated?
          }
        elsif data.to_i.zero?
          {
            emoji_id: nil,
            emoji_name: data,
            emoji_animated: false
          }
        elsif data.to_i.positive?
          data = server.emojis[data.to_i]

          {
            emoji_id: data.id,
            emoji_name: data.name,
            emoji_animated: data.animated?
          }
        end
      end
    end

    # Builder for onboarding options.
    class OptionBuilder
      # @return [Array<Hash>]
      attr_reader :options
      alias_method :to_a, :options

      # @!visibility private
      def initialize(server)
        @options = []
        @server = server
      end

      # Create an onboarding option.
      # @param title [String] The title of the option.
      # @param description [String, nil] The description of the option.
      # @param roles [Array<Role, Integer, String>] The roles to grant to a member when selected.
      # @param channels [Array<Channel, Integer, String>] The channels to add a member to when selected.
      # @param emoji [Emoji, String, nil] The emoji object, string for a unicode emoji, or nil for no emoji.
      # @return [Array<Hash<Symbol => Object>>]
      def option(title, description: nil, channels: [], roles: [], emoji: nil)
        @options << {
          title: title,
          description: description,
          role_ids: [*roles].map(&:resolve_id),
          channel_ids: [*channels].map(&:resolve_id),
          **Option.convert_emoji(emoji, @server)
        }
      end
    end
  end
end
