# frozen_string_literal: true

RSpec.describe 'bit_field/type' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:address_width, :enable_wide_register])
    RgGen.enable(:register_block, [:bus_width])
    RgGen.enable(:register, [:name, :size, :type])
    RgGen.enable(:bit_field, [:name, :bit_assignment, :initial_value, :reference, :type])
    RgGen.enable(:bit_field, :type, [:foo, :bar, :baz])
  end

  def create_bit_fields(&block)
    create_register_map { register_block(&block) }.bit_fields
  end

  describe 'ビットフィールド型' do
    before(:all) do
      RgGen.define_list_item_feature(:bit_field, :type, [:foo, :bar, :qux]) do
        register_map {}
      end
    end

    after(:all) do
      delete_register_map_factory
      RgGen.delete(:bit_field, :type, [:foo, :bar, :qux])
    end

    specify '指定した型を #type で取得できる' do
      [
        [:foo, :bar],
        [:FOO, :BAR],
        ['foo', 'bar'],
        [random_string(/foo/i), random_string(/bar/i)],
        [' foo', ' bar'],
        ['foo ', 'bar ']
      ].each do |foo_type, bar_type|
        bit_fields = create_bit_fields do
          register do
            name 'foo_bar'
            bit_field { name 'foo'; bit_assignment lsb: 0; type foo_type }
            bit_field { name 'bar'; bit_assignment lsb: 1; type bar_type }
          end
        end
        expect(bit_fields[0]).to have_property(:type, :foo)
        expect(bit_fields[1]).to have_property(:type, :bar)
      end
    end

    context '型が指定されなかった場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'foo'
              bit_field { name 'foo'; bit_assignment lsb: 0 }
            end
          end
        }.to raise_source_error 'no bit field type is given'

        expect {
          create_bit_fields do
            register do
              name 'foo'
              bit_field { name 'foo'; bit_assignment lsb: 0; type nil }
            end
          end
        }.to raise_source_error 'no bit field type is given'

        expect {
          create_bit_fields do
            register do
              name 'foo'
              bit_field { name 'foo'; bit_assignment lsb: 0; type '' }
            end
          end
        }.to raise_source_error 'no bit field type is given'
      end
    end

    context '有効になっていない型が指定された場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'qux'
              bit_field { name 'qux'; bit_assignment lsb: 0; type :qux }
            end
          end
        }.to raise_source_error 'unknown bit field type: :qux'
      end
    end

    context '未定義の型が指定された場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'baz'
              bit_field { name 'baz'; bit_assignment lsb: 0; type :buz }
            end
          end
        }.to raise_source_error 'unknown bit field type: :buz'
      end
    end
  end

  describe 'アクセス属性' do
    def create_bit_field(&block)
      RgGen.define_list_item_feature(:bit_field, :type, :foo) do
        register_map(&block)
      end
      bit_fields = create_bit_fields do
        register do
          name 'foo'
          bit_field { name 'foo'; bit_assignment lsb: 0; type :foo }
        end
      end

      delete_register_map_factory
      RgGen.delete(:bit_field, :type, :foo)

      bit_fields.first
    end

    describe '.read_write' do
      it '読み書き属性を設定する' do
        bit_field = create_bit_field { read_write }
        expect(bit_field).to match_access(:read_write)
      end
    end

    describe '.read_olny' do
      it '読み取り専用属性を設定する' do
        bit_field = create_bit_field { read_only }
        expect(bit_field).to match_access(:read_only)
      end
    end

    describe '.write_only' do
      it '書き込み専用属性を設定する' do
        bit_field = create_bit_field { write_only }
        expect(bit_field).to match_access(:write_only)
      end
    end

    describe '.reserved' do
      it '予約済み属性を設定する' do
        bit_field = create_bit_field { reserved }
        expect(bit_field).to match_access(:reserved)
      end
    end

    describe '.writable?/.readable?' do
      specify '与えたブロックの評価結果がアクセス属性になる' do
        bit_field = create_bit_field do
          writable? { @writable }
          readable? { @readable }
          build { @writable, @readable = [true, true] }
        end
        expect(bit_field).to match_access(:read_write)

        bit_field = create_bit_field do
          writable? { @writable }
          readable? { @readable }
          build { @writable, @readable = [true, false] }
        end
        expect(bit_field).to match_access(:write_only)

        bit_field = create_bit_field do
          writable? { @writable }
          readable? { @readable }
          build { @writable, @readable = [false, true] }
        end
        expect(bit_field).to match_access(:read_only)

        bit_field = create_bit_field do
          writable? { @writable }
          readable? { @readable }
          build { @writable, @readable = [false, false] }
        end
        expect(bit_field).to match_access(:reserved)
      end
    end

    specify '規定属性は読み書き属性' do
      bit_field = create_bit_field {}
      expect(bit_field).to match_access(:read_write)
    end

    specify '予約済み属性の場合はドキュメント専用' do
      bit_field = create_bit_field { read_write }
      expect(bit_field).not_to be_document_only

      bit_field = create_bit_field { read_only }
      expect(bit_field).not_to be_document_only

      bit_field = create_bit_field { write_only }
      expect(bit_field).not_to be_document_only

      bit_field = create_bit_field { reserved }
      expect(bit_field).to be_document_only
    end
  end

  describe '揮発性' do
    context '.volatileが指定されている場合' do
      before do
        RgGen.define_list_item_feature(:bit_field, :type, :foo) do
          register_map { volatile }
        end
      end

      after do
        delete_register_map_factory
        RgGen.delete(:bit_field, :type, :foo)
      end

      specify 'ビットフィールドは揮発性' do
        bit_fields = create_bit_fields do
          register do
            name 'register_0'
            bit_field { name 'bit_field_0'; bit_assignment lsb: 0; type :foo }
          end
        end

        expect(bit_fields[0]).to have_property(:volatile?, true)
      end
    end

    context '.non_volatileが指定されている場合' do
      before do
        RgGen.define_list_item_feature(:bit_field, :type, :foo) do
          register_map { non_volatile }
        end
      end

      after do
        delete_register_map_factory
        RgGen.delete(:bit_field, :type, :foo)
      end

      specify 'ビットフィールドは不揮発性' do
        bit_fields = create_bit_fields do
          register do
            name 'register_0'
            bit_field { name 'bit_field_0'; bit_assignment lsb: 0; type :foo }
          end
        end

        expect(bit_fields[0]).to have_property(:volatile?, false)
      end
    end

    context '.volatile?にブロックが指定された場合' do
      before do
        RgGen.define_list_item_feature(:bit_field, :type, :foo) do
          register_map do
            volatile? { @volatile }
            build { @volatile = true }
          end
        end

        RgGen.define_list_item_feature(:bit_field, :type, :bar) do
          register_map do
            volatile? { @volatile }
            build { @volatile = false }
          end
        end
      end

      after do
        delete_register_map_factory
        RgGen.delete(:bit_field, :type, [:foo, :bar])
      end

      specify 'ブロックの評価結果がビットフィールドの揮発性' do
        bit_fields = create_bit_fields do
          register do
            name 'register_0'
            bit_field { name 'bit_field_0'; bit_assignment lsb: 0; type :foo }
            bit_field { name 'bit_field_1'; bit_assignment lsb: 1; type :bar }
          end
        end

        expect(bit_fields[0]).to have_property(:volatile?, true)
        expect(bit_fields[1]).to have_property(:volatile?, false)
      end
    end

    context '未指定の場合' do
      before do
        RgGen.define_list_item_feature(:bit_field, :type, :foo) do
          register_map {}
        end
      end

      after do
        delete_register_map_factory
        RgGen.delete(:bit_field, :type, :foo)
      end

      specify 'ビットフィールドは不揮発性' do
        bit_fields = create_bit_fields do
          register do
            name 'register_0'
            bit_field { name 'bit_field_0'; bit_assignment lsb: 0; type :foo }
          end
        end

        expect(bit_fields[0]).to have_property(:volatile?, true)
      end
    end
  end

  describe 'オプションの指定' do
    before do
      RgGen.define_list_item_feature(:bit_field, :type, :foo) do
        register_map do
          property :input_options
          build { |_, options| @input_options = options }
        end
      end
    end

    after do
      delete_register_map_factory
      RgGen.delete(:bit_field, :type, :foo)
    end

    specify 'ビットフィールド型に対するHash型のオプションを指定することができる' do
      bit_fields = create_bit_fields do
        register do
          name 'register_0'
          bit_field { name 'bit_field_0'; bit_assignment width: 1; type [:foo, option_1: :bar] }
          bit_field { name 'bit_field_1'; bit_assignment width: 1; type [:foo, option_1: :bar, option_2: :baz] }
          bit_field { name 'bit_field_2'; bit_assignment width: 1; type 'foo: option_1: bar' }
          bit_field { name 'bit_field_3'; bit_assignment width: 1; type 'foo: option_1: bar, option_2: baz' }
        end
      end

      expect(bit_fields[0].type).to eq :foo
      expect(bit_fields[0].input_options).to match({ option_1: :bar })

      expect(bit_fields[1].type).to eq :foo
      expect(bit_fields[1].input_options).to match({ option_1: :bar, option_2: :baz })

      expect(bit_fields[2].type).to eq :foo
      expect(bit_fields[2].input_options).to match({ option_1: 'bar' })

      expect(bit_fields[3].type).to eq :foo
      expect(bit_fields[3].input_options).to match({ option_1: 'bar', option_2: 'baz' })
    end
  end

  describe '#printables[:type]' do
    before(:all) do
      RgGen.define_list_item_feature(:bit_field, :type, [:foo, :bar]) do
        register_map {}
      end
    end

    after(:all) do
      delete_register_map_factory
      RgGen.delete(:bit_field, :type, [:foo, :bar])
    end

    it '表示可能オブジェクトとして、入力されたビットフィールド型を返す' do
      bit_fields = create_bit_fields do
        register do
          name 'register_0'
          bit_field { name 'bit_field_0'; bit_assignment lsb: 0; type :foo }
          bit_field { name 'bit_field_1'; bit_assignment lsb: 1; type :bar }
        end
      end

      expect(bit_fields[0].printables[:type]).to eq :foo
      expect(bit_fields[1].printables[:type]).to eq :bar
    end
  end
end
