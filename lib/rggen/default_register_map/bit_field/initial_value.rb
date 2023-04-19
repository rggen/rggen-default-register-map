# frozen_string_literal: true

RgGen.define_simple_feature(:bit_field, :initial_value) do
  register_map do
    property :initial_value
    property :initial_values
    property :initial_value?, forward_to: :initial_value_set?
    property :fixed_initial_value?, forward_to: :fixed_format?
    property :initial_value_array?, forward_to: :array_format?

    input_pattern [{ parameterized: /default:(#{integer})/,
                     array: /#{integer}(?:[,\n]#{integer})+/ }]

    build do |value|
      @input_format =
        if hash?(value) || match_index == :parameterized
          :parameterized
        elsif array?(value) || match_index == :array
          :array
        else
          :single
        end
      @initial_value, @initial_values = parse_initial_value(value)
    end

    define_helpers do
      def verify_initial_value(&block)
        initial_value_verifiers << create_verifier(&block)
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
        @input_format == :array && !bit_field.sequential?
      end
      message do
        'arrayed initial value is not allowed for non sequential bit field'
      end
    end

    verify(:component) do
      error_condition do
        @input_format == :array && initial_values.size > bit_field.sequence_size
      end
      message { 'too many initial values are given' }
    end

    verify(:component) do
      error_condition do
        @input_format == :array && initial_values.size < bit_field.sequence_size
      end
      message { 'few initial values are given' }
    end

    verify(:component) do
      check_error do
        Array(initial_value || initial_values)
          .each(&method(:verify_initial_value))
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

    def initial_value_format
      @initial_value_format ||=
        if @input_format == :parameterized
          bit_field.sequential? && :array || :single
        else
          @input_format
        end
    end

    def array_format?
      initial_value_format == :array
    end

    def fixed_format?
      [:array, :single].include?(@input_format)
    end

    def parse_initial_value(input_value)
      case @input_format
      when :parameterized
        [parse_parameterized_initial_value(input_value), nil]
      when :array
        [nil, parse_arrayed_initial_value(input_value)]
      else
        [parse_value(input_value), nil]
      end
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
      values =
        if pattern_matched?
          input_value.split(/[,\n]/)
        else
          input_value
        end
      values.map(&method(:parse_value))
    end

    def parse_value(value)
      to_int(value) { |v| "cannot convert #{v.inspect} into initial value" }
    end

    def verify_initial_value(value)
      helper.initial_value_verifiers.each do |verifier|
        verifier.verify(self, value)
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
      [@initial_value, @initial_values].any?
    end

    def format_value(value)
      print_width = (bit_field.width + 3) / 4
      format('0x%0*x', print_width, value)
    end
  end
end
