# frozen_string_literal: true

class BoardEvolutionJob < ApplicationJob
  queue_as :default

  def perform(board_id)
    board = Board.find(board_id)
    return unless board.status_processing?

    # Save the initial state as step 0
    board.steps.create!(number: 0, state: board.state)

    current_state = board.state
    previous_states = {current_state.hash => 0}
    max_attempts = (ENV["MAX_FINAL_STATE_ATTEMPTS"] || 1000).to_i
    final_status = :max_attempts_reached

    (1..max_attempts).each do |step|
      service = GameOfLifeService.new(current_state)
      next_gen_state = service.next_state

      # Check for stable state
      if next_gen_state == current_state
        final_status = :stable
        break
      end

      # Check for oscillating state
      if previous_states.key?(next_gen_state.hash)
        final_status = :oscillating
        break
      end

      # Save the new state
      board.steps.create!(number: step, state: next_gen_state)
      current_state = next_gen_state
      previous_states[current_state.hash] = step
    end

    board.update!(status: final_status)
  end
end
