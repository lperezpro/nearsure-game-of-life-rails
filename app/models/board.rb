# frozen_string_literal: true

# == Schema Information
#
# Table name: boards
#
#  id         :bigint           not null, primary key
#  state      :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Board < ApplicationRecord
  validates :state, presence: true
  validate :validate_state_is_an_array_of_arrays

  private

  # Custom validation to ensure the board's state is a 2D array.
  def validate_state_is_an_array_of_arrays
    # The state must be an array.
    unless state.is_a?(Array)
      errors.add(:state, "must be an array")
      return
    end

    # Every element within the state array must also be an array (a row).
    unless state.all?(Array)
      errors.add(:state, "must be an array of arrays")
      return
    end

    # Every cell in the grid must be either 0 (dead) or 1 (alive).
    unless state.all? { |row| row.all? { |cell| [0, 1].include?(cell) } }
      errors.add(:state, "must only contain 0s and 1s")
    end
  end
end
