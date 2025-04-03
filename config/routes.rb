Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    namespace :v1 do
      # Routes for Products
      resources :products do
        # --- Nested Part Routes ---
        # Creates standard RESTful routes for Parts, nested under Products.
        # URLs will look like: /api/v1/products/:product_id/parts/...
        #
        # Verb   | Path                               | Controller#Action | Named Helper Prefix
        # -------|------------------------------------|-------------------|-------------------------
        # GET    | /products/:product_id/parts        | parts#index       | api_v1_product_parts
        # POST   | /products/:product_id/parts        | parts#create      | api_v1_product_parts
        # GET    | /products/:product_id/parts/:id    | parts#show        | api_v1_product_part
        # PATCH  | /products/:product_id/parts/:id    | parts#update      | api_v1_product_part
        # PUT    | /products/:product_id/parts/:id    | parts#update      | api_v1_product_part
        # DELETE | /products/:product_id/parts/:id    | parts#destroy     | api_v1_product_part
        resources :parts
      end
    end
  end
end
