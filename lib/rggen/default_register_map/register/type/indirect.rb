# frozen_string_literal: true

RgGen.define_list_item_feature(:register, :type, :indirect) do
  register_map do
    define_helpers do
      def verify_index(&block)
        index_verifiers << create_verifier(&block)
      end

      def index_verifiers
        @index_verifiers ||= []
      end
    end

    define_struct :index_entry, [:name, :value] do
      def value_index?
        !array_index?
      end

      def array_index?
        value.nil?
      end

      def distinguishable?(other)
        name == other.name && value != other.value &&
          [self, other].all?(&:value_index?)
      end

      def find_index_field(bit_fields)
        bit_fields.find { |bit_field| bit_field.full_name == name }
      end

      def to_s
        [name, value].compact.join(': ')
      end
    end

    property :index_entries
    property :collect_index_fields do |bit_fields|
      index_entries.map { |entry| entry.find_index_field(bit_fields) }
    end

    support_shared_address
    support_array_register

    input_pattern /(#{variable_name}(?:\.#{variable_name})*)/,
                  match_automatically: false

    build do |_type, options|
      @index_entries = parse_index_entries(options)
    end

    verify(:component) do
      error_condition do
        !(register.array? || array_index_fields.empty?)
      end
      message { 'array indices are given to non-array register' }
    end

    verify(:component) do
      error_condition do
        register.array? &&
          register.array_size.length < array_index_fields.length
      end
      message { 'too many array indices are given' }
    end

    verify(:component) do
      error_condition do
        register.array? &&
          register.array_size.length > array_index_fields.length
      end
      message { 'few array indices are given' }
    end

    verify(:all) do
      check_error do
        index_entries.each(&method(:verify_indirect_index))
      end
    end

    verify_index do
      error_condition do |index|
        !index_entries.one? { |other| other.name == index.name }
      end
      message do |index|
        "same bit field is used as indirect index more than once: #{index.name}"
      end
    end

    verify_index do
      error_condition { |index| !index_field(index) }
      message do |index|
        "no such bit field for indirect index is found: #{index.name}"
      end
    end

    verify_index do
      error_condition do |index|
        index_field(index).register.full_name == register.full_name
      end
      message do |index|
        "own bit field is not allowed for indirect index: #{index.name}"
      end
    end

    verify_index do
      error_condition do |index|
        index_field(index).register_files.any?(&:array?)
      end
      message do |index|
        'bit field within array register file is not allowed ' \
        "for indirect index: #{index.name}"
      end
    end

    verify_index do
      error_condition { |index| index_field(index).register.array? }
      message do |index|
        'bit field within array register is not allowed ' \
        "for indirect index: #{index.name}"
      end
    end

    verify_index do
      error_condition { |index| index_field(index).sequential? }
      message do |index|
        'sequential bit field is not allowed ' \
        "for indirect index: #{index.name}"
      end
    end

    verify_index do
      error_condition { |index| index_field(index).reserved? }
      message do |index|
        'reserved bit field is not allowed ' \
        "for indirect index: #{index.name}"
      end
    end

    verify_index do
      error_condition do |index|
        !index.array_index? &&
          (index.value > (2**index_field(index).width - 1))
      end
      message do |index|
        'bit width of indirect index is not enough for ' \
        "index value #{index.value}: #{index.name}"
      end
    end

    verify_index do
      error_condition do |index|
        index.array_index? &&
          (array_index_value(index) > 2**index_field(index).width)
      end
      message do |index|
        'bit width of indirect index is not enough for ' \
        "array size #{array_index_value(index)}: #{index.name}"
      end
    end

    verify(:all) do
      error_condition { !distinguishable? }
      message { 'cannot be distinguished from other registers' }
    end

    printable(:index_bit_fields) do
      index_entries.map(&:to_s)
    end

    private

    def parse_index_entries(options)
      error 'no indirect indices are given' if options.empty?
      options.map { |option| create_index_entry(option) }
    end

    def create_index_entry(option)
      entry = array?(option) && option || [option]

      field_name, index_value =
        case entry.size
        when 2 then [check_field_name(entry[0]), convert_index_value(entry[1])]
        when 1 then [check_field_name(entry[0])]
        when 0 then error 'no indirect index is given'
        else error "too many arguments for indirect index are given: #{entry.inspect}"
        end

      index_entry.new(field_name, index_value)
    end

    def check_field_name(field_name)
      return field_name if match_field_name?(field_name)
      error "illegal input value for indirect index: #{field_name.inspect}"
    end

    def match_field_name?(field_name)
      (string?(field_name) || symbol?(field_name)) && match_pattern(field_name)
    end

    def convert_index_value(value)
      to_int(value) { |v| "cannot convert #{v.inspect} into indirect index value" }
    end

    def verify_indirect_index(index)
      helper.index_verifiers.each { |verifier| verifier.verify(self, index) }
    end

    def index_field(index)
      @index_fields ||= {}
      @index_fields[index.name] ||=
        index.find_index_field(register_block.bit_fields)
    end

    def array_index_fields
      @array_index_fields ||= index_entries.select(&:array_index?)
    end

    def array_index_value(index)
      @array_index_values ||=
        array_index_fields
          .map.with_index { |entry, i| [entry.name, register.array_size[i]] }
          .to_h
      @array_index_values[index.name]
    end

    def distinguishable?
      files_and_registers
        .select { |other| other.register? && share_same_range?(other) }
        .all? { |other| distinguishable_indices?(other.index_entries) }
    end

    def share_same_range?(other)
      register.name != other.name && register.overlap?(other)
    end

    def distinguishable_indices?(other_entries)
      index_entries.any? do |entry|
        other_entries.any?(&entry.method(:distinguishable?))
      end
    end
  end
end
