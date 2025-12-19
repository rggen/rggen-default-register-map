# frozen_string_literal: true

RgGen.define_list_item_feature(:register, :type, :maskable) do
  register_map do
    support_array_register

    verify(:component) do
      check_error do
        register.bit_fields.each(&method(:check_assignment))
      end
    end

    def check_assignment(bit_field)
      (bit_field.sequence_size || 1).times do |i|
        msb = bit_field.msb(i)
        lsb = bit_field.lsb(i)
        next unless in_mask_range?(msb, lsb)

        error "bit field is assigned to upper half word: [#{msb}:#{lsb}]"
      end
    end

    def in_mask_range?(msb, lsb)
      width = register_block.bus_width
      half_width = width / 2
      (lsb..msb).any? { |bit| (bit % width) >= half_width }
    end
  end
end
