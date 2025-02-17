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
      if array?(value) || match_index == :array
        parse_arrayed_initial_value(value)
      elsif hash?(value) || match_index == :parameterized
        parse_parameterized_initial_value(value)
      else
        parse_single_initial_value(value)
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

    def parse_arrayed_initial_value(input_value)
      if pattern_matched?
        @flatten_initial_values = parse_string_arrayed_initial_value(input_value)
      elsif input_value.none? { array?(_1) }
        @flatten_initial_values = process_arrayed_initial_value(input_value)
      else
        @initial_values = process_arrayed_initial_value(input_value)
      end
      @input_format = :array
    end

    def process_arrayed_initial_value(input_value)
      input_value.map do |value|
        if array?(value)
          process_arrayed_initial_value(value)
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

    def parse_parameterized_initial_value(input_value)
      value =
        if pattern_matched?
          match_data.captures.first
        else
          input_value
            .fetch(:default) { error 'no default value is given' }
        end
      @initial_value = parse_value(value)
      @input_format = :parameterized
    end

    def parse_single_initial_value(input_value)
      @initial_value = parse_value(input_value)
      @input_format = :single
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

      if @flatten_initial_values
        @flatten_initial_values.size == bit_field_size.inject(:*)
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
      [@initial_value, @initial_values, @flatten_initial_values].any?
    end

    def initial_values_get(flatten: false)
      return unless @initial_values || @flatten_initial_values

      if flatten
        @flatten_initial_values ||= @initial_values.flatten
      else
        @initial_values ||=
          stratify_initial_values(@flatten_initial_values, bit_field_size)
      end
    end

    def stratify_initial_values(values, bit_field_size)
      return values if bit_field_size.size == 1

      div_size = values.size / bit_field_size.first
      values
        .group_by.with_index { |_, i| i / div_size }
        .map { |_, sub_values| stratify_initial_values(sub_values, bit_field_size[1..]) }
    end

    def bit_field_size
      [*register.array_size(hierarchical: true), *bit_field.sequence_size]
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
