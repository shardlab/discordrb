# frozen_string_literal: true

module Discordrb
  # The onboarding flow for new members in a server.
  class Onboarding
    # Map of onboarding modes.
    MODES = {
      default: 0,
      advanced: 1
    }.freeze

    # @return [Server] the server this onboarding object is for.
    attr_reader :server

    # @return [Integer] the current mode of onboarding.
    # @see MODES
    attr_reader :mode

    # @return [true, false] whether onboarding is enabled or not.
    attr_reader :enabled
    alias_method :enabled?, :enabled

    # @return [Array<Prompt>] the prompts shown during the inital onboarding flow.
    attr_reader :prompts

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      from_other(data)
    end

    # Get a string that will mention the Channels & Roles tab.
    # @return [String] a string that can be used to mention the onboarding flow.
    def mention
      '<id:customize>'
    end

    # @return [true, false] whether the onboarding mode only counts default channels towards constraints.
    def default_mode?
      @mode == MODES[:default]
    end

    # @return [true, false] whether the onboarding mode counts default channels and questions towards constraints.
    def advanced_mode?
      @mode == MODES[:advanced]
    end

    # Get a prompt by its ID.
    # @param id [Integer, String, Prompt] the ID of the prompt to find.
    # @return [Prompt, nil] the prompt, or `nil` if it couldn't be found.
    def prompt(id)
      @prompts.find { |prompt| prompt.id == id.resolve_id }
    end

    # @return [Array<Channel>] the default channels that members automatically get opted into.
    def default_channels
      @default_channel_ids.filter_map { |id| @bot.channel(id) }
    end

    # Set the default channels for this onboarding flow.
    # @param channels [Array<Channel, Integer, String>] the new default channels.
    def default_channels=(channels)
      update_data(default_channels: channels.map(&:resolve_id))
    end

    # Set whether onboarding is enabled or not.
    # @param enabled [true, false] whether onboarding is enabled or not.
    def enabled=(enabled)
      update_data(enabled: enabled)
    end

    # Set the mode for this onboarding flow.
    # @param mode [Symbol, Integer] the new onboarding mode.
    def mode=(mode)
      update_data(mode: MODES[mode] || mode)
    end

    # Set the prompts for this onboarding flow in bulk.
    # @param prompts [Array<Hash>] the new prompts to set.
    def prompts=(prompts)
      update_data(prompts: prompts.to_a.map(&:to_h))
    end

    # Remove one or more prompts from this onboarding flow.
    # @param ids [Integer, String, Prompt] the IDs of the prompts to remove.
    # @return [void]
    def delete_prompts(*ids)
      new_prompts = @prompts.reject do |prompt|
        [*ids].map(&:resolve_id).any?(prompt.id)
      end

      update_data(prompts: new_prompts.map(&:to_h))
    end

    alias_method :delete_prompt, :delete_prompts

    # Add one or more prompts to this onboarding flow.
    # @yieldparam builder [PromptBuilder] The prompt builder.
    # @return [void]
    def create_prompts
      yield (builder = PromptBuilder.new)

      update_data(prompts: @prompts.map(&:to_h) + builder.to_a)
    end

    alias_method :create_prompt, :create_prompts

    # @!visibility private
    def from_other(new_data)
      @mode = new_data['mode']
      @enabled = new_data['enabled']
      @default_channel_ids = new_data['default_channel_ids'].map(&:resolve_id)
      @prompts = new_data['prompts'].map { |prompt| Prompt.new(prompt, @server, @bot) }
    end

    # @!visibility private
    def update_data(new_data)
      from_other(JSON.parse(API::Server.modify_onboarding(@bot.token, server.id,
                                                          new_data[:mode] || :undef,
                                                          new_data[:prompts]&.to_a || :undef,
                                                          new_data[:default_channels] || :undef,
                                                          new_data.key?(:enabled) ? new_data[:enabled] : :undef)))
    end

    # A prompt that can be shown during the inital onboarding flow.
    class Prompt
      include IDObject

      # Map of prompt types.
      TYPES = {
        multiple_choice: 0,
        dropdown: 1
      }.freeze

      # @return [Integer] the type of this prompt.
      # @see TYPES
      attr_reader :type

      # @return [String] the title/question of this prompt.
      attr_reader :title

      # @return [Array<Option>] the options inside of this prompt.
      attr_reader :options

      # @return [true, false] whether users are limited to selecting one option for the prompt.
      attr_reader :single_select
      alias_method :single_select?, :single_select

      # @return [true, false] whether this prompt is required before a user completes the onboarding flow.
      attr_reader :required
      alias_method :required?, :required

      # @return [true, false] whether the prompt is present in the initial onboarding flow. If false, the prompt
      #   will only appear in the Channels & Roles tab.
      attr_reader :in_onboarding
      alias_method :in_onboarding?, :in_onboarding

      # @!visibility private
      def initialize(data, server, bot)
        @bot = bot
        @id = data['id'].to_i
        @type = data['type']
        @options = data['options'].map { |opt| Option.new(opt, server, bot) }
        @title = data['title']
        @single_select = data['single_select']
        @required = data['required']
        @in_onboarding = data['in_onboarding']
      end

      # Get an option by its ID.
      # @param id [Integer, String, Option] the ID of the option to find.
      # @return [Option, nil] the option or `nil` if it couldn't be found.
      def option(id)
        @options.find { |option| option.id == id.resolve_id }
      end

      # @return [true, false] whether this prompt has multiple choices.
      def multiple_choice?
        @type == TYPES[:multiple_choice]
      end

      # @return [true, false] whether this prompt is a dropdown.
      def dropdown?
        @type == TYPES[:dropdown]
      end

      # @!visibility private
      def to_h
        {
          id: @id,
          type: @type,
          options: @options.map(&:to_h),
          title: @title,
          single_select: @single_select,
          required: @required,
          in_onboarding: @in_onboarding
        }
      end
    end

    # An option within an onboarding prompt.
    class Option
      include IDObject

      # @return [String] the title of this option.
      attr_reader :title

      # @return [Emoji, nil] the emoji of this option.
      attr_reader :emoji

      # @return [String, nil] the description of this option.
      attr_reader :description

      # @return [Array<Role>] the roles assigned to a member when the option is selected.
      attr_reader :roles

      # @!visibility private
      def initialize(data, server, bot)
        @bot = bot
        @id = data['id'].to_i
        @title = data['title']
        @description = data['description']
        @channel_ids = data['channel_ids'].map(&:resolve_id)
        @roles = data['role_ids'].map { |id| server.role(id) }
        @emoji = Discordrb::Emoji.new(data['emoji'], bot) if data['emoji']&.values&.any?
      end

      # @return [Array<Channel>] the channels a member is added to when the option is selected.
      def channels
        @channel_ids.filter_map { |id| @bot.channel(id) }
      end

      # @!visibility private
      def to_h
        {
          id: @id,
          title: @title,
          description: @description,
          channel_ids: @channel_ids,
          role_ids: @roles.map(&:resolve_id),
          emoji_id: @emoji&.id,
          emoji_name: @emoji&.name,
          emoji_animated: @emoji&.animated?
        }.compact
      end
    end

    # Builder for onboarding prompts.
    class PromptBuilder
      # @return [Array<Hash>]
      attr_reader :prompts
      alias_method :to_a, :prompts

      # @!visibility private
      def initialize
        @prompts = []
      end

      # @param title [String] The title of the prompt.
      # @param type [Symbol, Integer] The type of prompt. See {Prompt::TYPES}.
      # @param single_select [true, false] whether users can only select one option for the prompt. Default true.
      # @param required [true, false] whether this prompt is required before a user completes the onboarding flow.
      # @param in_onboarding [true, false] whether the prompt is present in the onboarding flow. If false, the prompt
      #   will only appear in the Channels & Roles tab.
      # @yieldparam [OptionBuilder]
      def prompt(title:, type:, required:, single_select: true, in_onboarding: true)
        yield (builder = OptionBuilder.new)

        @prompts << { title: title, type: Prompt::TYPES[type] || type, options: builder.to_a,
                      required: required, in_onboarding: in_onboarding, id: @prompts.size + 1,
                      single_select: single_select }
      end
    end

    # Builder for onboarding options.
    class OptionBuilder
      # @return [Array<Hash>]
      attr_reader :options
      alias_method :to_a, :options

      # @!visibility private
      def initialize
        @options = []
      end

      # @param title [String] The title of the option.
      # @param description [String, nil] The description of the option.
      # @param channels [Array<Channel, Integer, String>] Channels a member is added to when the option is selected.
      # @param roles [Array<Role, Integer, String>] Roles assigned to a member when the option is selected.
      # @param emoji [Emoji, String, nil] The emoji object, string for a unicode emoji, or nil for no emoji.
      def option(title:, description: nil, channels: [], roles: [], emoji: nil)
        emoji = case emoji
                when String
                  { emoji_id: nil, emoji_name: emoji, emoji_animated: false }
                when Emoji
                  { emoji_id: emoji.id, emoji_name: emoji.name, emoji_animated: emoji.animated? }
                else
                  raise ArgumentError, "Invalid emoji type: #{emoji.class}" unless emoji.nil?
                end

        @options << { title: title, description: description, role_ids: [*roles].map(&:resolve_id),
                      channel_ids: [*channels].map(&:resolve_id), **emoji }
      end
    end
  end
end
