# frozen_string_literal: true

require "swagger_helper"

# rubocop:disable Metrics/BlockLength
describe "Game of Life API", type: :request do
  path "/api/v1/boards" do
    get "Lists all boards" do
      tags "Boards"
      produces "application/json"
      description "Returns a list of all boards currently stored in the database, including their current state and evolution status."

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
              status: {type: :string, enum: %w[processing stable oscillating max_attempts_reached]},
              created_at: {type: :string, format: "date-time"},
              updated_at: {type: :string, format: "date-time"}
            },
            required: %w[id state status created_at updated_at]
          }

        before { create_list(:board, 3) }
        run_test!
      end
    end

    post "Creates a board" do
      tags "Boards"
      consumes "application/json"
      produces "application/json"
      description <<~DESC
        Creates a new board from an initial 2D array state.
        This endpoint initiates a background job to calculate the board's evolution.
        The status of the calculation can be tracked via the `status_url` returned.
      DESC

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
            id: {type: :integer},
            status_url: {type: :string, format: :uri, example: "/api/v1/boards/1"}
          },
          required: %w[id status_url]
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

    get "Shows board status" do
      tags "Boards"
      produces "application/json"
      description "Shows the current status of the board's evolution, including whether it's still calculating or finished, and the total number of steps calculated so far."

      response "200", "board status" do
        let(:id) { create(:board).id }
        schema type: :object,
          properties: {
            id: {type: :integer},
            state: {
              type: :array,
              items: {
                type: :array,
                items: {type: :integer}
              }
            },
            status: {type: :string, enum: %w[processing stable oscillating max_attempts_reached]},
            total_steps_calculated: {type: :integer}
          },
          required: %w[id state status total_steps_calculated]
        run_test!
      end

      response "404", "board not found" do
        let(:id) { "invalid" }
        run_test!
      end
    end

    delete "Deletes a board" do
      tags "Boards"
      description "Deletes the board specified by ID and all of its associated step data."

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

  path "/api/v1/boards/{id}/step/{number}" do
    parameter name: :id, in: :path, type: :string, description: "Board ID"
    parameter name: :number, in: :path, type: :integer, description: "Step number (generation)"

    get "Retrieves a specific step" do
      tags "Boards"
      produces "application/json"
      description "Retrieves a previously calculated board state for a specific step number. Step 0 is the initial state."

      response "200", "step found" do
        let(:board_instance) { create(:board) }
        let(:id) { board_instance.id }
        let(:number) { 0 }
        before { board_instance.steps.create!(number: 0, state: board_instance.state) }

        schema type: :object,
          properties: {
            step: {type: :integer},
            state: {
              type: :array,
              items: {
                type: :array,
                items: {type: :integer}
              }
            }
          },
          required: %w[step state]
        run_test!
      end

      response "404", "step not found" do
        let(:id) { create(:board).id }
        let(:number) { 999 }
        run_test!
      end
    end
  end

  path "/api/v1/boards/{id}/next" do
    parameter name: :id, in: :path, type: :string, description: "Board ID"

    get "Gets the next state (step 1)" do
      tags "Boards (Deprecated)"
      produces "application/json"
      description <<~DESC
        **Deprecated:** Use `GET /api/v1/boards/{id}/step/1` instead.

        Retrieves the state of the board after one generation (step 1).
      DESC

      response "200", "next state returned" do
        let(:board_instance) { create(:board) }
        let(:id) { board_instance.id }
        before { board_instance.steps.create!(number: 1, state: [[0, 0, 0], [1, 1, 1], [0, 0, 0]]) }

        schema type: :object,
          properties: {
            step: {type: :integer, example: 1},
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

      response "404", "board or step not found" do
        let(:id) { "invalid" }
        run_test!
      end
    end
  end

  path "/api/v1/boards/{id}/steps/{n}" do
    parameter name: :id, in: :path, type: :string, description: "Board ID"
    parameter name: :n, in: :path, type: :integer, description: "Number of steps (generations)"

    get "Gets state after N steps" do
      tags "Boards (Deprecated)"
      produces "application/json"
      description <<~DESC
        **Deprecated:** Use `GET /api/v1/boards/{id}/step/{n}` instead.

        Retrieves the state of the board after 'n' generations.
      DESC

      response "200", "state after n steps returned" do
        let(:board_instance) { create(:board) }
        let(:id) { board_instance.id }
        let(:n) { 2 }
        before { board_instance.steps.create!(number: 2, state: board_instance.state) }

        schema type: :object,
          properties: {
            step: {type: :integer, example: 2},
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

      response "404", "board or step not found" do
        let(:id) { "invalid" }
        let(:n) { 5 }
        run_test!
      end
    end
  end

  path "/api/v1/boards/{id}/final" do
    parameter name: :id, in: :path, type: :string, description: "Board ID"

    get "Gets the final state" do
      tags "Boards (Deprecated)"
      produces "application/json"
      description <<~DESC
        **Deprecated:** Check the `status` on the main board endpoint `GET /api/v1/boards/{id}` instead.

        Returns the final state of the board if the calculation is complete.
        If the calculation is ongoing, it returns a status indicating it's still processing.
      DESC

      response "200", "final state returned" do
        let(:board_instance) { create(:board, status: :stable) }
        let(:id) { board_instance.id }
        before { board_instance.steps.create!(number: 0, state: board_instance.state) }

        schema type: :object,
          properties: {
            status: {type: :string, enum: %w[stable oscillating max_attempts_reached]},
            final_step: {type: :integer},
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

      response "202", "processing" do
        let(:id) { create(:board, status: :processing).id }
        schema type: :object,
          properties: {
            status: {type: :string, example: "processing"},
            message: {type: :string}
          }
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
