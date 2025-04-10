# app/controllers/api/v1/products_controller.rb
module Api
    module V1
      class ProductsController < ApplicationController
        # Use a before_action to find the product for show, update, destroy
        before_action :set_product, only: [:show, :update, :destroy]
  
        # GET /api/v1/products
        def index
          @products = Product.all
          render json: @products
        end
  
        # GET /api/v1/products/:id
        def show
          render json: @product
        end
  
        # POST /api/v1/products
        def create
          @product = Product.new(product_params)
  
          if @product.save
            # Render the created product with status 201 Created
            render json: @product, status: :created
          else
            # Render errors if save fails, with status 422 Unprocessable Entity
            render json: @product.errors, status: :unprocessable_entity
          end
        end
  
        # PATCH/PUT /api/v1/products/:id
        def update
          if @product.update(product_params)
            # Render the updated product
            render json: @product
          else
            # Render errors if update fails
            render json: @product.errors, status: :unprocessable_entity
          end
        end
  
        # DELETE /api/v1/products/:id
        def destroy
          @product.destroy
          # Return 204 No Content, indicating successful deletion with no body
          head :no_content
        end
  
        private
  
        # Use callbacks to share common setup or constraints between actions.
        def set_product
          begin
            @product = Product.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Product not found" }, status: :not_found
          end
        end
  
        # Only allow a list of trusted parameters through.
        # This is known as "Strong Parameters"
        def product_params
          params.require(:product).permit(:name, :description)
        end
      end
    end
  end