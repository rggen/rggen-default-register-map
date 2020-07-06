# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, [:rwe, :rwl]) do
  register_map do
    read_write
    volatile? { !bit_field.reference? }
    initial_value require: true
    reference use: true, width: 1

    verify(:all) do
      error_condition do
        bit_field.reference? &&
          register.full_name == reference_register.full_name
      end
      message do
        'bit field within the same register is not allowed for ' \
        "reference bit field: #{bit_field.reference.full_name}"
      end
    end

    private

    def reference_register
      bit_field.reference.register
    end
  end
end
