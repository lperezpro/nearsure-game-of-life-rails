# frozen_string_literal: true

class AddStatusToBoards < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL.squish
      CREATE TYPE board_status AS ENUM ('processing', 'stable', 'oscillating', 'max_attempts_reached');
    SQL
    add_column :boards, :status, :board_status, default: "processing", null: false
  end

  def down
    remove_column :boards, :status
    execute <<-SQL.squish
      DROP TYPE board_status;
    SQL
  end
end
