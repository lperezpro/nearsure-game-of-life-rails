# frozen_string_literal: true

require "rails_helper"

RSpec.describe BoardEvolutionJob, type: :job do
  include ActiveJob::TestHelper

  let(:board) { create(:board) } # Uses the "blinker" pattern from the factory

  it "enqueues the job" do
    expect do
      BoardEvolutionJob.perform_later(board.id)
    end.to have_enqueued_job(BoardEvolutionJob).with(board.id)
  end

  context "when executing the job" do
    it "creates the initial step (step 0)" do
      expect do
        perform_enqueued_jobs { BoardEvolutionJob.perform_later(board.id) }
      end.to change(board.steps, :count).by_at_least(1)

      board.reload
      expect(board.steps.find_by(number: 0)).not_to be_nil
      expect(board.steps.find_by(number: 0).state).to eq(board.state)
    end

    it "sets the board status to 'oscillating' for a blinker pattern" do
      perform_enqueued_jobs { BoardEvolutionJob.perform_later(board.id) }
      board.reload
      expect(board.status_oscillating?).to be true
      expect(board.steps.count).to eq(2) # Step 0 (initial), Step 1 (rotated)
    end

    it "sets the board status to 'stable' for a stable pattern" do
      stable_state = [[0, 1, 1, 0], [0, 1, 1, 0], [0, 0, 0, 0]]
      stable_board = create(:board, state: stable_state)

      perform_enqueued_jobs { BoardEvolutionJob.perform_later(stable_board.id) }
      stable_board.reload

      expect(stable_board.status_stable?).to be true
      expect(stable_board.steps.count).to eq(1) # Step 0 (initial)
    end

    it "stops if board status is not 'processing'" do
      board.update!(status: :stable)
      BoardEvolutionJob.perform_now(board.id)
      expect(board.steps.count).to eq(0)
    end
  end
end
