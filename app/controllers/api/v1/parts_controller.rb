module Api
    module V1
      class PartsController < ApplicationController
        before_action :set_product
        before_action :set_part, only: [:show, :update, :destroy]
  
  
        def index
          @parts = @product.parts
          render json: @parts
        end
  
        def show
          render json: @part
        end
  
        def create
          @part = @product.parts.build(part_params)
  
          if @part.save
            render json: @part, status: :created
          else
            render json: @part.errors, status: :unprocessable_entity
          end
        end
  
        def update
          if @part.update(part_params)
            render json: @part
          else
            render json: @part.errors, status: :unprocessable_entity
          end
        end
  
        def destroy
          @part.destroy 
          head :no_content
        end
  
        private
  
        def set_product
          begin
            @product = Product.find(params[:product_id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Product not found with ID #{params[:product_id]}" }, status: :not_found
          end
        end
  
        def set_part
          begin
            @part = @product.parts.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Part not found with ID #{params[:id]} for Product ##{@product.id}" }, status: :not_found
          end
        end
  
        def part_params
          params.require(:part).permit(:name)
        end
      end
    end
  end
  