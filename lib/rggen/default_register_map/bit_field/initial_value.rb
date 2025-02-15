# frozen_string_literal: true

RgGen.define_simple_feature(:bit_field, :initial_value) do
  register_map do
    property :initial_value
    property :initial_values, forward_to: :initial_values_get
    property :initial_value?, forward_to: :initial_value_set?
    property :fixed_initial_value?, forward_to: :fixed_format?
    property :initial_value_array?, forward_to: :array_format?

    input_pattern [{ parameterized: /default:(#{integer})/,
                     array: /#{integer}(?:[,\n]#{integer})+/ }]

    build do |value|
      if array?(value)
        @input_format = :array
        @initial_values = parse_arrayed_initial_value(value)
      elsif match_index == :array
        @input_format = :array
        @raw_initial_values = parse_string_arrayed_initial_value(value)
      elsif hash?(value) || match_index == :parameterized
        @input_format = :parameterized
        @initial_value = parse_parameterized_initial_value(value)
      else
        @input_format = :single
        @initial_value = parse_value(value)
      end
    end

    define_helpers do
      def verify_initial_value(&)
        initial_value_verifiers << create_verifier(&)
      end

      def initial_value_verifiers
        @initial_value_verifiers ||= []
      end
    end

    verify(:component) do
      error_condition { need_initial_value? && !initial_value? }
      message { 'no initial value is given' }
    end

    verify(:component) do
      error_condition do
        array_format? && !array_bit_field?
      end
      message do
        'arrayed initial value is not allowed for non sequential bit field'
      end
    end

    verify(:component) do
      error_condition { !match_arrayed_initial_value_size? }
      message { 'size of bit fields and size of initial values are not matched' }
    end

    verify(:component) do
      check_error do
        verify_initial_value(initial_value || initial_values)
      end
    end

    verify_initial_value do
      error_condition { |value| value < min_initial_value }
      message do |value|
        'input initial value is less than minimum initial value: ' \
        "initial value #{value} minimum initial value #{min_initial_value}"
      end
    end

    verify_initial_value do
      error_condition { |value| value > max_initial_value }
      message do |value|
        'input initial value is greater than maximum initial value: ' \
        "initial value #{value} maximum initial value #{max_initial_value}"
      end
    end

    verify_initial_value do
      error_condition { |value| !match_valid_condition?(value) }
      message do |value|
        "does not match the valid initial value condition: #{value}"
      end
    end

    printable(:initial_value) do
      if @input_format == :parameterized
        "default: #{format_value(initial_value)}"
      elsif @input_format == :array
        initial_values.map(&method(:format_value))
      elsif initial_value?
        format_value(initial_value)
      end
    end

    private

    def array_format?
      @input_format == :array ||
        @input_format == :parameterized && array_bit_field?
    end

    def fixed_format?
      [:array, :single].include?(@input_format)
    end

    def array_bit_field?
      bit_field.sequential? || register.array?(hierarchical: true)
    end

    def parse_parameterized_initial_value(input_value)
      value =
        if pattern_matched?
          match_data.captures.first
        else
          input_value
            .fetch(:default) { error 'no default value is given' }
        end
      parse_value(value)
    end

    def parse_arrayed_initial_value(input_value)
      input_value.map do |value|
        if array?(value)
          parse_arrayed_initial_value(value)
        else
          parse_value(value)
        end
      end
    end

    def parse_string_arrayed_initial_value(input_value)
      input_value
        .split(/[,\n]/)
        .map(&method(:parse_value))
    end

    def parse_value(value)
      to_int(value) { |v| "cannot convert #{v.inspect} into initial value" }
    end

    def verify_initial_value(value)
      if array?(value)
        value.each { verify_initial_value(_1) }
      elsif value
        helper.initial_value_verifiers.each do |verifier|
          verifier.verify(self, value)
        end
      end
    end

    def settings
      @settings ||=
        (bit_field.settings && bit_field.settings[:initial_value]) || {}
    end

    def need_initial_value?
      case settings[:require]
      when Proc then instance_exec(&settings[:require])
      else settings[:require]
      end
    end

    def match_arrayed_initial_value_size?
      return true unless array_format? && fixed_format?

      bit_field_size = [
        *register.array_size(hierarchical: true), *bit_field.sequence_size
      ]
      if @raw_initial_values
        @raw_initial_values.size == bit_field_size.inject(:*)
      else
        match_array_size?(@initial_values, bit_field_size)
      end
    end

    def match_array_size?(initial_values, bit_field_size)
      return false unless array?(initial_values) && !bit_field_size.empty?
      return false if initial_values.size != bit_field_size.first

      bit_field_size.size == 1 ||
        initial_values
          .all? { |sub_values| match_array_size?(sub_values, bit_field_size[1..]) }
    end

    def min_initial_value
      bit_field.width == 1 ? 0 : -(2**(bit_field.width - 1))
    end

    def max_initial_value
      2**bit_field.width - 1
    end

    def match_valid_condition?(value)
      !settings.key?(:valid_condition) ||
        instance_exec(value, &settings[:valid_condition])
    end

    def initial_value_set?
      [@initial_value, @initial_values, @raw_initial_values].any?
    end

    def initial_values_get
      if @raw_initial_values
        @initial_values ||=
          build_initial_values(
            @raw_initial_values, register.array_size(hierarchical: true)
          )
      end

      @initial_values
    end

    def build_initial_values(raw_values, array_size)
      return raw_values if array_size.nil? || array_size.empty?

      div_size = raw_values.size / array_size.first
      raw_values
        .group_by.with_index { |_, i| i / div_size }
        .map { |_, sub_values| build_initial_values(sub_values, array_size[1..]) }
    end

    def format_value(value)
      if array?(value)
        value.map(&method(:format_value))
      else
        print_width = (bit_field.width + 3) / 4
        format('0x%0*x', print_width, value)
      end
    end
  end
end
