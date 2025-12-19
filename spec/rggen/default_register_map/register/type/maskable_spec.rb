# frozen_string_literal: true

RSpec.describe 'register/type/maskable' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:address_width, :enable_wide_register])
    RgGen.enable(:register_block, [:byte_size, :bus_width])
    RgGen.enable(:register_file, [:name, :offset_address, :size])
    RgGen.enable(:register, [:name, :offset_address, :size, :type])
    RgGen.enable(:register, :type, [:maskable])
    RgGen.enable(:bit_field, [:name, :bit_assignment, :initial_value, :reference, :type])
    RgGen.enable(:bit_field, :type, [:ro, :rw, :wo, :reserved])
  end

  def create_registers(**config_values, &block)
    configuration = create_configuration(**config_values)
    register_map = create_register_map(configuration) do
      register_block do
        byte_size 256
        instance_eval(&block)
      end
    end
    register_map.registers
  end

  def create_register(**config_values, &block)
    registers = create_registers(**config_values) do
      register(&block)
    end
    registers[0]
  end

  specify 'レジスタ型は:maskable' do
    register = create_register do
      name 'foo'; type :maskable
      bit_field { name 'foo'; bit_assignment lsb: 0, width: 1; type :rw; initial_value 0 }
    end
    expect(register).to have_property(:type, :maskable)
  end

  specify '配列レジスタに対応する' do
    registers = create_registers do
      register do
        name 'foo'; type :maskable;
        bit_field { name 'foo'; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end

      register do
        name 'bar'; type :maskable; size [4]
        bit_field { name 'bar'; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end

      register do
        name 'buz'; type :maskable; size [2, 2]
        bit_field { name 'buz'; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
    end

    expect(registers[0]).not_to be_array
    expect(registers[1]).to be_array
    expect(registers[2]).to be_array
  end

  describe 'エラーチェック' do
    context '上位半分にビットフィールドが割り当てられた場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_register(bus_width: 8) do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 2, width: 2; type :rw; initial_value 0 }
          end
        }.not_to raise_error

        expect {
          create_register(bus_width: 8) do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 4, width: 2; type :rw; initial_value 0 }
          end
        }.to raise_source_error 'bit field is assigned to upper half word: [5:4]'

        expect {
          create_register(bus_width: 16) do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 6, width: 2; type :rw; initial_value 0 }
          end
        }.not_to raise_error

        expect {
          create_register(bus_width: 16) do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 8, width: 2; type :rw; initial_value 0 }
          end
        }.to raise_source_error 'bit field is assigned to upper half word: [9:8]'

        expect {
          create_register(bus_width: 32) do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 14, width: 2; type :rw; initial_value 0 }
          end
        }.not_to raise_error

        expect {
          create_register(bus_width: 32) do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 16, width: 2; type :rw; initial_value 0 }
          end
        }.to raise_source_error 'bit field is assigned to upper half word: [17:16]'

        expect {
          create_register(bus_width: 64) do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 30, width: 2; type :rw; initial_value 0 }
          end
        }.not_to raise_error

        expect {
          create_register(bus_width: 64) do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 32, width: 2; type :rw; initial_value 0 }
          end
        }.to raise_source_error 'bit field is assigned to upper half word: [33:32]'

        expect {
          create_register do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 15, width: 2; type :rw; initial_value 0 }
          end
        }.to raise_source_error 'bit field is assigned to upper half word: [16:15]'

        expect {
          create_register do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 13, width: 2, sequence_size: 2 ; type :rw; initial_value 0 }
          end
        }.to raise_source_error 'bit field is assigned to upper half word: [16:15]'

        expect {
          create_register do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 16, width: 2; type :rw; initial_value 0 }
          end
        }.to raise_source_error 'bit field is assigned to upper half word: [17:16]'

        expect {
          create_register do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 14, width: 2, sequence_size: 2 ; type :rw; initial_value 0 }
          end
        }.to raise_source_error 'bit field is assigned to upper half word: [17:16]'

        expect {
          create_register do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 31, width: 2; type :rw; initial_value 0 }
          end
        }.to raise_source_error 'bit field is assigned to upper half word: [32:31]'

        expect {
          create_register do
            name 'foo'; type :maskable
            bit_field {
              name 'foo'; bit_assignment lsb: 14, width: 2, sequence_size: 2, step: 17
              type :rw; initial_value 0
            }
          end
        }.to raise_source_error 'bit field is assigned to upper half word: [32:31]'

        expect {
          create_register do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 15, width: 18; type :rw; initial_value 0 }
          end
        }.to raise_source_error 'bit field is assigned to upper half word: [32:15]'

        expect {
          create_register do
            name 'foo'; type :maskable
            bit_field { name 'foo'; bit_assignment lsb: 0, width: 16; type :rw; initial_value 0 }
          end
        }.not_to raise_error

        expect {
          create_register do
            name 'foo'; type :maskable
            bit_field {
              name 'foo'; bit_assignment lsb: 14, width: 2, sequence_size: 2, step: 32
              type :rw; initial_value 0
            }
          end
        }.not_to raise_error
      end
    end
  end
end
