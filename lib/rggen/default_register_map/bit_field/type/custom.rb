# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, :custom) do
  register_map do
    property :sw_read, body: -> { option_value(:sw_read) }
    property :sw_write, body: -> { option_value(:sw_write) }
    property :hw_write?, body: -> { option_value(:hw_write) }
    property :hw_set?, body: -> { option_value(:hw_set) }
    property :hw_clear?, body: -> { option_value(:hw_clear) }
    property :sw_update?, forward_to: :update_by_sw?
    property :hw_update?, forward_to: :update_by_hw?
    property :read_trigger?, body: -> { option_value(:read_trigger) }
    property :write_trigger?, body: -> { option_value(:write_trigger) }

    readable? { bit_field.sw_read != :none }
    writable? { bit_field.sw_write != :none }
    volatile? { !bit_field.sw_update? && bit_field.readable? || bit_field.hw_update? }
    initial_value require: -> { bit_field.sw_update? || bit_field.hw_update? }

    input_pattern [
      true => truthy_pattern, false => falsey_pattern,
      sw_common: /(none|default|set|clear)/i,
      sw_write: /(set_[01]*|clear_[01]*|toggle_[01]*)/i
    ], match_automatically: false

    build { |_, options| parse_options(options) }

    printable(:type) do
      options =
        [:sw_read, :sw_write, :hw_write, :hw_set, :hw_clear]
          .map { |o| "#{o}: #{option_value(o)}" }
      [type, *options]
    end

    private

    def option_value(name)
      default_value =
        if boolean_option?(name)
          false
        else
          :default
        end
      @options.fetch(name, default_value)
    end

    def update_by_sw?
      [:set, :clear].include?(sw_read) || sw_write != :none
    end

    def update_by_hw?
      hw_write? || hw_set? || hw_clear?
    end

    def parse_options(options)
      @options = {}
      merge_options(options).each do |key, value|
        if match_option_name?(key, :sw_read)
          parse_value_option(:sw_read, [:sw_common], value)
        elsif match_option_name?(key, :sw_write)
          parse_value_option(:sw_write, [:sw_common, :sw_write], value)
        elsif (option = boolean_option?(key))
          parse_boolean_option(option, value)
        else
          error "unknown option is given: #{key.inspect}"
        end
      end
    end

    def merge_options(options)
      options.each_with_object({}) do |option, merged_options|
        option_hash = hash?(option) && option || [option].to_h
        merged_options.update(option_hash)
      end
    rescue ArgumentError, TypeError
      error "invalid options are given: #{options.inspect}"
    end

    def parse_value_option(option_name, allowed_patterns, value)
      match_data, match_index = match_pattern(value)

      if match_data && allowed_patterns.include?(match_index)
        @options[option_name] = match_data.captures.first.to_sym
      else
        error "invalid value for #{option_name} option: #{value.inspect}"
      end
    end

    def boolean_option?(key)
      [:hw_write, :hw_set, :hw_clear, :read_trigger, :write_trigger]
        .find { |option| match_option_name?(key, option) }
    end

    def parse_boolean_option(option_name, value)
      _, boolean_value =
        case value
        when true then [nil, true]
        when false then [nil, false]
        else match_pattern(value)
        end

      if [true, false].include?(boolean_value)
        @options[option_name] = boolean_value
      else
        error "invalid value for #{option_name} option: #{value.inspect}"
      end
    end

    def match_option_name?(lhs, rhs)
      return false unless string?(lhs) || symbol?(lhs)
      lhs.to_sym.casecmp?(rhs)
    end
  end
end
