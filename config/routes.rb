# config/routes.rb
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # API routes namespace
  namespace :api do
    namespace :v1 do
      # Creates standard RESTful routes for products:
      # GET /api/v1/products -> index action
      # GET /api/v1/products/:id -> show action
      # POST /api/v1/products -> create action
      # PUT /api/v1/products/:id -> update action (also PATCH)
      # DELETE /api/v1/products/:id -> destroy action
      resources :products
    end
  end
end