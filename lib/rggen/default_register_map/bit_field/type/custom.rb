# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, :custom) do
  register_map do
    property :sw_read, body: -> { option_value(:sw_read) }
    property :sw_write, body: -> { option_value(:sw_write) }
    property :sw_write_once?, body: -> { option_value(:sw_write_once) }
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
      sw_write: /(set_[01]|clear_[01]|toggle_[01])/i
    ], match_automatically: false

    build do |_, options|
      @options = parse_options(options)
    end

    verify(:component) do
      error_condition { sw_write_once? && !writable? }
      message { 'cannot enable sw_write_once option for unwritable bit field' }
    end

    verify(:component) do
      error_condition { hw_write? && reserved? }
      message { 'cannot enable hw_write option for reserved bit field' }
    end

    verify(:component) do
      error_condition { hw_set? && reserved? }
      message { 'cannot enable hw_set option for reserved bit field' }
    end

    verify(:component) do
      error_condition { hw_clear? && reserved? }
      message { 'cannot enable hw_clear option for reserved bit field' }
    end

    verify(:component) do
      error_condition { read_trigger? && !readable? }
      message { 'cannot enable read_trigger option for unreadable bit field' }
    end

    verify(:component) do
      error_condition { write_trigger? && !writable? }
      message { 'cannot enable write_trigger option for unwritable bit field' }
    end

    printable(:type) do
      options =
        [:sw_read, :sw_write, :sw_write_once, :hw_write, :hw_set, :hw_clear]
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
      options.each_with_object({}) do |(key, value), optin_hash|
        name = convert_to_option_name(key)
        optin_hash[name] = parse_option(name, key, value)
      end
    end

    def convert_to_option_name(key)
      return key unless string?(key) || symbol?(key)
      key.to_sym.downcase
    end

    def parse_option(option_name, key, value)
      case option_name
      when :sw_read
        parse_value_option(:sw_read, [:sw_common], value)
      when :sw_write
        parse_value_option(:sw_write, [:sw_common, :sw_write], value)
      when method(:boolean_option?)
        parse_boolean_option(option_name, value)
      else
        error "unknown option is given: #{key.inspect}"
      end
    end

    def parse_value_option(option_name, allowed_patterns, value)
      match_data, match_index = match_pattern(value)

      if match_data && allowed_patterns.include?(match_index)
        match_data.captures.first.downcase.to_sym
      else
        error "invalid value for #{option_name} option: #{value.inspect}"
      end
    end

    def boolean_option?(option_name)
      [
        :sw_write_once, :hw_write, :hw_set, :hw_clear,
        :read_trigger, :write_trigger
      ].include?(option_name)
    end

    def parse_boolean_option(option_name, value)
      boolean_value = convert_to_boolean_value(value)

      if [true, false].include?(boolean_value)
        boolean_value
      else
        error "invalid value for #{option_name} option: #{value.inspect}"
      end
    end

    def convert_to_boolean_value(value)
      _, boolean_value =
        case value
        when true then [nil, true]
        when false then [nil, false]
        else match_pattern(value)
        end
      boolean_value
    end
  end
end
