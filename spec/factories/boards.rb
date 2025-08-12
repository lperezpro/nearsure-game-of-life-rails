# frozen_string_literal: true

# == Schema Information
#
# Table name: boards
#
#  id         :bigint           not null, primary key
#  state      :jsonb            not null
#  status     :enum             default("processing"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_boards_on_state  (state) UNIQUE
#
FactoryBot.define do
  factory :board do
    # Default state is a common oscillator pattern known as a "blinker".
    # This provides a predictable state for testing transitions.
    state do
      [
        [0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 0, 0, 0]
      ]
    end

    trait :block do
      state do
        [
          [0, 0, 0, 0],
          [0, 1, 1, 0],
          [0, 1, 1, 0],
          [0, 0, 0, 0]
        ]
      end
    end

    trait :beacon do
      state do
        [
          [0, 0, 0, 0, 0, 0],
          [0, 1, 1, 0, 0, 0],
          [0, 1, 0, 0, 0, 0],
          [0, 0, 0, 0, 1, 0],
          [0, 0, 0, 1, 1, 0],
          [0, 0, 0, 0, 0, 0]
        ]
      end
    end

    trait :toad do
      state do
        [
          [0, 0, 0, 0, 0, 0],
          [0, 0, 1, 1, 1, 0],
          [0, 1, 1, 1, 0, 0],
          [0, 0, 0, 0, 0, 0]
        ]
      end
    end

    trait :glider do
      state do
        [
          [0, 0, 0, 0, 0],
          [0, 0, 1, 0, 0],
          [0, 0, 0, 1, 0],
          [0, 1, 1, 1, 0],
          [0, 0, 0, 0, 0]
        ]
      end
    end
  end
end
