# frozen_string_literal: true

RgGen.define_simple_feature(:bit_field, :reference) do
  register_map do
    property :reference, initial: -> { reference_bit_field }, verify: :all
    property :reference?, body: -> { use_reference? && !no_reference? }
    property :reference_width, forward_to: :required_width
    property :find_reference, forward_to: :find_reference_bit_field

    input_pattern /(#{variable_name}(?:\.#{variable_name})*)/

    build do |value|
      pattern_matched? ||
        (error "illegal input value for reference: #{value.inspect}")
      @input_reference = match_data.to_s
    end

    verify(:component) do
      error_condition { require_reference? && no_reference? }
      message { 'no reference bit field is given' }
    end

    verify(:component) do
      error_condition { reference? && @input_reference == bit_field.full_name }
      message { "self reference: #{@input_reference}" }
    end

    verify(:all) do
      error_condition { reference? && !reference_bit_field }
      message { "no such bit field found: #{@input_reference}" }
    end

    verify(:all) do
      error_condition do
        reference? && within_array?(reference_bit_field) &&
          (bit_field.depth != reference_bit_field.depth)
      end
      message do
        'depth of layer is not matched: ' \
        "own #{bit_field.depth} " \
        "reference #{reference_bit_field.depth}"
      end
    end

    define_helpers do
      def verify_array(&)
        array_verifiers << create_verifier(&)
      end

      def array_verifiers
        @array_verifiers ||= []
      end
    end

    verify(:all) do
      check_error do
        reference? && within_array?(reference_bit_field) &&
          helper.array_verifiers.each(&method(:verify_array))
      end
    end

    verify_array do
      error_condition { |own, ref| !own.array? && ref.array? }
      message do |*_, layer|
        "bit field within array #{layer.to_s.tr('_', ' ')} is not allowed for " \
        "reference bit field: #{@input_reference}"
      end
    end

    verify_array do
      error_condition { |own, ref| unmatch_array_size?(own, ref) }
      message do |own, ref|
        'array size is not matched: ' \
        "own #{own.array_size} reference #{ref.array_size}"
      end
    end

    verify(:all) do
      error_condition do
        reference? && !bit_field.sequential? && reference_bit_field.sequential?
      end
      message do
        'sequential bit field is not allowed for ' \
        "reference bit field: #{@input_reference}"
      end
    end

    verify(:all) do
      error_condition { reference? && unmatch_sequence_size? }
      message do
        'sequence size is not matched: ' \
        "own #{bit_field.sequence_size} " \
        "reference #{reference_bit_field.sequence_size}"
      end
    end

    verify(:all) do
      error_condition { reference? && reference_bit_field.reserved? }
      message { "refer to reserved bit field: #{@input_reference}" }
    end

    verify(:all) do
      error_condition { reference? && !match_width? }
      message do
        "#{required_width} bits reference bit field is required: " \
        "#{reference_bit_field.width} bit(s) width"
      end
    end

    printable(:reference) do
      reference? && @input_reference || nil
    end

    private

    def settings
      @settings ||=
        (bit_field.settings && bit_field.settings[:reference]) || {}
    end

    def use_reference?
      settings.fetch(:use, false)
    end

    def require_reference?
      use_reference? && settings[:require]
    end

    def no_reference?
      @input_reference.nil?
    end

    def reference_bit_field
      (reference? || nil) &&
        (@reference_bit_field ||= lookup_reference)
    end

    def find_reference_bit_field(bit_fields)
      (reference? || nil) &&
        bit_fields
          .find { |bit_field| bit_field.full_name == @input_reference }
    end

    def lookup_reference
      find_reference_bit_field(register_block.bit_fields)
    end

    def within_array?(bit_field)
      bit_field.register_files.any?(&:array?) || bit_field.register.array?
    end

    def verify_array(verifier)
      [*register_files, register]
        .zip([*reference_bit_field.register_files, reference_bit_field.register])
        .each { |own, ref| verifier.verify(self, own, ref, own.layer) }
    end

    def unmatch_array_size?(own, ref)
      own.array? && ref.array? && own.array_size != ref.array_size
    end

    def unmatch_sequence_size?
      bit_field.sequential? && reference_bit_field.sequential? &&
        (bit_field.sequence_size != reference_bit_field.sequence_size)
    end

    def required_width
      settings[:width] || bit_field.width
    end

    def match_width?
      reference_bit_field.width >= required_width
    end
  end
end
