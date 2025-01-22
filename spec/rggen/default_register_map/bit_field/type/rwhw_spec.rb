
# frozen_string_literal: true

RSpec.describe 'bit_field/type/rwhw' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:address_width, :enable_wide_register])
    RgGen.enable(:register_block, [:bus_width])
    RgGen.enable(:register, [:name, :size, :type])
    RgGen.enable(:bit_field, [:name, :bit_assignment, :initial_value, :reference, :type])
    RgGen.enable(:bit_field, :type, [:rw, :rwhw])
  end

  def create_bit_fields(&block)
    create_register_map { register_block(&block) }.bit_fields
  end

  specify 'ビットフィール型は:rwhw' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo_0; bit_assignment lsb: 0; type :rwhw; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to have_property(:type, :rwhw)
  end

  it '揮発性ビットフィールドである' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo_0; bit_assignment lsb: 0; type :rwhw; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to have_property(:volatile?, true)
  end

  specify 'アクセス属性は読み書き可' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo_0; bit_assignment lsb: 0; type :rwhw; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to match_access(:read_write)
  end

  specify '初期値の指定が必要' do
    expect {
      create_bit_fields do
        register do
          name :foo
          bit_field { name :foo_0; bit_assignment lsb: 0; type :rwhw }
        end
      end
    }.to raise_source_error
  end

  context '参照ビットフィールドの指定がある場合' do
    specify '1ビット幅以上の参照ビットフィールドの指定が必要' do
      expect {
        create_bit_fields do
          register do
            name :foo
            bit_field { name :foo_0; bit_assignment lsb: 0, width: 2; type :rwhw; initial_value 0; reference 'foo.foo_1' }
            bit_field { name :foo_1; bit_assignment lsb: 8, width: 1; type :rw; initial_value 0 }
          end

          register do
            name :bar
            bit_field { name :bar_0; bit_assignment lsb: 0, width: 1; type :rwhw; initial_value 0; reference 'bar.bar_1' }
            bit_field { name :bar_1; bit_assignment lsb: 8, width: 2; type :rw; initial_value 0 }
          end
        end
      }.not_to raise_error
    end
  end
end
