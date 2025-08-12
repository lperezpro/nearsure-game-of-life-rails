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
FactoryBot.define do
  factory :step do
    board
    number { 0 }
    state { board.state }
  end
end
