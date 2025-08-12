# frozen_string_literal: true

class CreateSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :steps do |t|
      t.references :board, null: false, foreign_key: true
      t.integer :number, null: false, default: 0
      t.jsonb :state, null: false, default: []

      t.timestamps
    end

    # Add an index to speed up lookups by board and step number
    add_index :steps, [:board_id, :number], unique: true
  end
end
