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
require "rails_helper"

RSpec.describe Step, type: :model do
  describe "associations" do
    it { should belong_to(:board) }
  end

  describe "validations" do
    subject { build(:step) }

    it { should validate_presence_of(:number) }
    it { should validate_numericality_of(:number).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:state) }

    it "validates uniqueness of number per board" do
      existing_step = create(:step)
      new_step = build(:step, board: existing_step.board, number: existing_step.number)
      expect(new_step).not_to be_valid
      expect(new_step.errors[:number]).to include("has already been taken")
    end
  end
end
