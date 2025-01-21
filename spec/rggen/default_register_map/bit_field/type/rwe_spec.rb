# frozen_string_literal: true

RSpec.describe 'bit_field/type/rwe' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:address_width, :enable_wide_register])
    RgGen.enable(:register_block, [:bus_width])
    RgGen.enable(:register, [:name, :size, :type])
    RgGen.enable(:bit_field, [:name, :bit_assignment, :initial_value, :reference, :type])
    RgGen.enable(:bit_field, :type, [:rw, :rwe])
  end

  def create_bit_fields(&block)
    create_register_map { register_block(&block) }.bit_fields
  end

  specify 'ビットフィール型は:rwe' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo_0; bit_assignment lsb: 0; type :rwe; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to have_property(:type, :rwe)
  end

  context '参照ビットフィールドの指定がない場合' do
    it '揮発性ビットフィールドである' do
      bit_fields = create_bit_fields do
        register do
          name :foo
          bit_field { name :foo_0; bit_assignment lsb: 0; type :rwe; initial_value 0 }
        end
      end
      expect(bit_fields[0]).to have_property(:volatile?, true)
    end
  end

  context '参照ビットフィールドの指定がある場合' do
    it '不揮発性ビットフィールドである' do
      bit_fields = create_bit_fields do
        register do
          name :foo
          bit_field { name :foo_0; bit_assignment lsb: 0; type :rwe; initial_value 0; reference 'foo_1.foo_1' }
        end
        register do
          name :foo_1
          bit_field { name :foo_1; bit_assignment lsb: 1; type :rw; initial_value 0 }
        end
      end
      expect(bit_fields[0]).to have_property(:volatile?, false)
    end
  end

  specify 'アクセス属性は読み書き可' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo_0; bit_assignment lsb: 0; type :rwe; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to match_access(:read_write)
  end

  specify '初期値の指定が必要' do
    expect {
      create_bit_fields do
        register do
          name :foo
          bit_field { name :foo_0; bit_assignment lsb: 0; type :rwe }
        end
      end
    }.to raise_register_map_error
  end

  context '参照ビットフィールドの指定がある場合' do
    specify '1ビット幅以上の参照ビットフィールドの指定が必要' do
      expect {
        create_bit_fields do
          register do
            name :foo_0
            bit_field { name :foo_0; bit_assignment lsb: 0, width: 2; type :rwe; initial_value 0; reference 'foo_1.foo_1' }
          end
          register do
            name :foo_1
            bit_field { name :foo_1; bit_assignment lsb: 0, width: 1; type :rw; initial_value 0 }
          end

          register do
            name :bar_0
            bit_field { name :bar_0; bit_assignment lsb: 0, width: 1; type :rwe; initial_value 0; reference 'bar_1.bar_1' }
          end
          register do
            name :bar_1
            bit_field { name :bar_1; bit_assignment lsb: 0, width: 2; type :rw; initial_value 0 }
          end
        end
      }.not_to raise_error
    end
  end

  context '参照ビットフィールドに同一レジスタ内のビットフィールドを指定した場合' do
    it 'RegisterMapErrorを起こす' do
      expect {
        create_bit_fields do
          register do
            name :foo
            bit_field { name :foo_0; bit_assignment lsb: 0, width: 1; type :rwe; initial_value 0; reference 'foo.foo_1' }
            bit_field { name :foo_1; bit_assignment lsb: 1, width: 1; type :rw; initial_value 0 }
          end
        end
      }.to raise_register_map_error 'bit field within the same register is not allowed for reference bit field: foo.foo_1'
    end
  end
end
