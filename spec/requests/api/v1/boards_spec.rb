# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Api::V1::Boards", type: :request do
  describe "GET /api/v1/boards" do
    it "returns a list of all boards" do
      create_list(:board, 3)
      get api_v1_boards_path, as: :json
      expect(response).to have_http_status(:ok)
      json_response = response.parsed_body
      expect(json_response.size).to eq(3)
    end
  end

  describe "POST /api/v1/boards" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          board: {
            state: [
              [0, 1, 0],
              [0, 1, 0],
              [0, 1, 0]
            ]
          }
        }
      end

      it "creates a new Board" do
        expect do
          post api_v1_boards_path, params: valid_attributes, as: :json
        end.to change(Board, :count).by(1)
      end

      it "returns a created status and the board id" do
        post api_v1_boards_path, params: valid_attributes, as: :json
        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response["id"]).to be_an(Integer)
      end
    end

    context "with invalid parameters" do
      it "does not create a new Board" do
        expect do
          post api_v1_boards_path, params: { board: { state: "invalid" } }, as: :json
        end.not_to change(Board, :count)
      end

      it "returns an unprocessable content status and error message" do
        post api_v1_boards_path, params: { board: { state: "invalid" } }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        json_response = response.parsed_body
        expect(json_response["errors"]).to include("State must be an array")
      end
    end
  end

  describe "DELETE /api/v1/boards/:id" do
    let!(:board) { create(:board) }

    context "when the board exists" do
      it "deletes the board" do
        expect do
          delete api_v1_board_path(board), as: :json
        end.to change(Board, :count).by(-1)
      end

      it "returns a no content status" do
        delete api_v1_board_path(board), as: :json
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when the board does not exist" do
      it "returns a not found status" do
        delete api_v1_board_path(id: 0), as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/v1/boards/:id/next" do
    let(:board) { create(:board) } # Uses the blinker pattern from factory

    context "when the board exists" do
      it "returns the next state of the board" do
        get next_api_v1_board_path(board)
        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expected_next_state = [
          [0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0],
          [0, 1, 1, 1, 0],
          [0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0]
        ]
        expect(json_response["state"]).to eq(expected_next_state)
      end
    end

    context "when the board does not exist" do
      it "returns a not found status" do
        get next_api_v1_board_path(id: 0) # An ID that is unlikely to exist
        expect(response).to have_http_status(:not_found)
        json_response = response.parsed_body
        expect(json_response["error"]).to eq("Board not found")
      end
    end
  end

  describe "GET /api/v1/boards/:id/steps/:n" do
    let(:board) { create(:board) }

    context "with a valid number of steps" do
      it "returns the state after 2 steps" do
        get steps_api_v1_board_path(board, n: 2)
        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        # The blinker pattern returns to its original state after 2 steps
        expect(json_response["state"]).to eq(board.state)
      end
    end

    context "with an invalid number of steps" do
      it "returns a bad request for n=0" do
        get steps_api_v1_board_path(board, n: 0)
        expect(response).to have_http_status(:bad_request)
        json_response = response.parsed_body
        expect(json_response["error"]).to eq("Number of steps (n) must be a positive integer.")
      end
    end

    context "when the board does not exist" do
      it "returns a not found status" do
        get steps_api_v1_board_path(id: 999, n: 5)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/v1/boards/:id/final" do
    context "for a board that becomes stable" do
      # A stable block
      let(:stable_board) do
        create(
          :board,
          state: [
            [0, 0, 0],
            [0, 1, 1],
            [0, 1, 1]
          ]
        )
      end
      it "returns the stable state" do
        get final_api_v1_board_path(stable_board)
        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response["status"]).to eq("stable")
        expect(json_response["state"]).to eq(stable_board.state)
      end
    end

    context "for a board that oscillates" do
      let(:oscillating_board) { create(:board) } # The blinker from the factory

      it "returns the oscillating state" do
        get final_api_v1_board_path(oscillating_board)
        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response["status"]).to eq("oscillating")
      end
    end

    context "when the board does not exist" do
      it "returns a not found status" do
        get final_api_v1_board_path(id: 999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
