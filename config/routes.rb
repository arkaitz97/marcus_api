Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :products do
        resources :parts do
          resources :part_options
        end
      end
    end
  end
end
