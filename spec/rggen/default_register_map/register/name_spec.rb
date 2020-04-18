# frozen_string_literal: true

RSpec.describe 'register/name' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:register_file, :name)
    RgGen.enable(:register, :name)
  end

  describe '#name' do
    let(:names) do
      random_strings(/[_a-z][_a-z0-9]*/i, 4)
    end

    let(:register_map) do
      create_register_map do
        register_block do
          register { name names[0] }
          register { name names[1] }
          register { name names[2] }
          register { name names[3] }
        end
      end
    end

    it '入力されたレジスタ名を返す' do
      expect(register_map.registers[0]).to have_property(:name, names[0])
      expect(register_map.registers[1]).to have_property(:name, names[1])
      expect(register_map.registers[2]).to have_property(:name, names[2])
      expect(register_map.registers[3]).to have_property(:name, names[3])
    end
  end

  describe '#full_name' do
    let(:register_map) do
      create_register_map do
        register_block do
          register { name :register_0 }
          register_file do
            name :register_file_0
            register { name :register_1 }
            register_file do
              name :register_file_1
              register { name :register_2 }
            end
          end
        end
      end
    end

    it 'レジスタファイルを含めた階層名を返す' do
      expect(register_map.registers[0]).to have_property(:full_name, 'register_0')
      expect(register_map.registers[1]).to have_property(:full_name, 'register_file_0.register_1')
      expect(register_map.registers[2]).to have_property(:full_name, 'register_file_0.register_file_1.register_2')
    end

    it '区切り文字を変更できる' do
      expect(register_map.registers[2].full_name('/')).to eq 'register_file_0/register_file_1/register_2'
      expect(register_map.registers[2].full_name('_')).to eq 'register_file_0_register_file_1_register_2'
    end
  end

  it '表示可能オブジェクトとして、レジスタ名を返す' do
    register_map = create_register_map do
      register_block { register { name 'foo' } }
    end
    expect(register_map.registers[0].printables[:name]).to eq 'foo'
  end

  describe 'エラーチェック' do
    context 'レジスタ名が未入力の場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_register_map do
            register_block { register {} }
          end
        }.to raise_register_map_error 'no register name is given'

        expect {
          create_register_map do
            register_block { register { name nil } }
          end
        }.to raise_register_map_error 'no register name is given'

        expect {
          create_register_map do
            register_block { register { name '' } }
          end
        }.to raise_register_map_error 'no register name is given'
      end
    end

    context 'レジスタ名が入力パターンに合致しない場合' do
      it 'RegisterMapErrorを起こす' do
        [
          random_string(/[0-9][a-z_]/i),
          random_string(/[a-z_][[:punct:]&&[^_]][0-9a-z_]/i),
          random_string(/[a-z_]\s+[a-z_]/i)
        ].each do |invalid_name|
          expect {
            create_register_map do
              register_block { register { name invalid_name } }
            end
          }.to raise_register_map_error("illegal input value for register name: #{invalid_name.inspect}")
        end
      end
    end

    context '同一レジスタブロック内でレジスタ名の重複がある場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_register_map do
            register_block do
              register { name 'foo' }
              register { name 'foo' }
            end
          end
        }.to raise_register_map_error('duplicated register name: foo')

        expect {
          create_register_map do
            register_block do
              register_file { name 'foo' }
              register { name 'foo' }
            end
          end
        }.to raise_register_map_error('duplicated register name: foo')
      end
    end

    context '同一レジスタファイル内でレジスタ名の重複がある場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_register_map do
            register_block do
              register_file do
                name 'foo'
                register { name 'bar' }
                register { name 'bar' }
              end
            end
          end
        }.to raise_register_map_error('duplicated register name: bar')

        expect {
          create_register_map do
            register_block do
              register_file do
                name 'foo'
                register_file { name 'bar' }
                register { name 'bar' }
              end
            end
          end
        }.to raise_register_map_error('duplicated register name: bar')
      end
    end

    context '異なるレジスタブロック間でレジスタ名の重複がある場合' do
      it 'RegisterMapErrorを起こさない' do
        expect {
          create_register_map do
            register_block { register { name 'foo' } }
            register_block { register { name 'foo' } }
          end
        }.not_to raise_error

        expect {
          create_register_map do
            register_block { register_file { name 'foo' } }
            register_block { register { name 'foo' } }
          end
        }.not_to raise_error
      end
    end

    context '異なるレジスタファイル間でレジスタ名の重複がある場合' do
      it 'RegisterMapErrorを起こさない' do
        expect {
          create_register_map do
            register_block do
              register_file do
                name 'foo'
                register { name 'baz' }
              end
              register_file do
                name 'bar'
                register { name 'baz' }
              end
            end
          end
        }.not_to raise_error

        expect {
          create_register_map do
            register_block do
              register_file do
                name 'foo'
                register_file { name 'baz' }
              end
              register_file do
                name 'bar'
                register { name 'baz' }
              end
            end
          end
        }.not_to raise_error
      end
    end
  end
end
