# frozen_string_literal: true

RgGen.define_feature(:bit_field, :labels) do
  register_map do
    feature do
      property :labels, initial: -> { [] }

      input_pattern variable_name, match_automatically: false

      define_struct :label_entry, [:name, :value, :comment] do
        def to_s
          to_h
            .compact
            .map { |k, v| "#{k}: #{v}" }
            .join(' ')
        end
      end

      build do |values|
        values.each { |label| labels << parse_label(label) }
      end

      define_helpers do
        def verify_label_value(&body)
          label_value_verifiers << create_verifier(&body)
        end

        def label_value_verifiers
          @label_value_verifiers ||= []
        end
      end

      verify(:component) do
        check_error do
          labels.each do |label|
            helper.label_value_verifiers.each do |verifier|
              verifier.verify(self, label.value)
            end
          end
        end
      end

      verify_label_value do
        error_condition { |value| value < min_label_value }
        message do |value|
          'input label value is less than minimum label value: ' \
          "label value #{value} minimum label value #{min_label_value}"
        end
      end

      verify_label_value do
        error_condition { |value| value > max_label_value }
        message do |value|
          'input label value is greater than maximum label value: ' \
          "label value #{value} maximum label value #{max_label_value}"
        end
      end

      printable :labels

      private

      def parse_label(label)
        label_values = [
          parse_name(label), parse_value(label), fetch_label(label, :comment)
        ]
        label_entry.new(*label_values)
      end

      def parse_name(label)
        label_value = fetch_label(label, :name) { error 'no label name is given' }
        name = match_name(label_value)
        unique_name?(name) && name ||
          (error "duplicated label name: #{name}", label_value)
      end

      def match_name(name)
        match_data, = match_pattern(name)
        match_data&.to_s ||
          (error "illegal input value for label name: #{name.inspect}", name)
      end

      def unique_name?(name)
        labels.none? { |label| label.name == name }
      end

      def parse_value(label)
        label_value = fetch_label(label, :value) { error 'no label value is given' }
        value = convert_label_value(label_value)
        unique_value?(value) && value ||
          (error "duplicated label value: #{value}", label_value)
      end

      def convert_label_value(value)
        Integer(value)
      rescue ArgumentError, TypeError
        error "cannot convert #{value.inspect} into label value", value
      end

      def unique_value?(value)
        labels.none? { |label| label.value == value }
      end

      def fetch_label(label, key, &ifnone)
        match_key =
          [key.to_sym, key.to_s]
            .find { |k| label.key?(k) }
        (match_key || ifnone&.call) && label[match_key]
      end

      def min_label_value
        bit_field.width == 1 ? 0 : -(2**(bit_field.width - 1))
      end

      def max_label_value
        2**bit_field.width - 1
      end
    end

    factory do
      value_format :hash_list
    end
  end
end
