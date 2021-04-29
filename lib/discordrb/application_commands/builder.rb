# frozen_string_literal: true

module Discordrb::ApplicationCommands
  class Option
    attr_accessor :name, :description, :type, :options

    def initialize(name, description, type, required = nil, default = nil, choices = nil)
      @name = name
      @description = description
      @type = type
      @choices = choices
      @required = required
      @default = default
    end

    def to_h
      { 
        name: @name,
        description: @description,
        type: @type,
        choices: @choices,
        required: @required,
        default: @default
      }.compact
    end
  end

  class Builder
    attr_reader :name
    attr_reader :description
    attr_reader :options

    TYPES = {
      subcommand: 1,
      group: 2,
      string: 3,
      integer: 4,
      bool: 5,
      user: 6,
      channel: 7,
      role: 8
    }

    def initialize(name, description, &block)
      @name = name
      @description = description
      @options = []

      yield self if block_given?
    end

    TYPES.slice(*(TYPES.keys - %i[string integer subcommand group])).each do |type_name, type|
      define_method(type_name) do |name, description, required: nil, default: nil|
        subcommand_check

        @options << Option.new(name, description, type, required, default)
      end
    end

    TYPES.slice(:string, :integer).each do |type_name, type|
      define_method(type_name) do |name, description, required: nil, default: nil, choices: nil|
        subcommand_check

        case choices
        when Hash
          choices = choices.map {|k,v| {name: k, value: v} }
        when Array
          choices = choices.map {|v| { name: v.to_s, value: v } }
        end

        @options << Option.new(name, description, type, required, default, choices)
      end
    end

    def subcommand(name, description, &block)
      sub_builder = SubcommandBuilder.new(name, description, &block)

      @options << sub_builder
      sub_builder
    end
    
    def group(name, description, &block)
      group_builder = GroupBuilder.new(name, description, &block)

      @options << group_builder
      group_builder
    end

    def to_h
      {
        name: @name,
        description: @description,
        options: @options.map(&:to_h)
      }
    end

    private

    def subcommand_check
      return unless @options.any? {|opt| [1, 2].include? opt.type }
      raise ArgumentError, 'You cannot have subcommands or groups on the same level as other arguments'
    end
  end

  class SubcommandBuilder < Builder
    undef group
    undef subcommand

    def to_h
      super.merge(type: TYPES[:subcommand])
    end
  end

  class GroupBuilder < Builder
    undef group

    def to_h
      super.merge(type: TYPES[:group])
    end
  end
end