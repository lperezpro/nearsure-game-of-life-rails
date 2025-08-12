# frozen_string_literal: true

class AddUniqueIndexToBoardsState < ActiveRecord::Migration[8.0]
  def change
    add_index :boards, :state, unique: true
  end
end
