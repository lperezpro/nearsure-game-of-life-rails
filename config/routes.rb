# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api do
    namespace :v1 do
      resources :boards, only: [:index, :create, :show, :destroy] do
        member do
          get "next", to: "boards#next_state"
          get "steps/:n", to: "boards#steps_away", as: :steps
          get "final", to: "boards#final_state"
          get "step/:number", to: "boards#show_step", as: :step
        end
      end
    end
  end

  if Rails.env.local? || Rails.env.staging?
    mount Rswag::Ui::Engine => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  end
end
