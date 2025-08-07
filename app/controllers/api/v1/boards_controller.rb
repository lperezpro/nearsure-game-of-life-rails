# frozen_string_literal: true

class Api::V1::BoardsController < ApplicationController
  before_action :set_board, only: [:destroy, :next_state, :steps_away, :final_state]

  # GET /api/v1/boards
  # Returns a list of all boards in the database.
  def index
    @boards = Board.all
    render json: @boards, status: :ok
  end

  # POST /api/v1/boards
  # Creates a new board. Expects a 'state' parameter, which is a 2D array of 0s and 1s.
  # On success, returns 201 Created with the new board's ID.
  # On failure, returns 422 Unprocessable Content with validation errors.
  def create
    @board = Board.new(board_params)
    if @board.save
      render json: {id: @board.id}, status: :created
    else
      render json: {errors: @board.errors.full_messages}, status: :unprocessable_content
    end
  end

  # GET /api/v1/boards/:id/next
  # Calculates and returns the next single generation for the specified board.
  def next_state
    service = GameOfLifeService.new(@board.state)
    render json: {state: service.next_state}, status: :ok
  end

  # GET /api/v1/boards/:id/steps/:n
  # Calculates the state of the board after 'n' generations.
  # Returns a 400 Bad Request if 'n' is not a positive integer.
  def steps_away
    n = params[:n].to_i
    current_state = @board.state

    if n <= 0
      return render json: {error: "Number of steps (n) must be a positive integer."}, status: :bad_request
    end

    n.times do
      service = GameOfLifeService.new(current_state)
      current_state = service.next_state
    end

    render json: {state: current_state}, status: :ok
  end

  # GET /api/v1/boards/:id/final
  # Attempts to find a final state for the board, which can be either stable
  # (no longer changes) or oscillating (repeats a cycle of states).
  # It uses a safety break to prevent infinite loops for patterns that do not stabilize.
  def final_state
    current_state = @board.state
    previous_states = {current_state.hash => true}
    # Safety break to prevent infinite loops, configurable via ENV var.
    max_attempts = (ENV["MAX_FINAL_STATE_ATTEMPTS"] || 1000).to_i

    max_attempts.times do
      service = GameOfLifeService.new(current_state)
      next_gen_state = service.next_state

      # If the state hasn't changed, it's stable.
      if next_gen_state == current_state
        return render json: {state: current_state, status: "stable"}, status: :ok
      end

      # If we've seen this state before, it's an oscillator.
      if previous_states[next_gen_state.hash]
        return render json: {state: next_gen_state, status: "oscillating"}, status: :ok
      end

      current_state = next_gen_state
      previous_states[current_state.hash] = true
    end

    # If the loop finishes, we haven't found a final state in time.
    render json: {error: "Board did not reach a final state after #{max_attempts} attempts."},
      status: :unprocessable_content
  end

  # DELETE /api/v1/boards/:id
  def destroy
    @board.destroy
    head :no_content
  end

  private

  def board_params
    params.require(:board).permit!.slice(:state)
  end

  def set_board
    @board = Board.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {error: "Board not found"}, status: :not_found
  end
end
