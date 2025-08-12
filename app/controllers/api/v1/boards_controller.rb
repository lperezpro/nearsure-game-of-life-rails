# frozen_string_literal: true

module Api
  module V1
    class BoardsController < ApplicationController
      before_action :set_board, except: [:index, :create]

      # GET /api/v1/boards
      # Returns a list of all boards in the database.
      def index
        @boards = Board.all
        render json: @boards, status: :ok
      end

      # GET /api/v1/boards/:id
      # Shows the status of the board's evolution
      # - whether it's still calculating or finished - and the total number of steps calculated so far.
      # Returns 404 Not Found if the board does not exist.
      def show
        render json: {
                 id: @board.id,
                 state: @board.state,
                 status: @board.status,
                 total_steps_calculated: @board.steps.count
               },
          status: :ok
      end

      # POST /api/v1/boards
      # Creates a new board. Expects a 'state' parameter, which is a 2D array of 0s and 1s.
      # On success, returns 201 Created with the new board's ID.
      # On failure, returns 422 Unprocessable Content with validation errors.
      def create
        @board = Board.new(board_params)
        if @board.save
          # Enqueue the background job to calculate the evolution
          BoardEvolutionJob.perform_later(@board.id)
          render json: {id: @board.id, status_url: api_v1_board_url(@board)}, status: :created
        else
          render json: {errors: @board.errors.full_messages}, status: :unprocessable_entity
        end
      end

      # GET /api/v1/boards/:id/step/:step
      # Retrieves a previously calculated board state for a specific step.
      # Returns 404 Not Found if the step does not exist.
      def show_step
        step = @board.steps.find_by(number: params[:number])
        if step
          render json: {step: step.number, state: step.state}, status: :ok
        else
          render json: {
                   error: "Step not found or not yet calculated.",
                   status: @board.status,
                   total_steps_calculated: @board.steps.count
                 },
            status: :not_found
        end
      end

      # DELETE /api/v1/boards/:id
      def destroy
        @board.destroy
        head :no_content
      end

      # --- Deprecated Actions ---
      # These now read from the pre-calculated data.

      # GET /api/v1/boards/:id/next
      # Returns the next single generation for the specified board.
      # This action is deprecated and now uses the pre-calculated steps.
      def next_state
        show_step_by_number(1)
      end

      # GET /api/v1/boards/:id/steps/:n
      # Find the state of the board after 'n' generations.
      # This action is deprecated and now uses the pre-calculated steps.
      def steps_away
        show_step_by_number(params[:n].to_i)
      end

      # GET /api/v1/boards/:id/final
      # Returns the final state of the board after all generations have been calculated.
      # This action is deprecated and now uses the pre-calculated steps.
      def final_state
        if @board.status_processing?
          return render json: {status: "processing", message: "Final state is still being calculated."},
            status: :accepted
        end

        final_state = @board.steps.last
        render json: {
                 status: @board.status,
                 final_step: final_state.number,
                 state: final_state.state
               },
          status: :ok
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

      def show_step_by_number(number)
        params[:number] = number
        show_step
      end
    end
  end
end
