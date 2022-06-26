# frozen_string_literal: true

RSpec.describe 'global/enable_wide_register' do
  include_context 'configuration common'
  include_context 'clean-up builder'

  before(:all) do
    RgGen.enable(:global, :enable_wide_register)
  end

  describe '#enable_wide_register?' do
    specify 'デフォルト値はfalseである' do
      configuration = create_configuration
      expect(configuration).to have_property(:enable_wide_register?, false)
    end

    context '幅広レジスタを許可する場合' do
      it 'trueを返す' do
        configuration = create_configuration(enable_wide_register: true)
        expect(configuration).to have_property(:enable_wide_register?, true)

        [
          /true/i, /yes/i, /on/i
        ].each do |pattern|
          value = random_string(pattern)
          configuration = create_configuration(enable_wide_register: value)
          expect(configuration).to have_property(:enable_wide_register?, true)

          value = random_string(pattern).to_sym
          configuration = create_configuration(enable_wide_register: value)
          expect(configuration).to have_property(:enable_wide_register?, true)
        end
      end
    end

    context '幅広レジスタを許可しない場合' do
      it 'falseを返す' do
        configuration = create_configuration(enable_wide_register: false)
        expect(configuration).to have_property(:enable_wide_register?, false)

        [/false/i, /no/i, /off/i].each do |pattern|
          value = random_string(pattern)
          configuration = create_configuration(enable_wide_register: value)
          expect(configuration).to have_property(:enable_wide_register?, false)

          value = random_string(pattern).to_sym
          configuration = create_configuration(enable_wide_register: value)
          expect(configuration).to have_property(:enable_wide_register?, false)
        end
      end
    end
  end

  it '表示可能オブジェクトとして設定値を返す' do
    configuration = create_configuration(enable_wide_register: true)
    expect(configuration.printables[:enable_wide_register]).to be true

    configuration = create_configuration(enable_wide_register: false)
    expect(configuration.printables[:enable_wide_register]).to be false
  end

  describe 'エラーチェック' do
    context 'true/yes/on/false/no/off以外が入力された場合' do
      it 'ConfigurationErrorを起こす' do
        [nil, '', 'foo', :foo, 0, 1, Object.new].each do |value|
          expect {
            create_configuration(enable_wide_register: value)
          }.to raise_configuration_error "cannot convert #{value.inspect} into boolean"
        end
      end
    end
  end
end
