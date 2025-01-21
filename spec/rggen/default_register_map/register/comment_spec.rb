# frozen_string_literal: true

RSpec.describe 'register/comment' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:register, :comment)
  end

  let(:register_name) do
    'foo'
  end

  def create_register(&)
    register_map = create_register_map do
      register_block do
        register(&)
      end
    end

    register = register_map.registers.first
    allow(register).to receive(:name).and_return(register_name)
    register
  end

  describe '#comment' do
    it '入力されたコメントを返す' do
      register = create_register { comment :foo }
      expect(register).to have_property(:comment, 'foo')

      register = create_register { comment 'foo' }
      expect(register).to have_property(:comment, 'foo')

      register = create_register { comment "foo\nbar\nbaz" }
      expect(register).to have_property(:comment, "foo\nbar\nbaz")

      register = create_register { comment ['foo', 'bar', 'baz'] }
      expect(register).to have_property(:comment, "foo\nbar\nbaz")
    end

    it '末尾の空白は削除される' do
      register = create_register { comment 'foo  ' }
      expect(register).to have_property(:comment, 'foo')

      register = create_register { comment "foo\nbar\nbaz\n  " }
      expect(register).to have_property(:comment, "foo\nbar\nbaz")

      register = create_register { comment '  ' }
      expect(register).to have_property(:comment, '')
    end

    it 'ERBテンプレートとして処理された結果を返す' do
      register = create_register do
        comment <<~'COMMENT'
          this register is <%= register.name %>
          <% 4.times do |i| %>
          <%= i %>
          <% end %>
        COMMENT
      end
      expect(register).to have_property(:comment, <<~COMMENT)
        this register is #{register_name}
        0
        1
        2
        3
      COMMENT
    end

    context 'コメントが未入力の場合' do
      it '空文字を返す' do
        register = create_register {}
        expect(register).to have_property(:comment, '')

        register = create_register { comment nil }
        expect(register).to have_property(:comment, '')
      end
    end
  end

  describe '#printables[:comment]' do
    context 'コメントが入力された場合' do
      it '入力されたコメントを表示可能オブジェクトとして返す' do
        register = create_register { comment "foo\nbar\nbaz" }
        expect(register.printables[:comment]).to eq "foo\nbar\nbaz"

        register = create_register do
          comment <<~'COMMENT'
            this register is <%= register.name %>
            <% 4.times do |i| %>
            <%= i %>
            <% end %>
          COMMENT
        end
        expect(register.printables[:comment]).to eq <<~COMMENT
          this register is #{register_name}
          0
          1
          2
          3
        COMMENT
      end
    end

    context '#commentが空文字を返す場合' do
      it 'nilを返す' do
        register = create_register {}
        expect(register.printables[:comment]).to be_nil

        register = create_register { comment '' }
        expect(register.printables[:comment]).to be_nil

        register = create_register { comment '  ' }
        expect(register.printables[:comment]).to be_nil
      end
    end
  end
end
