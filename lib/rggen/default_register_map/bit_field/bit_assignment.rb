# frozen_string_literal: true

RgGen.define_simple_feature(:bit_field, :bit_assignment) do
  configuration do
    property :bit_assignment, default: :width_first

    input_pattern [width_first: /width_first/i, lsb_first: /lsb_first/i]
    ignore_empty_value false

    build do |value|
      pattern_matched? ||
        (error "illegal input value for bit assignment: #{value.inspect}")
      @bit_assignment = match_index
    end
  end

  register_map do
    property :lsb, forward_to: :lsb_bit
    property :msb, forward_to: :msb_bit
    property :width, default: 1
    property :sequence_size
    property :step, initial: -> { width }
    property :sequential?, body: -> { !@sequence_size.nil? }
    property :bit_map, initial: -> { calc_bit_map }

    input_pattern /#{integer}(?::#{integer})*/,
                  match_automatically: false

    build do |value|
      input_value = preprocess(value)
      helper.variable_names.each do |key, variable_name|
        parse_value(input_value, key, variable_name)
      end
    end

    verify(:feature) do
      error_condition { [@lsb_base, @width, @sequence_size, @step].none? }
      message { 'no bit assignment is given' }
    end

    verify(:feature) do
      error_condition { [@lsb_base, @width].none? }
      message { 'neither lsb nor width is given' }
    end

    verify(:feature) do
      error_condition { lsb.negative? }
      message { "lsb is less than 0: #{lsb}" }
    end

    verify(:feature) do
      error_condition { width < 1 }
      message { "width is less than 1: #{width}" }
    end

    verify(:feature) do
      error_condition { sequential? && sequence_size < 1 }
      message { "sequence size is less than 1: #{sequence_size}" }
    end

    verify(:feature) do
      error_condition { sequential? && step < width }
      message { "step is less than width: step #{step} width #{width}" }
    end

    verify(:feature) do
      error_condition { overlap? }
      message { 'overlap with existing bit field(s)' }
    end

    printable(:bit_assignments) do
      Array.new(@sequence_size || 1) do |i|
        width > 1 && "[#{msb(i)}:#{lsb(i)}]" || "[#{lsb(i)}]"
      end
    end

    private

    define_helpers do
      def variable_names
        @variable_names ||= {
          width: :@width, lsb: :@lsb_base, sequence_size: :@sequence_size, step: :@step
        }.freeze
      end
    end

    def preprocess(value)
      case value
      when method(:hash?) then value
      when method(:integer?) then { variable_key(0) => value }
      when method(:match_bit_assignment?) then split_match_data(match_data)
      else
        error "illegal input value for bit assignment: #{value.inspect}"
      end
    end

    # workaround for ruby 3.2 bug
    # see:
    # * https://bugs.ruby-lang.org/issues/19273
    # * https://github.com/rggen/rggen/issues/129#issuecomment-1366666885
    def match_bit_assignment?(value)
      string?(value) && match_pattern(value) && value.count(':') <= 3
    end

    def split_match_data(match_data)
      match_data
        .to_s
        .split(':')
        .map.with_index { |v, i| [variable_key(i), v] }
        .to_h
    end

    def variable_key(index)
      @keys ||=
        if configuration.bit_assignment == :width_first
          helper.variable_names.keys
        else
          keys = helper.variable_names.keys
          [keys[1], keys[0], *keys[2..]]
        end
      @keys[index]
    end

    def parse_value(input_value, key, variable_name)
      return unless input_value.key?(key)

      value =
        to_int(input_value[key]) do
          "cannot convert #{input_value[key].inspect} into " \
          "bit assignment(#{key.to_s.tr('_', ' ')})"
        end
      instance_variable_set(variable_name, value)
    end

    def lsb_base
      @lsb_base ||=
        ((bit_field.component_index.zero? && 0) || calc_next_lsb(previous_bit_field))
    end

    def previous_bit_field
      index = bit_field.component_index - 1
      bit_fields[index]
    end

    def calc_next_lsb(bit_field)
      compact_sequential_bit_field?(bit_field) &&
        (bit_field.lsb + bit_field.width * bit_field.sequence_size) ||
        (bit_field.lsb + bit_field.width)
    end

    def compact_sequential_bit_field?(bit_field)
      bit_field.sequential? && (bit_field.step == bit_field.width)
    end

    def lsb_bit(index = 0)
      lsb_msb_bit(index, 0)
    end

    def msb_bit(index = 0)
      lsb_msb_bit(index, width - 1)
    end

    def lsb_msb_bit(index, offset)
      base = lsb_base + offset
      if base_lsb_msb?(index)
        base
      elsif !integer?(index)
        "#{base}+#{step}*#{index}"
      else
        sequential_lsb_list[index]&.+(offset)
      end
    end

    def base_lsb_msb?(index)
      !sequential? || integer?(index) && index.zero?
    end

    def sequential_lsb_list
      @sequential_lsb_list ||=
        Array.new(sequence_size) { |i| lsb_base + step * i }
    end

    def calc_bit_map
      Array.new(sequence_size || 1) { |i| (2**width - 1) << lsb(i) }.inject(:|)
    end

    def overlap?
      bit_fields.any? { |bit_field| (bit_field.bit_map & bit_map).nonzero? }
    end
  end
end
