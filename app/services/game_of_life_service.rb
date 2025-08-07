# frozen_string_literal: true

class GameOfLifeService
  # rubocop:disable Layout/MultilineArrayLineBreaks, Layout/ExtraSpacing
  # Defines the 8 possible directions to check for neighbors (relative coordinates).
  DIRECTIONS = [
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1],           [0, 1],
    [1, -1], [1, 0], [1, 1]
  ].freeze
  # rubocop:enable Layout/MultilineArrayLineBreaks, Layout/ExtraSpacing

  # @param board_state [Array<Array<Integer>>] A 2D array representing the board.
  def initialize(board_state)
    @board_state = board_state
    @rows = board_state.size
    @cols = board_state.first.size
  end

  # Calculates the next state of the board based on the rules of Conway's Game of Life.
  # @return [Array<Array<Integer>>] The new board state.
  def next_state
    (0...@rows).map do |row|
      (0...@cols).map do |col|
        new_cell_state(row, col)
      end
    end
  end

  private

  # Determines the new state of a single cell based on its neighbors.
  # @param row [Integer] The row index of the cell.
  # @param col [Integer] The column index of the cell.
  # @return [Integer] The new state of the cell (1 for alive, 0 for dead).
  def new_cell_state(row, col)
    alive_neighbors = count_alive_neighbors(row, col)
    cell_is_alive = @board_state[row][col] == 1

    if cell_is_alive
      [2, 3].include?(alive_neighbors) ? 1 : 0
    else
      alive_neighbors == 3 ? 1 : 0
    end
  end

  # Counts the number of live neighbors for a given cell.
  # @param row [Integer] The row index of the cell.
  # @param col [Integer] The column index of the cell.
  # @return [Integer] The count of live neighbors.
  def count_alive_neighbors(row, col)
    DIRECTIONS.sum do |dr, dc|
      neighbor_row = row + dr
      neighbor_col = col + dc

      next 0 unless neighbor_row.between?(0, @rows - 1) && neighbor_col.between?(0, @cols - 1)

      @board_state[neighbor_row][neighbor_col]
    end
  end
end
