# frozen_string_literal: true

RSpec.describe 'bit_field/type/ro' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:address_width, :enable_wide_register])
    RgGen.enable(:register_block, [:bus_width])
    RgGen.enable(:register, [:name, :size, :type])
    RgGen.enable(:bit_field, [:name, :bit_assignment, :initial_value, :reference, :type])
    RgGen.enable(:bit_field, :type, [:ro, :rw])
  end

  def create_bit_fields(&block)
    create_register_map { register_block(&block) }.bit_fields
  end

  specify 'ビットフィールド型は:ro' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 0; type :ro }
      end
    end
    expect(bit_fields[0]).to have_property(:type, :ro)
  end

  it '揮発性ビットフィールドである' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 0; type :ro }
      end
    end
    expect(bit_fields[0]).to have_property(:volatile?, true)
  end

  specify 'アクセス属性は読み込みのみ可' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 0; type :ro }
      end
    end
    expect(bit_fields[0]).to match_access(:read_only)
  end

  specify '初期値の指定は不要' do
    expect {
      create_bit_fields do
        register do
          name :foo
          bit_field { name :foo; bit_assignment lsb: 0; type :ro; initial_value 0 }
        end
        register do
          name :bar
          bit_field { name :bar; bit_assignment lsb: 0; type :ro }
        end
      end
    }.not_to raise_error
  end

  context '参照ビットフィールドの指定がある場合' do
    specify '同一幅のビットフィールドの指定が必要' do
      expect {
        create_bit_fields do
          register do
            name :foo
            bit_field { name :foo_0; bit_assignment lsb: 0, width: 1; type :ro; reference 'bar.bar_0' }
            bit_field { name :foo_1; bit_assignment lsb: 1, width: 2; type :ro; reference 'bar.bar_1' }
          end
          register do
            name :bar
            bit_field { name :bar_0; bit_assignment lsb: 0, width: 1; type :rw; initial_value 0 }
            bit_field { name :bar_1; bit_assignment lsb: 1, width: 2; type :rw; initial_value 0 }
          end
        end
      }.not_to raise_error

      expect {
        create_bit_fields do
          register do
            name :foo
            bit_field { name :foo_0; bit_assignment lsb: 0, width: 1; type :ro; reference 'bar.bar_0' }
            bit_field { name :foo_1; bit_assignment lsb: 1, width: 2; type :ro; reference 'bar.bar_1' }
          end
          register do
            name :bar
            bit_field { name :bar_0; bit_assignment lsb: 0, width: 2; type :rw; initial_value 0 }
            bit_field { name :bar_1; bit_assignment lsb: 2, width: 1; type :rw; initial_value 0 }
          end
        end
      }.to raise_register_map_error
    end
  end
end
