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
require "rails_helper"

RSpec.describe Board, type: :model do
  describe "validations" do
    context "with a valid state" do
      it "is valid with a 2D array of 0s and 1s" do
        board = Board.new(state: [[0, 1], [1, 0]])
        expect(board).to be_valid
      end
    end

    context "with an invalid state" do
      it "is invalid when state is not present" do
        board = Board.new(state: nil)
        expect(board).not_to be_valid
        expect(board.errors[:state]).to include("can't be blank")
      end

      it "is invalid when state is not an array" do
        board = Board.new(state: "not an array")
        expect(board).not_to be_valid
        expect(board.errors[:state]).to include("must be an array")
      end

      it "is invalid when state is not an array of arrays" do
        board = Board.new(state: [0, 1, 0])
        expect(board).not_to be_valid
        expect(board.errors[:state]).to include("must be an array of arrays")
      end

      it "is invalid when state contains elements other than 0 or 1" do
        board = Board.new(state: [[0, 1], [2, 0]])
        expect(board).not_to be_valid
        expect(board.errors[:state]).to include("must only contain 0s and 1s")
      end
    end
  end
end
