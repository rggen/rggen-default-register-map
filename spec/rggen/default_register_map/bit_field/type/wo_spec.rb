
# frozen_string_literal: true

RSpec.describe 'bit_field/type/wo' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:address_width, :enable_wide_register])
    RgGen.enable(:register_block, [:bus_width])
    RgGen.enable(:register, [:name, :size, :type])
    RgGen.enable(:bit_field, [:name, :bit_assignment, :initial_value, :reference, :type])
    RgGen.enable(:bit_field, :type, [:wo])
  end

  def create_bit_fields(&block)
    create_register_map { register_block(&block) }.bit_fields
  end

  specify 'ビットフィール型は:wo' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 1; type :wo; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to have_property(:type, :wo)
  end

  it '不揮発性ビットフィールドである' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 0; type :wo; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to have_property(:volatile?, false)
  end

  specify 'アクセス属性は書き込みのみ可' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 1; type :wo; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to match_access(:write_only)
  end

  specify '初期値の指定は必要' do
    expect {
      create_bit_fields do
        register do
          name :foo
          bit_field { name :foo; bit_assignment lsb: 1; type :wo }
        end
      end
    }.to raise_source_error
  end

  specify '参照ビットフィールドの指定は不要' do
    expect {
      create_bit_fields do
        register do
          name :foo
          bit_field { name :foo; bit_assignment lsb: 1; type :wo; initial_value 0 }
        end
        register do
          name :bar
          bit_field { name :bar; bit_assignment lsb: 1; type :wo; initial_value 0; reference 'foo.foo' }
        end
      end
    }.not_to raise_error
  end
end
