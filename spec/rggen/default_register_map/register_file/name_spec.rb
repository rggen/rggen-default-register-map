# frozen_string_literal: true

RSpec.describe 'register_file/name' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:register_file, :name)
    RgGen.enable(:register, :name)
  end

  describe '#name' do
    let(:names) do
      random_strings(/[a-z]\w+/i, 4)
    end

    let(:register_map) do
      create_register_map do
        register_block do
          register_file { name names[0] }
          register_file { name names[1] }
          register_file do
            name names[2]
            register_file { name names[3] }
          end
        end
      end
    end

    it '入力されたレジスタファイル名を返す' do
      expect(register_map.register_files[0]).to have_property(:name, names[0])
      expect(register_map.register_files[1]).to have_property(:name, names[1])
      expect(register_map.register_files[2]).to have_property(:name, names[2])
      expect(register_map.register_files[3]).to have_property(:name, names[3])
    end
  end

  describe '#full_name' do
    let(:register_map) do
      create_register_map do
        register_block do
          register_file do
            name :register_file_0
            register_file do
              name :register_file_1
              register_file do
                name :register_file_2
              end
            end
          end
        end
      end
    end

    it '上位のレジスタファイル名を含めた階層名を返す' do
      expect(register_map.register_files[0]).to have_property(:full_name, 'register_file_0')
      expect(register_map.register_files[1]).to have_property(:full_name, 'register_file_0.register_file_1')
      expect(register_map.register_files[2]).to have_property(:full_name, 'register_file_0.register_file_1.register_file_2')
    end

    it '区切り文字を変更できる' do
      expect(register_map.register_files[2].full_name('/')).to eq 'register_file_0/register_file_1/register_file_2'
      expect(register_map.register_files[2].full_name('_')).to eq 'register_file_0_register_file_1_register_file_2'
    end
  end

  describe 'printable[:name]' do
    let(:register_file) do
      register_map = create_register_map do
        register_block do
          register_file do
            name 'foo'
          end
        end
      end
      register_map.register_files[0]
    end

    it '表示可能オブジェクトとしてレジスタファイル名を返す' do
      allow(register_file).to receive(:array_size).and_return(nil)
      expect(register_file.printables[:name]).to eq 'foo'
    end

    context '配列レジスタファイルの場合' do
      it '表示可能オブジェクトとして、配列の大きさを含むレジスタファイル名を返す' do
        allow(register_file).to receive(:array_size).and_return([1, 2])
        expect(register_file.printables[:name]).to eq 'foo[1][2]'
      end
    end
  end

  describe 'printables[:layer_name]' do
    let(:register_files) do
      register_map = create_register_map do
        register_block do
          register_file do
            name 'foo'
            register_file { name 'bar' }
            register_file { name 'baz' }
          end
        end
      end
      register_map.register_files
    end

    it '表示可能オブジェクトとして、上位階層を含むレジスタファイル名を返す' do
      allow(register_files[0]).to receive(:array_size).and_return([1])
      allow(register_files[1]).to receive(:array_size).and_return([2, 3])
      allow(register_files[2]).to receive(:array_size).and_return(nil)

      expect(register_files[0].printables[:layer_name]).to eq 'foo[1]'
      expect(register_files[1].printables[:layer_name]).to eq 'foo[1].bar[2][3]'
      expect(register_files[2].printables[:layer_name]).to eq 'foo[1].baz'
    end
  end

  describe 'エラーチェック' do
    context 'レジスタファイル名が未入力の場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_register_map do
            register_block { register_file {} }
          end
        }.to raise_register_map_error 'no register file name is given'

        expect {
          create_register_map do
            register_block { register_file { name nil } }
          end
        }.to raise_register_map_error 'no register file name is given'

        expect {
          create_register_map do
            register_block { register_file { name '' } }
          end
        }.to raise_register_map_error 'no register file name is given'
      end
    end

    context 'レジスタファイル名が入力パターンに合致しない場合' do
      it 'RegisterMapErrorを起こす' do
        [
          random_string(/[0-9][a-z_]/i),
          random_string(/[a-z_][[:punct:]&&[^_]][0-9a-z_]/i),
          random_string(/[a-z_]\s+[a-z_]/i)
        ].each do |illegal_name|
          expect {
            create_register_map do
              register_block { register_file { name illegal_name } }
            end
          }.to raise_register_map_error "illegal input value for register file name: #{illegal_name.inspect}"
        end
      end
    end

    context '同一レジスタブロック内で、レジスタファイル名に重複がある場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_register_map do
            register_block do
              register_file { name :foo }
              register_file { name :foo }
            end
          end
        }.to raise_register_map_error 'duplicated register file name: foo'

        expect {
          create_register_map do
            register_block do
              register { name :foo }
              register_file { name :foo }
            end
          end
        }.to raise_register_map_error 'duplicated register file name: foo'
      end
    end

    context '同一レジスタファイル内で、レジスタファイル名に重複がある場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_register_map do
            register_block do
              register_file do
                name :foo
                register_file { name :bar }
                register_file { name :bar }
              end
            end
          end
        }.to raise_register_map_error 'duplicated register file name: bar'

        expect {
          create_register_map do
            register_block do
              register_file do
                name :foo
                register { name :bar }
                register_file { name :bar }
              end
            end
          end
        }.to raise_register_map_error 'duplicated register file name: bar'
      end
    end

    context '異なるレジスタブロック間で、レジスタファイル名に重複がある場合' do
      it 'RegisterMapErrorを起こさない' do
        expect {
          create_register_map do
            register_block { register_file { name :foo } }
            register_block { register_file { name :foo } }
          end
        }.not_to raise_error

        expect {
          create_register_map do
            register_block { register { name :foo } }
            register_block { register_file { name :foo } }
          end
        }.not_to raise_error
      end
    end

    context '異なるレジスタファイル間で、レジスタファイル名に重複がある場合' do
      it 'RegisterMapErrorを起こさない' do
        expect {
          create_register_map do
            register_block do
              register_file do
                name :foo
                register_file { name :baz }
              end
              register_file do
                name :bar
                register_file { name :baz }
              end
            end
          end
        }.not_to raise_error

        expect {
          create_register_map do
            register_block do
              register_file do
                name :foo
                register { name :baz }
              end
              register_file do
                name :bar
                register_file { name :baz }
              end
            end
          end
        }.not_to raise_error
      end
    end
  end
end
