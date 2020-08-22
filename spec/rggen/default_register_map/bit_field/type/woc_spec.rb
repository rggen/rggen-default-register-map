# frozen_string_literal: true

RSpec.describe 'bit_field/type/woc' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:register, [:name, :size, :type])
    RgGen.enable(:bit_field, [:name, :bit_assignment, :initial_value, :reference, :type])
    RgGen.enable(:bit_field, :type, [:woc, :rw])
  end

  def create_bit_fields(&block)
    create_register_map { register_block(&block) }.bit_fields
  end

  specify 'ビットフィールド型は:woc' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 0; type :woc; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to have_property(:type, :woc)
  end

  it '揮発性ビットフィールドである' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 0; type :woc; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to have_property(:volatile?, true)
  end

  specify 'アクセス属性は書き込みのみ可能' do
    bit_fields = create_bit_fields do
      register do
        name :foo
        bit_field { name :foo; bit_assignment lsb: 0; type :woc; initial_value 0 }
      end
    end
    expect(bit_fields[0]).to match_access(:write_only)
  end

  specify '初期値の指定が必要' do
    expect {
      create_bit_fields do
        register do
          name :foo
          bit_field { name :foo_0; bit_assignment lsb: 0, width: 1; type :woc; initial_value 0 }
          bit_field { name :foo_1; bit_assignment lsb: 1, width: 2; type :woc; initial_value 1 }
        end
      end
    }.not_to raise_error

    expect {
      create_bit_fields do
        register do
          name :foo
          bit_field { name :foo_0; bit_assignment lsb: 0, width: 1; type :woc }
        end
      end
    }.to raise_register_map_error
  end

  context '参照ビットフィールドの指定がある場合' do
    specify '同一幅のビットフィールドの指定が必要' do
      expect {
        create_bit_fields do
          register do
            name :foo
            bit_field { name :foo_0; bit_assignment lsb: 0, width: 1; type :woc; reference 'bar.bar_0'; initial_value 0 }
            bit_field { name :foo_1; bit_assignment lsb: 1, width: 2; type :woc; reference 'bar.bar_1'; initial_value 0 }
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
            bit_field { name :foo_0; bit_assignment lsb: 0, width: 1; type :woc; reference 'bar.bar_0'; initial_value 0 }
            bit_field { name :foo_1; bit_assignment lsb: 1, width: 2; type :woc; reference 'bar.bar_1'; initial_value 0 }
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
