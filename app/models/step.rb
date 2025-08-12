# frozen_string_literal: true

# == Schema Information
#
# Table name: steps
#
#  id         :bigint           not null, primary key
#  number     :integer          default(0), not null
#  state      :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  board_id   :bigint           not null
#
# Indexes
#
#  index_steps_on_board_id             (board_id)
#  index_steps_on_board_id_and_number  (board_id,number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (board_id => boards.id)
#
class Step < ApplicationRecord
  belongs_to :board, inverse_of: :steps

  validates :number,
    presence: true,
    numericality: {only_integer: true, greater_than_or_equal_to: 0},
    uniqueness: {scope: :board_id}
  validates :state, presence: true
end
