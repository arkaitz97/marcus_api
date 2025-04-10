Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :products do
        resources :parts do
          resources :part_options
        end
      end
      resources :part_restrictions, only: [:index, :show, :create, :destroy]
      resources :price_rules, only: [:index, :show, :create, :destroy]
      resources :orders, only: [:index, :show, :create, :update, :destroy] do
      end
      post 'product_configuration/validate_selection', to: 'product_configuration#validate_selection'
      post 'product_configuration/calculate_price', to: 'product_configuration#calculate_price'
    end
  end
end
