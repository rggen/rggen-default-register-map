# frozen_string_literal: true

RSpec.describe 'bit_field/type/rol' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:bus_width, :enable_wide_register])
    RgGen.enable(:register, [:name, :size, :type])
    RgGen.enable(:bit_field, [:name, :bit_assignment, :initial_value, :reference, :type])
    RgGen.enable(:bit_field, :type, [:rw, :rol])
  end

  def create_bit_fields(&block)
    create_register_map { register_block(&block) }.bit_fields
  end

  specify 'ビットフィールド型は:rol' do
    bit_fields = create_bit_fields do
      register do
        name 'foo'
        bit_field { name 'foo'; bit_assignment width: 1; type :rol; initial_value 0 }
      end
    end

    expect(bit_fields[0]).to have_property(:type, :rol)
  end

  it '揮発性ビットフィールドである' do
    bit_fields = create_bit_fields do
      register do
        name 'foo'
        bit_field { name 'foo'; bit_assignment width: 1; type :rol; initial_value 0 }
      end
    end

    expect(bit_fields[0]).to have_property(:volatile?, true)
  end

  specify 'アクセス属性は読み出しのみ可' do
    bit_fields = create_bit_fields do
      register do
        name 'foo'
        bit_field { name 'foo'; bit_assignment width: 1; type :rol; initial_value 0 }
      end
    end

    expect(bit_fields[0]).to match_access(:read_only)
  end

  specify '初期値の指定が必要' do
    expect {
      create_bit_fields do
        register do
          name 'foo'
          bit_field { name 'foo'; bit_assignment width: 1; type :rol }
        end
      end
    }.to raise_register_map_error
  end

  describe '参照ビットフィールド' do
    specify '1ビット幅以上のビットフィールが指定可能' do
      expect {
        create_bit_fields do
          register do
            name 'foo'
            bit_field { name 'foo_0'; bit_assignment lsb: 0, width: 2; type :rol; initial_value 0; reference 'foo.foo_1' }
            bit_field { name 'foo_1'; bit_assignment lsb: 8, width: 1; type :rw ; initial_value 0 }
          end
        end
      }.not_to raise_error

      expect {
        create_bit_fields do
          register do
            name 'bar'
            bit_field { name 'bar_0'; bit_assignment lsb: 0, width: 1; type :rol; initial_value 0; reference 'bar.bar_1' }
            bit_field { name 'bar_1'; bit_assignment lsb: 8, width: 2; type :rw ; initial_value 0 }
          end
        end
      }.not_to raise_error
    end
  end
end
