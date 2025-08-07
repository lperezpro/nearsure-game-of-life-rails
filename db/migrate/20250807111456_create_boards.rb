# frozen_string_literal: true

class CreateBoards < ActiveRecord::Migration[8.0]
  def change
    create_table :boards do |t|
      t.jsonb :state, null: false, default: []

      t.timestamps
    end
  end
end
