# frozen_string_literal: true

RSpec.describe 'bit_field/labels' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:bit_field, [:bit_assignment, :labels])
  end

  def create_bit_field(&body)
    register_map = create_register_map do
      register_block do
        register(&body)
      end
    end
    register_map.bit_fields[0]
  end

  def label_matchers(labels)
    labels.map { |label| have_attributes(label) }
  end

  def match_labels(labels)
    match(label_matchers(labels))
  end

  def have_labels(labels)
    have_property(:labels, label_matchers(labels))
  end

  describe '#labels' do
    it '入力されたラベルを返す' do
      bit_field = create_bit_field do
        bit_field do
          bit_assignment width: 1
          labels [
            { name: :foo , value: 0x0, comment: 'FOO value' },
            { name: 'bar', value: '0x1' }
          ]
        end
      end

      expect(bit_field).to have_labels([
        { name: 'foo', value: 0x0, comment: 'FOO value' },
        { name: 'bar', value: 0x1 }
      ])

      bit_field = create_bit_field do
        bit_field do
          bit_assignment width: 1
          labels <<~'LABELS'
            name:   foo
            value:  0x0
            comment:   FOO value

            name:   bar
            value:  1
          LABELS
        end
      end

      expect(bit_field).to have_labels([
        { name: 'foo', value: 0x0, comment: 'FOO value' },
        { name: 'bar', value: 0x1 }
      ])
    end
  end

  it '表示可能オブジェクトとして、入力されたラベル一覧を返す' do
    bit_field = create_bit_field do
      bit_field do
        bit_assignment width: 1
        labels [
          { name: 'foo', value: 0x0, comment: 'FOO value' },
          { name: 'bar', value: '0x1' }
        ]
      end
    end

    expect(bit_field.printables[:labels]).to match_labels([
      { name: 'foo', value: 0x0, comment: 'FOO value' },
      { name: 'bar', value: 0x1 }
    ])

    expect(bit_field.printables[:labels].map(&:to_s).join("\n")).to eq <<~'LABELS'.chomp
      name: foo value: 0 comment: FOO value
      name: bar value: 1
    LABELS
  end

  describe 'エラーチェック' do
    context 'ラベル名の指定がない場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_field do
            bit_field do
              bit_assignment width: 1
              labels [value: 0]
            end
          end
        }.to raise_source_error 'no label name is given'
      end
    end

    context 'ラベル名が識別子になっていない場合' do
      it 'SourceErrorを起こす' do
        [
          random_string(/[0-9][_a-z0-9]*/i),
          random_string(/[_a-z][[:punct:]&&[^_]][_a-z0-9]/i),
          random_string(/[_a-z]\s+[_a-z]/i)
        ].each do |name|
          expect {
            create_bit_field do
              bit_field do
                bit_assignment width: 1
                labels [ name: name, value: 0 ]
              end
            end
          }.to raise_source_error "illegal input value for label name: #{name.inspect}"
        end
      end
    end

    context '同一ビットフィールド内でラベル名の重複がある場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_field do
            bit_field do
              bit_assignment width: 1
              labels [
                { name: :foo, value: 0 },
                { name: 'foo', value: 1 }
              ]
            end
          end
        }.to raise_source_error 'duplicated label name: foo'
      end
    end

    context '異なるビットフィールド間でラベル名の重複がある場合' do
      specify 'エラーにならない' do
        expect {
          create_bit_field do
            bit_field do
              bit_assignment width: 1
              labels [name: 'foo', value: 0]
            end

            bit_field do
              bit_assignment width: 1
              labels [name: 'foo', value: 0]
            end
          end
        }.not_to raise_error
      end
    end

    context 'ラベル値の指定がない場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_field do
            bit_field do
              bit_assignment width: 1
              labels [name: :foo]
            end
          end
        }.to raise_source_error 'no label value is given'
      end
    end

    context 'ラベル値が整数に変換できない場合' do
      it 'SourceErrorを起こす' do
        [nil, true, false, 'foo', '0xef,_gh', Object.new].each do |value|
          expect {
            create_bit_field do
              bit_field do
                bit_assignment width: 1
                labels [name: :foo, value: value]
              end
            end
          }.to raise_source_error "cannot convert #{value.inspect} into label value"
        end
      end
    end

    context 'ラベル値が最小値未満の場合' do
      it 'SourceErrorを起こす' do
        {
          1 => [0, [-1, -2, rand(-16..-3)]],
          2 => [-2, [-3, -4, rand(-16..-5)]],
          3 => [-4, [-5, -6, rand(-16..-7)]]
        }.each do |width, (min_value, values)|
          values.each do |value|
            expect {
              create_bit_field do
                bit_field do
                  bit_assignment width: width
                  labels [name: 'foo', value: value]
                end
              end
            }.to raise_source_error 'input label value is less than minimum label value: '\
                                          "label value #{value} minimum label value #{min_value}"
          end
        end
      end
    end

    context 'ラベル値が最大値を超える場合' do
      it 'SourceErrorを起こす' do
        {
          1 => [1, [2, 3, rand(4..16)]],
          2 => [3, [4, 5, rand(6..16)]],
          3 => [7, [8, 9, rand(10..16)]]
        }.each do |width, (max_value, values)|
          values.each do |value|
            expect {
              create_bit_field do
                bit_field do
                  bit_assignment width: width
                  labels [ name: 'foo', value: value ]
                end
              end
            }.to raise_source_error 'input label value is greater than maximum label value: ' \
                                          "label value #{value} maximum label value #{max_value}"
          end
        end
      end
    end

    context 'ラベル値の重複がある場合' do
      it 'SourceErrorを起こす' do
        expect {
          create_bit_field do
            bit_field do
              bit_assignment width: 1
              labels [
                { name: :foo, value: 0 },
                { name: :bar, value: 0 }
              ]
            end
          end
        }.to raise_source_error 'duplicated label value: 0'
      end
    end
  end
end
