# frozen_string_literal: true

RSpec.describe 'bit_field/type/wos' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:address_width, :enable_wide_register])
    RgGen.enable(:register_block, [:bus_width])
    RgGen.enable(:register, [:name, :size, :type])
    RgGen.enable(:bit_field, [:name, :bit_assignment, :initial_value, :reference, :type])
    RgGen.enable(:bit_field, :type, [:wos])
  end

  def create_bit_fields(&block)
    create_register_map { register_block(&block) }.bit_fields
  end

  specify 'ビットフィール型は:wos' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 0; type :wos; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to have_property(:type, :wos)
  end

  it '揮発性ビットフィールドである' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 0; type :wos; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to have_property(:volatile?, true)
  end

  specify 'アクセス属性は書き込みのみ可能' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 0; type :wos; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to match_access(:write_only)
  end

  specify '初期値の指定は必須' do
    expect {
      create_bit_fields do
        register do
          name :foo
          bit_field { name :foo; bit_assignment lsb: 0; type :wos }
        end
      end
    }.to raise_source_error
  end
end
