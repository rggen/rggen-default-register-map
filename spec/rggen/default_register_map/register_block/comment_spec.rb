# frozen_string_literal: true

RSpec.describe 'register_block/comment' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:register_block, :comment)
  end

  let(:register_block_name) do
    'foo'
  end

  def create_register_block(&)
    register_map = create_register_map do
      register_block(&)
    end

    register_block = register_map.register_blocks.first
    allow(register_block).to receive(:name).and_return(register_block_name)
    register_block
  end

  describe '#comment' do
    it '入力されたコメントを返す' do
      register_block = create_register_block { comment :foo }
      expect(register_block).to have_property(:comment, 'foo')

      register_block = create_register_block { comment 'foo' }
      expect(register_block).to have_property(:comment, 'foo')

      register_block = create_register_block { comment "foo\nbar\nbaz" }
      expect(register_block).to have_property(:comment, "foo\nbar\nbaz")

      register_block = create_register_block { comment ['foo', 'bar', 'baz'] }
      expect(register_block).to have_property(:comment, "foo\nbar\nbaz")
    end

    it '末尾の空白は削除される' do
      register_block = create_register_block { comment 'foo  ' }
      expect(register_block).to have_property(:comment, 'foo')

      register_block = create_register_block { comment "foo\nbar\nbaz\n  " }
      expect(register_block).to have_property(:comment, "foo\nbar\nbaz")

      register_block = create_register_block { comment '  ' }
      expect(register_block).to have_property(:comment, '')
    end

    it 'ERBテンプレートとして処理された結果を返す' do
      register_block = create_register_block do
        comment <<~'COMMENT'
          this register block is <%= register_block.name %>
          <% 4.times do |i| %>
          <%= i %>
          <% end %>
        COMMENT
      end
      expect(register_block).to have_property(:comment, <<~COMMENT)
        this register block is #{register_block_name}
        0
        1
        2
        3
      COMMENT
    end

    context 'コメントが未入力の場合' do
      it '空文字を返す' do
        register_block = create_register_block {}
        expect(register_block).to have_property(:comment, '')

        register_block = create_register_block { comment nil }
        expect(register_block).to have_property(:comment, '')
      end
    end
  end

  describe '#printables[:comment]' do
    context 'コメントが入力された場合' do
      it '入力されたコメントを表示可能オブジェクトとして返す' do
        register_block = create_register_block { comment "foo\nbar\nbaz" }
        expect(register_block.printables[:comment]).to eq "foo\nbar\nbaz"

        register_block = create_register_block do
          comment <<~'COMMENT'
            this register block is <%= register_block.name %>
            <% 4.times do |i| %>
            <%= i %>
            <% end %>
          COMMENT
        end
        expect(register_block.printables[:comment]).to eq <<~COMMENT
          this register block is #{register_block_name}
          0
          1
          2
          3
        COMMENT
      end
    end

    context '#commentが空文字を返す場合' do
      it 'nilを返す' do
        register_block = create_register_block {}
        expect(register_block.printables[:comment]).to be_nil

        register_block = create_register_block { comment '' }
        expect(register_block.printables[:comment]).to be_nil

        register_block = create_register_block { comment '  ' }
        expect(register_block.printables[:comment]).to be_nil
      end
    end
  end
end
