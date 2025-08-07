# frozen_string_literal: true

require "swagger_helper"

# rubocop:disable Metrics/BlockLength
describe "Game of Life API", type: :request do
  path "/api/v1/boards" do
    get "Lists all boards" do
      tags "Boards"
      produces "application/json"
      description "Returns a list of all boards currently stored in the database."

      response "200", "successful" do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: {type: :integer},
              state: {
                type: :array,
                items: {
                  type: :array,
                  items: {type: :integer}
                }
              },
              created_at: {type: :string, format: "date-time"},
              updated_at: {type: :string, format: "date-time"}
            },
            required: %w[id state created_at updated_at]
          }

        run_test!
      end
    end

    post "Creates a board" do
      tags "Boards"
      consumes "application/json"
      produces "application/json"
      description "Creates a new board. Expects a 'state' parameter, which is a 2D array of 0s and 1s."

      parameter name: :board,
        in: :body,
        schema: {
          type: :object,
          properties: {
            board: {
              type: :object,
              properties: {
                state: {
                  type: :array,
                  items: {
                    type: :array,
                    items: {type: :integer, enum: [0, 1]}
                  },
                  example: [[0, 1, 0], [0, 1, 0], [0, 1, 0]]
                }
              },
              required: ["state"]
            }
          },
          required: ["board"]
        }

      response "201", "board created" do
        let(:board) do
          {board: {state: [[0, 1, 0], [0, 1, 0], [0, 1, 0]]}}
        end
        schema type: :object,
          properties: {
            id: {type: :integer}
          },
          required: ["id"]
        run_test!
      end

      response "422", "invalid request" do
        let(:board) { {board: {state: "invalid"}} }
        schema type: :object,
          properties: {
            errors: {
              type: :array,
              items: {type: :string}
            }
          }
        run_test!
      end
    end
  end

  path "/api/v1/boards/{id}" do
    parameter name: :id, in: :path, type: :string, description: "Board ID"

    delete "Deletes a board" do
      tags "Boards"
      description "Deletes the board specified by ID."

      response "204", "board deleted" do
        let(:id) { create(:board).id }
        run_test!
      end

      response "404", "board not found" do
        let(:id) { "invalid" }
        run_test!
      end
    end
  end

  path "/api/v1/boards/{id}/next" do
    parameter name: :id, in: :path, type: :string, description: "Board ID"

    get "Calculates the next state" do
      tags "Boards"
      produces "application/json"
      description "Calculates and returns the next single generation for the specified board."

      response "200", "next state returned" do
        let(:id) { create(:board).id }
        schema type: :object,
          properties: {
            state: {
              type: :array,
              items: {
                type: :array,
                items: {type: :integer}
              }
            }
          }
        run_test!
      end

      response "404", "board not found" do
        let(:id) { "invalid" }
        run_test!
      end
    end
  end

  path "/api/v1/boards/{id}/steps/{n}" do
    parameter name: :id, in: :path, type: :string, description: "Board ID"
    parameter name: :n, in: :path, type: :integer, description: "Number of steps (generations)"

    get "Calculates state after N steps" do
      tags "Boards"
      produces "application/json"
      description "Calculates the state of the board after 'n' generations."

      response "200", "state after n steps returned" do
        let(:id) { create(:board).id }
        let(:n) { 2 }
        schema type: :object,
          properties: {
            state: {
              type: :array,
              items: {
                type: :array,
                items: {type: :integer}
              }
            }
          }
        run_test!
      end

      response "400", "bad request" do
        let(:id) { create(:board).id }
        let(:n) { 0 }
        run_test!
      end

      response "404", "board not found" do
        let(:id) { "invalid" }
        let(:n) { 5 }
        run_test!
      end
    end
  end

  path "/api/v1/boards/{id}/final" do
    parameter name: :id, in: :path, type: :string, description: "Board ID"

    get "Calculates the final state" do
      tags "Boards"
      produces "application/json"
      description "Attempts to find a final state for the board, which can be either stable or oscillating."

      response "200", "final state returned" do
        let(:id) { create(:board).id }
        schema type: :object,
          properties: {
            state: {
              type: :array,
              items: {
                type: :array,
                items: {type: :integer}
              }
            },
            status: {type: :string, enum: %w[stable oscillating]}
          }
        run_test!
      end

      response "422", "final state not found" do
        # This case is hard to trigger reliably in a test without complex mocks
        # or a known non-terminating pattern and adjusting MAX_ATTEMPTS.
        # The documentation will still reflect its possibility.
        let(:id) { create(:board).id }

        before do
          # Mock the service to always return a new, unique state
          # to prevent stabilization or oscillation, forcing a timeout.
          allow_any_instance_of(GameOfLifeService).to receive(:next_state) do |service|
            # Create a new state that is guaranteed to be different
            new_state = service.instance_variable_get(:@board_state).deep_dup
            new_state[0][0] = (new_state[0][0] + rand(1..100)) # A simple way to ensure it's different
            new_state
          end
        end
        run_test!
      end

      response "404", "board not found" do
        let(:id) { "invalid" }
        run_test!
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
