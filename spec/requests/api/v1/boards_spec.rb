# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Api::V1::Boards", type: :request do
  include ActiveJob::TestHelper

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

      it "creates a new Board and enqueues a job" do
        expect do
          post api_v1_boards_path, params: valid_attributes, as: :json
        end.to change(Board, :count).by(1).and have_enqueued_job(BoardEvolutionJob)
      end

      it "returns a created status, board id, and status url" do
        post api_v1_boards_path, params: valid_attributes, as: :json
        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        board = Board.last
        expect(json_response["id"]).to eq(board.id)
        expect(json_response["status_url"]).to eq(api_v1_board_url(board))
      end
    end

    context "with invalid parameters" do
      it "does not create a new Board" do
        expect do
          post api_v1_boards_path, params: {board: {state: "invalid"}}, as: :json
        end.not_to change(Board, :count)
      end

      it "returns an unprocessable content status and error message" do
        post api_v1_boards_path, params: {board: {state: "invalid"}}, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        json_response = response.parsed_body
        expect(json_response["errors"]).to include("State must be an array")
      end
    end
  end

  describe "GET /api/v1/boards/:id" do
    let(:board) { create(:board) }

    it "returns the board status" do
      get api_v1_board_path(board)
      expect(response).to have_http_status(:ok)
      json_response = response.parsed_body
      expect(json_response["id"]).to eq(board.id)
      expect(json_response["status"]).to eq("processing")
      expect(json_response["total_steps_calculated"]).to eq(0)
    end
  end

  describe "GET /api/v1/boards/:id/step/:number" do
    let(:board) { create(:board) }
    before do
      # Manually create steps for testing purposes
      board.steps.create!(number: 0, state: board.state)
      board.steps.create!(number: 1, state: [[0, 0, 0], [1, 1, 1], [0, 0, 0]])
    end

    it "retrieves a specific step" do
      get step_api_v1_board_path(board, number: 1)
      expect(response).to have_http_status(:ok)
      json_response = response.parsed_body
      expect(json_response["step"]).to eq(1)
      expect(json_response["state"]).to eq([[0, 0, 0], [1, 1, 1], [0, 0, 0]])
    end

    it "returns not found for a non-existent step" do
      get step_api_v1_board_path(board, number: 99)
      expect(response).to have_http_status(:not_found)
      json_response = response.parsed_body
      expect(json_response["error"]).to include("Step not found")
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

  describe "Legacy endpoints" do
    let(:board) { create(:board) } # Blinker pattern
    let(:next_state_data) do
      [
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 1, 1, 1, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0]
      ]
    end

    describe "Reading from steps" do
      before do
        # Pre-calculate steps for these tests
        board.steps.create!(number: 0, state: board.state)
        board.steps.create!(number: 1, state: next_state_data)
        board.steps.create!(number: 2, state: board.state) # Blinker returns to original state
      end

      describe "GET /api/v1/boards/:id/next" do
        it "returns the state of step 1" do
          get next_api_v1_board_path(board)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["state"]).to eq(next_state_data)
        end
      end

      describe "GET /api/v1/boards/:id/steps/:n" do
        let(:board) { create(:board) }

        context "with a valid number of steps" do
          it "returns the state after 2 steps" do
            get steps_api_v1_board_path(board, n: 2)
            expect(response).to have_http_status(:ok)
            expect(response.parsed_body["state"]).to eq(board.state)
          end
        end

        context "with an invalid number of steps" do
          it "returns a bad request for n=-5" do
            get steps_api_v1_board_path(board, n: -5)
            expect(response).to have_http_status(:not_found)
            json_response = response.parsed_body
            expect(json_response["error"]).to eq("Step not found or not yet calculated.")
          end
        end

        context "when the board does not exist" do
          it "returns a not found status" do
            get steps_api_v1_board_path(id: 999, n: 5)
            expect(response).to have_http_status(:not_found)
          end
        end
      end
    end

    describe "GET /api/v1/boards/:id/final" do
      context "when processing is not complete" do
        before do
          perform_enqueued_jobs { BoardEvolutionJob.perform_later(board.id) }
          board.reload
        end

        it "returns the final state" do
          get final_api_v1_board_path(board)
          expect(response).to have_http_status(:ok)
          json_response = response.parsed_body
          expect(json_response["status"]).to eq("oscillating")
          expect(json_response["final_step"]).to eq(1)
        end
      end

      context "when processing is ongoing" do
        it "returns a processing status" do
          get final_api_v1_board_path(board)
          expect(response).to have_http_status(:accepted)
          json_response = response.parsed_body
          expect(json_response["status"]).to eq("processing")
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
