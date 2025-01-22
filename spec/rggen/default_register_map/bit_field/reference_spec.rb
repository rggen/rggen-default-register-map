# frozen_string_literal: true

RSpec.describe 'bit_field/reference' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.define_simple_feature(:register_file, :array) do
      register_map do
        property :array?, default: false
        property :array_size, default: nil
        build { |value| @array, @array_size = value }
      end
    end
    RgGen.define_simple_feature(:register, :array) do
      register_map do
        property :array?, default: false
        property :array_size, default: nil
        build { |value| @array, @array_size = value }
      end
    end
    RgGen.define_simple_feature(:bit_field, :settings) do
      register_map do
        property :settings
        build { |value| @settings = value }
      end
    end
    RgGen.define_simple_feature(:bit_field, :width) do
      register_map do
        property :width, default: 1
        build { |value| @width = value }
      end
    end
    RgGen.define_simple_feature(:bit_field, :sequential) do
      register_map do
        property :sequential?, default: false
        property :sequence_size, default: 0
        build { |value| @sequential, @sequence_size = value }
      end
    end
    RgGen.define_simple_feature(:bit_field, :reserved) do
      register_map do
        property :reserved?, default: false
        build { |value| @reserved = value }
      end
    end
  end

  before(:all) do
    RgGen.enable(:register_file, [:name, :array])
    RgGen.enable(:register, [:name, :array])
    RgGen.enable(:bit_field, [:name, :reference, :settings, :width, :sequential, :reserved])
  end

  after(:all) do
    RgGen.delete(:register_file, :array)
    RgGen.delete(:register, :array)
    RgGen.delete(:bit_field, [:settings, :width, :sequential, :reserved])
  end

  def create_bit_fields(&block)
    create_register_map { register_block(&block) }.bit_fields
  end

  let(:default_settings) do
    { reference: { use: true } }
  end

  describe '#reference' do
    it '指定された参照ビットフィールドを返す' do
      bit_fields = create_bit_fields do
        register do
          name 'foo_0'
          bit_field { name 'foo_0_0'; reference 'foo_0.foo_0_1'; settings default_settings }
          bit_field { name 'foo_0_1' }
        end
      end
      expect(bit_fields[0]).to have_property(:reference, equal(bit_fields[1]))

      bit_fields = create_bit_fields do
        register do
          name 'foo_0'
          bit_field { name 'foo_0_0' }
          bit_field { name 'foo_0_1'; reference 'foo_0.foo_0_0'; settings default_settings }
        end
      end
      expect(bit_fields[1]).to have_property(:reference, equal(bit_fields[0]))

      bit_fields = create_bit_fields do
        register do
          name 'foo_0'
          bit_field { name 'foo_0_0' }
        end
        register do
          name 'foo_1'
          bit_field { name 'foo_1_0'; reference 'foo_0.foo_0_0'; settings default_settings }
        end
      end
      expect(bit_fields[1]).to have_property(:reference, equal(bit_fields[0]))

      bit_fields = create_bit_fields do
        register do
          name 'foo_0'
          bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; settings default_settings }
        end
        register do
          name 'foo_1'
          bit_field { name 'foo_1_0' }
        end
      end
      expect(bit_fields[0]).to have_property(:reference, equal(bit_fields[1]))

      bit_fields = create_bit_fields do
        register do
          name 'foo_0'
          bit_field { name 'foo_0_0'; reference 'foo_1'; settings default_settings }
        end
        register do
          name 'foo_1'
          bit_field {}
        end
      end
      expect(bit_fields[0]).to have_property(:reference, equal(bit_fields[1]))

      bit_fields = create_bit_fields do
        register_file do
          name 'foo_0'
          register do
            name 'foo_0_0'
            bit_field { name 'foo_0_0_0'; reference 'foo_0.foo_0_1.foo_0_1_0'; settings default_settings }
          end
          register do
            name 'foo_0_1'
            bit_field { name 'foo_0_1_0' }
          end
        end
      end
      expect(bit_fields[0]).to have_property(:reference, equal(bit_fields[1]))

      bit_fields = create_bit_fields do
        register do
          name 'foo_0'
          bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0.foo_1_0_0'; settings default_settings }
        end
        register_file do
          name 'foo_1'
          register do
            name 'foo_1_0'
            bit_field { name 'foo_1_0_0' }
          end
        end
      end
      expect(bit_fields[0]).to have_property(:reference, equal(bit_fields[1]))

      bit_fields = create_bit_fields do
        register_file do
          name 'foo_0'
          register do
            name 'foo_0_0'
            bit_field { name 'foo_0_0_0'; reference 'foo_1.foo_1_0'; settings default_settings }
          end
        end
        register do
          name 'foo_1'
          bit_field { name 'foo_1_0' }
        end
      end
      expect(bit_fields[0]).to have_property(:reference, equal(bit_fields[1]))
    end

    context '参照ビットフィールドが指定されていない場合' do
      specify '呼び出してもエラーにならない' do
        bit_fields = create_bit_fields do
          register do
            name 'foo_0'
            bit_field { name 'foo_0_0'; settings default_settings }
            bit_field { name 'foo_0_1'; reference ''; settings default_settings }
            bit_field { name 'foo_0_2'; reference nil; settings default_settings }
          end
        end
        expect {
          bit_fields[0].reference
          bit_fields[1].reference
          bit_fields[2].reference
        }.not_to raise_error
      end
    end
  end

  describe '#reference?' do
    it '参照ビットフィールドを持つかどうかを示す' do
      bit_fields = create_bit_fields do
        register do
          name 'foo_0'
          bit_field { name 'foo_0_0'; reference 'foo_0.foo_0_2'; settings default_settings }
          bit_field { name 'foo_0_1'; reference 'foo_0.foo_0_2'; settings reference: { use: false } }
          bit_field { name 'foo_0_2'; settings default_settings }
        end
      end
      expect(bit_fields[0]).to have_property(:reference?, true)
      expect(bit_fields[1]).to have_property(:reference?, false)
      expect(bit_fields[2]).to have_property(:reference?, false)
    end
  end

  describe '#printables[:reference]' do
    context '参照ビットフィールドが設定されている場合' do
      it '表示可能オブジェクトとして、参照ビットフィールド名を返す' do
        bit_fields = create_bit_fields do
          register do
            name 'foo_0'
            bit_field { name 'foo_0_0'; reference 'foo_0.foo_0_1'; settings default_settings }
            bit_field { name 'foo_0_1' }
          end
        end
        expect(bit_fields[0].printables[:reference]).to eq 'foo_0.foo_0_1'
      end
    end

    context '参照ビットフィールドが設定されていない場合' do
      it 'nilを返す' do
        bit_fields = create_bit_fields do
          register do
            name 'foo_0'
            bit_field { name 'foo_0_0'; settings default_settings }
          end
        end
        expect(bit_fields[0].printables[:reference]).to be_nil
      end
    end
  end

  describe 'エラーチェック' do
    context '参照ビットフィールド名が入力パターンに合致しない場合' do
      it 'SourceErrorを起こす' do
        [
          0,
          '0foo',
          'foo.0',
          'foo.0bar',
          'foo/bar',
          'foo?.bar',
          'foo.bar?',
          'foo bar'
        ].each do |input_value|
          expect {
            create_bit_fields do
              register do
                name 'foo_0'
                bit_field { name 'foo_0_0'; reference input_value }
              end
            end
          }.to raise_source_error "illegal input value for reference: #{input_value.inspect}"
        end
      end
    end

    context '自分自身を参照している場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_0.foo_0_0'; settings default_settings }
            end
          end
        }.to raise_source_error 'self reference: foo_0.foo_0_0'
      end
    end

    context '参照ビットフィールドが存在しない場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_1'; settings default_settings }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0' }
            end
          end
        }.to raise_source_error 'no such bit field found: foo_1.foo_1_1'

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_2.foo_1_0'; settings default_settings }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0' }
            end
          end
        }.to raise_source_error 'no such bit field found: foo_2.foo_1_0'

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_3.foo_3_0'; settings default_settings }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0' }
            end
          end
        }.to raise_source_error 'no such bit field found: foo_3.foo_3_0'

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_2'; settings default_settings }
            end
            register do
              name 'foo_1'
              bit_field {}
            end
          end
        }.to raise_source_error 'no such bit field found: foo_2'

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'bar_1.foo_1_0.foo_1_0_0.foo_1_0_0_0'; settings default_settings }
            end
            register_file do
              name 'foo_1'
              register_file do
                name 'foo_1_0'
                register do
                  name 'foo_1_0_0'
                  bit_field { name 'foo_1_0_0_0' }
                end
              end
            end
          end
        }.to raise_source_error 'no such bit field found: bar_1.foo_1_0.foo_1_0_0.foo_1_0_0_0'

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.bar_1_0.foo_1_0_0.foo_1_0_0_0'; settings default_settings }
            end
            register_file do
              name 'foo_1'
              register_file do
                name 'foo_1_0'
                register do
                  name 'foo_1_0_0'
                  bit_field { name 'foo_1_0_0_0' }
                end
              end
            end
          end
        }.to raise_source_error 'no such bit field found: foo_1.bar_1_0.foo_1_0_0.foo_1_0_0_0'

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0.bar_1_0_0.foo_1_0_0_0'; settings default_settings }
            end
            register_file do
              name 'foo_1'
              register_file do
                name 'foo_1_0'
                register do
                  name 'foo_1_0_0'
                  bit_field { name 'foo_1_0_0_0' }
                end
              end
            end
          end
        }.to raise_source_error 'no such bit field found: foo_1.foo_1_0.bar_1_0_0.foo_1_0_0_0'

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0.foo_1_0_0.bar_1_0_0_0'; settings default_settings }
            end
            register_file do
              name 'foo_1'
              register_file do
                name 'foo_1_0'
                register do
                  name 'foo_1_0_0'
                  bit_field { name 'foo_1_0_0_0' }
                end
              end
            end
          end
        }.to raise_source_error 'no such bit field found: foo_1.foo_1_0.foo_1_0_0.bar_1_0_0_0'
      end
    end

    context 'require設定の指定があり、参照ビットフィールドの指定がない場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; settings reference: { use: true, require: true } }
            end
          end
        }.to raise_source_error 'no reference bit field is given'
      end
    end

    context 'require設定が未指定の場合' do
      specify '参照ビットフィールドの指定は必須ではない' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; settings default_settings }
            end
          end
        }.not_to raise_error
      end
    end

    context '配列レジスタファイル/レジスタ中のビットフィールドを参照していて、自身と階層の深さが合わない場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'foo'
              bit_field { name 'foo'; reference 'bar.bar.bar'; settings default_settings }
            end
            register_file do
              name 'bar'
              array [true, [1]]
              register do
                name 'bar'
                bit_field { name 'bar' }
              end
            end
          end
        }.to raise_source_error 'depth of layer is not matched: own 4 reference 5'

        expect {
          create_bit_fields do
            register do
              name 'foo'
              bit_field { name 'foo'; reference 'bar.bar.bar'; settings default_settings }
            end
            register_file do
              name 'bar'
              register do
                name 'bar'
                array [true, [1]]
                bit_field { name 'bar' }
              end
            end
          end
        }.to raise_source_error 'depth of layer is not matched: own 4 reference 5'

        expect {
          create_bit_fields do
            register_file do
              name 'foo'
              register do
                name 'foo'
                bit_field { name 'foo'; reference 'bar.bar'; settings default_settings }
              end
            end
            register do
              name 'bar'
              array [true, [1]]
              bit_field { name 'bar' }
            end
          end
        }.to raise_source_error 'depth of layer is not matched: own 5 reference 4'

        expect {
          create_bit_fields do
            register_file do
              name 'foo'
              register_file do
                name 'foo'
                register do
                  name 'foo'
                  bit_field { name 'foo'; reference 'bar.bar.bar'; settings default_settings }
                end
              end
            end
            register_file do
              name 'bar'
              array [true, [1]]
              register do
                name 'bar'
                bit_field { name 'bar' }
              end
            end
          end
        }.to raise_source_error 'depth of layer is not matched: own 6 reference 5'

        expect {
          create_bit_fields do
            register_file do
              name 'foo'
              register_file do
                name 'foo'
                register do
                  name 'foo'
                  bit_field { name 'foo'; reference 'bar.bar.bar'; settings default_settings }
                end
              end
            end
            register_file do
              name 'bar'
              register do
                name 'bar'
                array [true, [1]]
                bit_field { name 'bar' }
              end
            end
          end
        }.to raise_source_error 'depth of layer is not matched: own 6 reference 5'
      end
    end

    context '自身は単体レジスタファイル/レジスタで、配列レジスタファイル/レジスタを参照している場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; settings default_settings }
            end
            register do
              name 'foo_1'
              array [true, [2]]
              bit_field { name 'foo_1_0' }
            end
          end
        }.to raise_source_error 'bit field within array register is not allowed for reference bit field: foo_1.foo_1_0'

        expect {
          create_bit_fields do
            register_file do
              name 'foo_0'
              register do
                name 'foo_0_0'
                bit_field { name 'foo_0_0_0'; reference 'foo_1.foo_1_0.foo_1_0_0'; settings default_settings }
              end
            end
            register_file do
              name 'foo_1'
              array [true, [2]]
              register do
                name 'foo_1_0'
                bit_field { name 'foo_1_0_0' }
              end
            end
          end
        }.to raise_source_error 'bit field within array register file is not allowed for reference bit field: foo_1.foo_1_0.foo_1_0_0'
      end
    end

    context '自身は配列レジスタファイル/レジスタで、単体レジスタファイル/レジスタを参照している場合' do
      it 'SourceErrorを起こさない' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              array [true, [2]]
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; settings default_settings }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0' }
            end
          end
        }.not_to raise_error

        expect {
          create_bit_fields do
            register_file do
              name 'foo_0'
              array [true, [2]]
              register do
                name 'foo_0_0'
                bit_field { name 'foo_0_0_0'; reference 'foo_1.foo_1_0.foo_1_0_0'; settings default_settings }
              end
            end
            register_file do
              name 'foo_1'
              register do
                name 'foo_1_0'
                bit_field { name 'foo_1_0_0' }
              end
            end
          end
        }.not_to raise_error
      end
    end

    context '自身、参照レジスタともに配列レジスタファイル/レジスタで、配列のサイズが一致する場合' do
      it 'SourceErrorを起こさない' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              array [true, [2]]
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; settings default_settings }
            end
            register do
              name 'foo_1'
              array [true, [2]]
              bit_field { name 'foo_1_0' }
            end

            register do
              name 'foo_2'
              array [true, [2, 3]]
              bit_field { name 'foo_2_0'; reference 'foo_3.foo_3_0'; settings default_settings }
            end
            register do
              name 'foo_3'
              array [true, [2, 3]]
              bit_field { name 'foo_3_0' }
            end

            register_file do
              name 'foo_4'
              array [true, [2]]
              register do
                name 'foo_4_0'
                bit_field { name 'foo_4_0_0'; reference 'foo_5.foo_5_0.foo_5_0_0'; settings default_settings }
              end
            end

            register_file do
              name 'foo_5'
              array [true, [2]]
              register do
                name 'foo_5_0'
                bit_field { name 'foo_5_0_0' }
              end
            end

            register_file do
              name 'foo_6'
              array [true, [2, 1]]
              register do
                name 'foo_6_0'
                bit_field { name 'foo_6_0_0'; reference 'foo_7.foo_7_0.foo_7_0_0'; settings default_settings }
              end
            end

            register_file do
              name 'foo_7'
              array [true, [2, 1]]
              register do
                name 'foo_7_0'
                bit_field { name 'foo_7_0_0' }
              end
            end
          end
        }.not_to raise_error
      end
    end

    context '自身、参照レジスタともに配列レジスタフィアル/レジスタで、配列のサイズが一致しない場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              array [true, [2]]
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; settings default_settings }
            end
            register do
              name 'foo_1'
              array [true, [1]]
              bit_field { name 'foo_1_0' }
            end
          end
        }.to raise_source_error 'array size is not matched: own [2] reference [1]'

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              array [true, [2]]
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; settings default_settings }
            end
            register do
              name 'foo_1'
              array [true, [2, 1]]
              bit_field { name 'foo_1_0' }
            end
          end
        }.to raise_source_error 'array size is not matched: own [2] reference [2, 1]'

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              array [true, [2, 1]]
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; settings default_settings }
            end
            register do
              name 'foo_1'
              array [true, [2]]
              bit_field { name 'foo_1_0' }
            end
          end
        }.to raise_source_error 'array size is not matched: own [2, 1] reference [2]'

        expect {
          create_bit_fields do
            register_file do
              name 'foo_0'
              array [true, [2]]
              register do
                name 'foo_0_0'
                bit_field { name 'foo_0_0_0'; reference 'foo_1.foo_1_0.foo_1_0_0'; settings default_settings }
              end
            end
            register_file do
              name 'foo_1'
              array [true, [1]]
              register do
                name 'foo_1_0'
                bit_field { name 'foo_1_0_0' }
              end
            end
          end
        }.to raise_source_error 'array size is not matched: own [2] reference [1]'

        expect {
          create_bit_fields do
            register_file do
              name 'foo_0'
              array [true, [2, 1]]
              register do
                name 'foo_0_0'
                bit_field { name 'foo_0_0_0'; reference 'foo_1.foo_1_0.foo_1_0_0'; settings default_settings }
              end
            end
            register_file do
              name 'foo_1'
              array [true, [2]]
              register do
                name 'foo_1_0'
                bit_field { name 'foo_1_0_0' }
              end
            end
          end
        }.to raise_source_error 'array size is not matched: own [2, 1] reference [2]'

        expect {
          create_bit_fields do
            register_file do
              name 'foo_0'
              array [true, [2]]
              register do
                name 'foo_0_0'
                bit_field { name 'foo_0_0_0'; reference 'foo_1.foo_1_0.foo_1_0_0'; settings default_settings }
              end
            end
            register_file do
              name 'foo_1'
              array [true, [2, 1]]
              register do
                name 'foo_1_0'
                bit_field { name 'foo_1_0_0' }
              end
            end
          end
        }.to raise_source_error 'array size is not matched: own [2] reference [2, 1]'
      end
    end

    context '自身が単体ビットフィールドで、連番ビットフィールドを参照している場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; settings default_settings }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0'; sequential [true, 2] }
            end
          end
        }.to raise_source_error 'sequential bit field is not allowed for reference bit field: foo_1.foo_1_0'
      end
    end

    context '自身が連番ビットフィールドで、単体ビットフィールドを参照している場合' do
      it 'SourceErrorを起こさない' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; sequential [true, 2]; settings default_settings }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0' }
            end
          end
        }.not_to raise_error
      end
    end

    context '自身、参照ビットフィールドともに連番ビットフィールドで、連番サイズが一致する場合' do
      it 'SourceErrorを起こさない' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; sequential [true, 2]; settings default_settings }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0'; sequential [true, 2] }
            end
          end
        }.not_to raise_error
      end
    end

    context '自身、参照ビットフィールドともに連番ビットフィールドで、連番サイズが一致しない場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; sequential [true, 2]; settings default_settings }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0'; sequential [true, 3] }
            end
          end
        }.to raise_source_error 'sequence size is not matched: own 2 reference 3'
      end
    end

    context '予約済みビットフィールドを参照してる場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; settings default_settings }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0'; reserved true }
            end
          end
        }.to raise_source_error 'refer to reserved bit field: foo_1.foo_1_0'
      end
    end

    describe '幅の確認' do
      context 'width設定の指定があり、参照ビットフィールドの幅がそれより狭い場合' do
        it 'SourceErrorを起こす' do
          expect {
            create_bit_fields do
              register do
                name 'foo'
                bit_field { name 'foo_0'; reference 'foo.foo_1'; width 8; settings reference: { use: true, width: 1 } }
                bit_field { name 'foo_1'; width 1 }
                bit_field { name 'foo_2'; reference 'foo.foo_3'; width 8; settings reference: { use: true, width: 1 } }
                bit_field { name 'foo_3'; width 2 }
              end

              register do
                name 'bar'
                bit_field { name 'bar_0'; reference 'bar.bar_1'; width 8; settings reference: { use: true, width: 2 } }
                bit_field { name 'bar_1'; width 2 }
                bit_field { name 'bar_2'; reference 'bar.bar_3'; width 8; settings reference: { use: true, width: 2 } }
                bit_field { name 'bar_3'; width 3 }
              end
            end
          }.not_to raise_error

          expect {
            create_bit_fields do
              register do
                name 'foo'
                bit_field { name 'foo_0'; reference 'foo.foo_1'; width 8; settings reference: { use: true, width: 2 } }
                bit_field { name 'foo_1'; width 1 }
              end
            end
          }.to raise_source_error '2 bits reference bit field is required: 1 bit(s) width'
        end
      end
    end

    context 'width設定の指定がなく、参照ビットフィールドの幅が自身の幅より狭い場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_fields do
            register do
              name 'foo'
              bit_field { name 'foo_0'; reference 'foo.foo_1'; width 1; settings default_settings }
              bit_field { name 'foo_1'; width 1 }
              bit_field { name 'foo_2'; reference 'foo.foo_3'; width 1; settings default_settings }
              bit_field { name 'foo_3'; width 2 }
            end

            register do
              name 'bar'
              bit_field { name 'bar_0'; reference 'bar.bar_1'; width 2; settings default_settings }
              bit_field { name 'bar_1'; width 2 }
              bit_field { name 'bar_2'; reference 'bar.bar_3'; width 2; settings default_settings }
              bit_field { name 'bar_3'; width 3 }
            end
          end
        }.not_to raise_error

        expect {
          create_bit_fields do
            register do
              name 'foo'
              bit_field { name 'foo_0'; reference 'foo.foo_1'; width 2; settings default_settings }
              bit_field { name 'foo_1'; width 1 }
            end
          end
        }.to raise_source_error '2 bits reference bit field is required: 1 bit(s) width'
      end
    end

    context 'use設定が未指定の場合' do
      specify 'エラーチェックは行われない' do
        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_0.foo_0_0' }
            end
          end
        }.not_to raise_error

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_0.foo_0_1' }
            end
          end
        }.not_to raise_error

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; settings reference: { require: true } }
            end
          end
        }.not_to raise_error

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0' }
            end
            register do
              name 'foo_1'
              array [true, [2]]
              bit_field { name 'foo_1_0' }
            end
          end
        }.not_to raise_error

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              array [true, [2]]
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0' }
            end
            register do
              name 'foo_1'
              array [true, [1]]
              bit_field { name 'foo_1_0' }
            end
          end
        }.not_to raise_error

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0' }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0'; sequential [true, 2] }
            end
          end
        }.not_to raise_error

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0'; sequential [true, 2] }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0'; sequential [true, 3] }
            end
          end
        }.not_to raise_error

        expect {
          create_bit_fields do
            register do
              name 'foo_0'
              bit_field { name 'foo_0_0'; reference 'foo_1.foo_1_0' }
            end
            register do
              name 'foo_1'
              bit_field { name 'foo_1_0'; reserved true }
            end
          end
        }.not_to raise_error

        expect {
          create_bit_fields do
            register do
              name 'foo'
              bit_field { name 'foo_0'; reference 'foo.foo_1'; width 2 }
              bit_field { name 'foo_1'; width 1 }
            end
          end
        }.not_to raise_error
      end
    end
  end
end
