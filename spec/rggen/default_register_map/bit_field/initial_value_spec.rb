# frozen_string_literal: true

RSpec.describe 'bit_field/initial_value' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.define_simple_feature(:bit_field, :settings) do
      register_map do
        property :settings
        build { |value| @settings = value }
      end
    end

    RgGen.enable(:global, [:address_width, :enable_wide_register])
    RgGen.enable(:register_block, :bus_width)
    RgGen.enable(:register_file, :size)
    RgGen.enable(:register, :size)
    RgGen.enable(:bit_field, [:bit_assignment, :settings, :initial_value].shuffle)
  end

  after(:all) do
    RgGen.delete(:bit_field, :settings)
  end

  def create_bit_field(setting_values, width, **kwargs)
    allow(RgGen::Core::RegisterMap::Component)
      .to receive(:new)
      .and_wrap_original do |m, *args, &b|
        m.call(*args).tap do |c|
          if c.register?
            allow(c)
              .to receive(:settings)
              .and_return({ support_array: true })
          end
          b.call(c)
        end
      end

    register_map = create_register_map do
      register_block do
        register_file do
          size kwargs[:register_file_size] if kwargs.key?(:register_file_size)
          register do
            size kwargs[:register_size] if kwargs.key?(:register_size)
            bit_field do
              settings initial_value: setting_values
              initial_value kwargs[:initial_value] if kwargs.key?(:initial_value)
              if kwargs.key?(:sequence_size) && kwargs[:sequence_size] > 0
                bit_assignment width:, lsb: 0, sequence_size: kwargs[:sequence_size]
              else
                bit_assignment width:, lsb: 0
              end
            end
          end
        end
      end
    end

    register_map.bit_fields.first
  end

  def random_sequence_size
    [0, 1, 2].sample
  end

  let(:default_settings) do
    { require: false }
  end

  context '入力が単一の数字の場合' do
    specify '#initial_valueで入力値を取得できる' do
      {
        1 => [0, 1],
        2 => [-2, -1, 0, 1, 3],
        3 => [-4, -1, 0, 1, 7]
      }.each do |width, values|
        values.each do |value|
          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: random_sequence_size, initial_value: value
            )
          expect(bit_field).to have_property(:initial_value, value)

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: random_sequence_size, initial_value: value.to_f
            )
          expect(bit_field).to have_property(:initial_value, value)

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: random_sequence_size, initial_value: value.to_s
            )
          expect(bit_field).to have_property(:initial_value, value)

          value.negative? && next

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: random_sequence_size, initial_value: format('0x%x', value)
            )
          expect(bit_field).to have_property(:initial_value, value)
        end
      end
    end

    specify '#initial_valuesはnilを返す' do
      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: random_sequence_size, initial_value: 0
        )
      expect(bit_field).to have_property(:initial_values, nil)
    end

    specify '固定化された初期値である' do
      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: random_sequence_size, initial_value: 0
        )
      expect(bit_field).to have_property(:fixed_initial_value?, true)
    end

    specify '配列になっている初期値ではない' do
      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: random_sequence_size, initial_value: 0
        )
      expect(bit_field).to have_property(:initial_value_array?, false)
    end
  end

  context '入力がHashでdefaultに値が設定されている場合' do
    specify '#initial_valueでdefaltに指定された値を取得できる' do
      {
        1 => [0, 1],
        2 => [-2, -1, 0, 1, 3],
        3 => [-4, -1, 0, 1, 7]
      }.each do |width, values|
        values.each do |value|
          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: random_sequence_size, initial_value: { default: value }
            )
          expect(bit_field).to have_property(:initial_value, value)

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: random_sequence_size, initial_value: { default: value.to_f }
            )
          expect(bit_field).to have_property(:initial_value, value)

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: random_sequence_size, initial_value: { default: value.to_s }
            )
          expect(bit_field).to have_property(:initial_value, value)

          value.negative? && next

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: random_sequence_size, initial_value: { default: format('0x%x', value) }
            )
          expect(bit_field).to have_property(:initial_value, value)
        end
      end
    end

    specify '入力が文字列の場合も対応する' do
      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: random_sequence_size, initial_value: 'default: 0'
        )
      expect(bit_field).to have_property(:initial_value, 0)

      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: random_sequence_size, initial_value: 'default: 0x1'
        )
      expect(bit_field).to have_property(:initial_value, 1)
    end

    specify '#initial_valuesはnilを返す' do
      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: random_sequence_size, initial_value: { default: 0 }
        )
      expect(bit_field).to have_property(:initial_values, nil)
    end

    specify '固定化された初期値ではない' do
      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: random_sequence_size, initial_value: { default: 0 }
        )
      expect(bit_field).to have_property(:fixed_initial_value?, false)
    end

    context '単一ビットフィールドの場合' do
      specify '配列になっている初期値ではない' do
        bit_field =
          create_bit_field(
            default_settings, 1, initial_value: { default: 0 }
          )
        expect(bit_field).to have_property(:initial_value_array?, false)
      end
    end

    context '連続ビットフィールドまたは配列レジスタの場合' do
      specify '配列になっている初期値である' do
        bit_field =
          create_bit_field(
            default_settings, 1,
            sequence_size: 1, initial_value: { default: 0 }
          )
        expect(bit_field).to have_property(:initial_value_array?, true)

        bit_field =
          create_bit_field(
            default_settings, 1,
            register_file_size: 1, initial_value: { default: 0 }
          )
        expect(bit_field).to have_property(:initial_value_array?, true)

        bit_field =
          create_bit_field(
            default_settings, 1,
            register_size: 1, initial_value: { default: 0 }
          )
        expect(bit_field).to have_property(:initial_value_array?, true)

        bit_field =
          create_bit_field(
            default_settings, 1,
            register_file_size: 1, register_size: 1, sequence_size: 1, initial_value: { default: 0 }
          )
        expect(bit_field).to have_property(:initial_value_array?, true)
      end
    end
  end

  context '入力が配列の場合' do
    specify '#initial_valuesで階層化された入力値を取得できる' do
      {
        1 => [0, 1],
        2 => [-2, -1, 0, 1, 3],
        3 => [-4, -1, 0, 1, 7]
      }.each do |width, values|
        values.each do |value|
          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: 1, initial_value: [value]
            )
          expect(bit_field).to have_property(:initial_values, match([value]))

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: 2, initial_value: [0, value]
            )
          expect(bit_field).to have_property(:initial_values, match([0, value]))

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: 1, initial_value: [value.to_f]
            )
          expect(bit_field).to have_property(:initial_values, match([value]))

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: 2, initial_value: [0, value.to_f]
            )
          expect(bit_field).to have_property(:initial_values, match([0, value]))

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: 1, initial_value: [value.to_s]
            )
          expect(bit_field).to have_property(:initial_values, match([value]))

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: 2, initial_value: [0, value.to_s]
            )
          expect(bit_field).to have_property(:initial_values, match([0, value]))

          value.negative? && next

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: 1, initial_value: [format('0x%x', value)]
            )
          expect(bit_field).to have_property(:initial_values, match([value]))

          bit_field =
            create_bit_field(
              default_settings, width,
              sequence_size: 2, initial_value: [0, format('0x%x', value)]
            )
          expect(bit_field).to have_property(:initial_values, match([0, value]))
        end
      end

      bit_field =
        create_bit_field(
          default_settings, 8,
          register_file_size: [2], initial_value: [0, 1]
        )
      expect(bit_field).to have_property(:initial_values, match([0, 1]))

      bit_field =
        create_bit_field(
          default_settings, 8,
          register_file_size: [2, 2], initial_value: [[0, 1], [2, 3]]
        )
      expect(bit_field).to have_property(:initial_values, match([[0, 1], [2, 3]]))

      bit_field =
        create_bit_field(
          default_settings, 8,
          register_file_size: [2, 2], initial_value: [0, 1, 2, 3]
        )
      expect(bit_field).to have_property(:initial_values, match([[0, 1], [2, 3]]))

      bit_field =
        create_bit_field(
          default_settings, 8,
          register_size: [2], initial_value: [0, 1]
        )
      expect(bit_field).to have_property(:initial_values, match([0, 1]))

      bit_field =
        create_bit_field(
          default_settings, 8,
          register_size: [2, 2], initial_value: [[0, 1], [2, 3]]
        )
      expect(bit_field).to have_property(:initial_values, match([[0, 1], [2, 3]]))

      bit_field =
        create_bit_field(
          default_settings, 8,
          register_size: [2, 2], initial_value: [0, 1, 2, 3]
        )
      expect(bit_field).to have_property(:initial_values, match([[0, 1], [2, 3]]))

      bit_field =
        create_bit_field(
          default_settings, 8,
          register_file_size: [1], register_size: [2], sequence_size: 3,
          initial_value: [[[0, 1, 2], [3, 4, 5]]]
        )
      expect(bit_field)
        .to have_property(
          :initial_values,
          match([[[0, 1, 2], [3, 4, 5]]])
        )

      bit_field =
        create_bit_field(
          default_settings, 8,
          register_file_size: [1], register_size: [2], sequence_size: 3,
          initial_value: [0, 1, 2, 3, 4, 5]
        )
      expect(bit_field)
        .to have_property(
          :initial_values,
          match([[[0, 1, 2], [3, 4, 5]]])
        )
    end

    context 'オプションflatten: tureが指定された場合' do
      specify '平坦化された入力値を取得できる' do
        bit_field =
          create_bit_field(
            default_settings, 8,
            register_file_size: [2], initial_value: [0, 1]
          )
        expect(bit_field.initial_values(flatten: true)).to match([0, 1])

        bit_field =
          create_bit_field(
            default_settings, 8,
            register_file_size: [2, 2], initial_value: [[0, 1], [2, 3]]
          )
        expect(bit_field.initial_values(flatten: true)).to match([0, 1, 2, 3])

        bit_field =
          create_bit_field(
            default_settings, 8,
            register_file_size: [1], register_size: [2], sequence_size: 3,
            initial_value: [[[0, 1, 2], [3, 4, 5]]]
          )
        expect(bit_field.initial_values(flatten: true)).to match([0, 1, 2, 3, 4, 5])
      end
    end

    specify '入力が \',\'、 または、改行区切りの文字列に対応する' do
      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: 2, initial_value: '0, 1'
        )
      expect(bit_field).to have_property(:initial_values, match([0, 1]))

      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: 2, initial_value: "0\n1"
        )
      expect(bit_field).to have_property(:initial_values, match([0, 1]))

      bit_field =
        create_bit_field(
          default_settings, 2,
          sequence_size: 3, initial_value: "0,1\n2"
        )
      expect(bit_field).to have_property(:initial_values, match([0, 1, 2]))

      bit_field =
        create_bit_field(
          default_settings, 3,
          register_file_size: [2], register_size: [2], sequence_size: 2,
          initial_value: '0, 1, 2, 3, 4, 5, 6, 7'
        )
      expect(bit_field)
        .to have_property(
          :initial_values,
          match([[[0, 1], [2, 3]], [[4, 5], [6, 7]]]))
    end

    specify '#initial_valueはnilを返す' do
      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: 1, initial_value: [0]
        )
      expect(bit_field).to have_property(:initial_value, nil)
    end

    specify '固定化された初期値である' do
      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: 1, initial_value: [0]
        )
      expect(bit_field).to have_property(:fixed_initial_value?, true)
    end

    specify '配列になっている初期値である' do
      bit_field =
        create_bit_field(
          default_settings, 1,
          sequence_size: 1, initial_value: [0]
        )
      expect(bit_field).to have_property(:initial_value_array?, true)
    end
  end

  describe 'initial_value?' do
    it '初期値が設定されたかどうかを返す' do
      bit_field = create_bit_field(default_settings, 1)
      expect(bit_field).to have_property(:initial_value?, false)

      bit_field = create_bit_field(default_settings, 1, initial_value: nil)
      expect(bit_field).to have_property(:initial_value?, false)

      bit_field = create_bit_field(default_settings, 1, initial_value: '')
      expect(bit_field).to have_property(:initial_value?, false)

      bit_field = create_bit_field(default_settings, 1, initial_value: 1)
      expect(bit_field).to have_property(:initial_value?, true)

      bit_field = create_bit_field(default_settings, 1, initial_value: { default: 1 })
      expect(bit_field).to have_property(:initial_value?, true)

      bit_field = create_bit_field(default_settings, 1, sequence_size: 1, initial_value: [1])
      expect(bit_field).to have_property(:initial_value?, true)
    end
  end

  describe '#printables[:initial_value]' do
    context '初期値が設定されている場合' do
      it '表示可能オブジェクトとして、設定された初期値を返す' do
        bit_field = create_bit_field(default_settings, 1, initial_value: 0)
        expect(bit_field.printables[:initial_value]).to eq '0x0'

        bit_field = create_bit_field(default_settings, 8, initial_value: 0xab)
        expect(bit_field.printables[:initial_value]).to eq '0xab'

        bit_field = create_bit_field(default_settings, 11, initial_value: 0xab)
        expect(bit_field.printables[:initial_value]).to eq '0x0ab'

        bit_field = create_bit_field(default_settings, 1, initial_value: { default: 0 })
        expect(bit_field.printables[:initial_value]).to eq 'default: 0x0'

        bit_field =
          create_bit_field(
            default_settings, 1,
            sequence_size: 2, initial_value: [0, 1]
          )
        expect(bit_field.printables[:initial_value]).to match(['0x0', '0x1'])

        bit_field =
          create_bit_field(
            default_settings, 3,
            register_file_size: [2], register_size: [2], sequence_size: 2,
            initial_value: [[[0, 1], [2, 3]], [[4, 5], [6, 7]]]
          )
        expect(bit_field.printables[:initial_value])
          .to match([[['0x0', '0x1'], ['0x2', '0x3']], [['0x4', '0x5'], ['0x6', '0x7']]])
      end
    end

    context '初期値が未設定の場合' do
      it 'nilを返す' do
        bit_field = create_bit_field(default_settings, 1)
        expect(bit_field.printables[:initial_value]).to be_nil

        bit_field = create_bit_field(default_settings, 8)
        expect(bit_field.printables[:initial_value]).to be_nil

        bit_field = create_bit_field(default_settings, 11)
        expect(bit_field.printables[:initial_value]).to be_nil
      end
    end
  end

  describe 'エラーチェック' do
    context '入力が整数に変換できない場合' do
      it 'SourceErrorを起こす' do
        [true, false, 'foo', '0xef_gh', Object.new].each do |value|
          expect {
            create_bit_field(default_settings, 1, initial_value: value)
          }.to raise_source_error "cannot convert #{value.inspect} into initial value"

          expect {
            create_bit_field(default_settings, 1, initial_value: { default: value })
          }.to raise_source_error "cannot convert #{value.inspect} into initial value"

          expect {
            create_bit_field(
              default_settings, 1,
              sequence_size: 1, initial_value: [value])
          }.to raise_source_error "cannot convert #{value.inspect} into initial value"

          expect {
            create_bit_field(
              default_settings, 1,
              sequence_size: 2, initial_value: [0, value])
          }.to raise_source_error "cannot convert #{value.inspect} into initial value"
        end

        expect {
          create_bit_field(
            default_settings, 1, initial_value: { default: nil }
          )
        }.to raise_source_error 'cannot convert nil into initial value'

        expect {
          create_bit_field(
            default_settings, 1, sequence_size: 1, initial_value: [nil]
          )
        }.to raise_source_error 'cannot convert nil into initial value'

        expect {
          create_bit_field(
            default_settings, 1, sequence_size: 2, initial_value: [0, nil]
          )
        }.to raise_source_error 'cannot convert nil into initial value'

        expect {
          create_bit_field(
            default_settings, 1, sequence_size: 1, initial_value: { default: [0] }
          )
        }.to raise_source_error 'cannot convert [0] into initial value'
      end
    end

    context '入力がHashでdefaultが指定されていない場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_field(
            default_settings, 1, initial_value: { foo: 0 }
          )
        }.to raise_source_error 'no default value is given'
      end
    end

    context '配列状ではないビットフィールドに対して、配列が入力された場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_field(
            default_settings, 1, initial_value: [0]
          )
        }.to raise_source_error 'arrayed initial value is not allowed for non sequential bit field'
      end
    end

    context '配列状ビットフィールドと初期値配列の大きさが合わない場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_field(default_settings, 1, register_file_size: 1, initial_value: [0, 0])
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(default_settings, 1, register_file_size: 2, initial_value: [0])
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(default_settings, 1, register_size: 1, initial_value: [0, 0])
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(default_settings, 1, register_size: 2, initial_value: [0])
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(default_settings, 1, sequence_size: 1, initial_value: [0, 0])
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(default_settings, 1, sequence_size: 2, initial_value: [0])
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [[[0, 0], [0, 0]]]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [[[0, 0], [0, 0]], [[0, 0], [0, 0]], [[0, 0], [0, 0]]]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [[[0, 0]], [[0, 0], [0, 0]]]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [[[0, 0], [0, 0]], [[0, 0]]]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [[[0, 0], [0, 0], [0, 0]], [[0, 0], [0, 0]]]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [[[0, 0], [0, 0]], [[0, 0], [0, 0], [0, 0]]]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [[[0], [0, 0]], [[0, 0], [0, 0]]]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [[[0, 0], [0, 0]], [[0, 0], [0]]]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [[[0, 0], [0, 0, 0]], [[0, 0], [0, 0]]]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [[[0, 0], [0, 0]], [[0, 0, 0], [0, 0]]]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [0, 0, 0, 0, 0, 0, 0]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'

        expect {
          create_bit_field(
            default_settings, 1,
            register_file_size: 2, register_size: 2, sequence_size: 2,
            initial_value: [0, 0, 0, 0, 0, 0, 0, 0, 0]
          )
        }.to raise_source_error 'size of bit fields and size of initial values are not matched'
      end
    end

    context '初期値の指定が必須の場合で、初期値の指定がない場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_field({ require: true}, 1)
        }.to raise_source_error 'no initial value is given'

        expect {
          create_bit_field({ require: true}, 1, initial_value: nil)
        }.to raise_source_error 'no initial value is given'

        expect {
          create_bit_field({ require: true}, 1, initial_value: '')
        }.to raise_source_error 'no initial value is given'

        need_initial_value = true
        expect {
          create_bit_field({ require: -> { need_initial_value } }, 1)
        }.to raise_source_error 'no initial value is given'

        need_initial_value = false
        expect {
          create_bit_field({ require: -> { need_initial_value } }, 1)
        }.not_to raise_error
      end
    end

    context '入力が最小値未満の場合' do
      it 'SourceErrorを起こす' do
        {
          1 => [0, [-1, -2, rand(-16..-3)]],
          2 => [-2, [-3, -4, rand(-16..-5)]],
          3 => [-4, [-5, -6, rand(-16..-7)]]
        }.each do |width, (min_value, values)|
          values.each do |value|
            expect {
              create_bit_field(default_settings, width, initial_value: value)
            }.to raise_source_error 'input initial value is less than minimum initial value: ' \
                                          "initial value #{value} minimum initial value #{min_value}"

            expect {
              create_bit_field(default_settings, width, initial_value: { default: value })
            }.to raise_source_error 'input initial value is less than minimum initial value: ' \
                                          "initial value #{value} minimum initial value #{min_value}"

            expect {
              create_bit_field(default_settings, width, sequence_size: 1, initial_value: [value])
            }.to raise_source_error 'input initial value is less than minimum initial value: ' \
                                          "initial value #{value} minimum initial value #{min_value}"
          end
        end
      end
    end

    context '入力が最大値を超える場合' do
      it 'SourceErrorを起こす' do
        {
          1 => [1, [2, 3, rand(4..16)]],
          2 => [3, [4, 5, rand(6..16)]],
          3 => [7, [8, 9, rand(10..16)]]
        }.each do |width, (max_value, values)|
          values.each do |value|
            expect {
              create_bit_field(default_settings, width, initial_value: value)
            }.to raise_source_error 'input initial value is greater than maximum initial value: ' \
                                          "initial value #{value} maximum initial value #{max_value}"

            expect {
              create_bit_field(default_settings, width, initial_value: { default: value })
            }.to raise_source_error 'input initial value is greater than maximum initial value: ' \
                                          "initial value #{value} maximum initial value #{max_value}"

            expect {
              create_bit_field(default_settings, width, sequence_size: 1, initial_value: [value])
            }.to raise_source_error 'input initial value is greater than maximum initial value: ' \
                                          "initial value #{value} maximum initial value #{max_value}"
          end
        end
      end
    end

    context 'valid_condition設定の指定があり' do
      let(:setting) do
        condition = proc do |v|
          min = 2**bit_field.width - 3
          max = 2**bit_field.width - 2
          (min..max).include?(v)
        end
        { valid_condition: condition }
      end

      context '与えられたブロックの評価結果が真の場合' do
        it 'SourceErrorを起こさない' do
          expect {
            create_bit_field(setting, 3, initial_value: 5)
          }.not_to raise_error

          expect {
            create_bit_field(setting, 3, initial_value: 6)
          }.not_to raise_error

          expect {
            create_bit_field(setting, 3, initial_value: { default: 5 })
          }.not_to raise_error

          expect {
            create_bit_field(setting, 3, sequence_size: 1, initial_value: [5])
          }.not_to raise_error
        end
      end

      context '評価結果が偽の場合' do
        it 'SourceErrorを起こす' do
          expect {
            create_bit_field(setting, 3, initial_value: 4)
          }.to raise_source_error 'does not match the valid initial value condition: 4'

          expect {
            create_bit_field(setting, 3, initial_value: 7)
          }.to raise_source_error 'does not match the valid initial value condition: 7'

          expect {
            create_bit_field(setting, 3, initial_value: { default: 4 })
          }.to raise_source_error 'does not match the valid initial value condition: 4'

          expect {
            create_bit_field(setting, 3, sequence_size: 1, initial_value: [4])
          }.to raise_source_error 'does not match the valid initial value condition: 4'
        end
      end
    end
  end
end
