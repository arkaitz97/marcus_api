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
    end
  end
end
