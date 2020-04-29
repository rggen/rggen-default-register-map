# frozen_string_literal: true

RgGen.define_simple_feature(:register_file, :offset_address) do
  register_map do
    property :offset_address
    property :address_range, initial: -> { start_address..end_address }

    build do |value|
      @offset_address = Integer(value)
    end

    private

    def start_address
      offset_address
    end

    def end_address
      offset_address + register_file.byte_size - 1
    end
  end
end
