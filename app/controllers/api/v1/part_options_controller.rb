module Api
    module V1
      class PartOptionsController < ApplicationController
        before_action :set_product
        before_action :set_part
        before_action :set_part_option, only: [:show, :update, :destroy]
        def index
          @part_options = @part.part_options 
          render json: @part_options
        end
        def show
          render json: @part_option
        end
        def create
          @part_option = @part.part_options.build(part_option_params)
  
          if @part_option.save 
            render json: @part_option, status: :created
          else
            render json: @part_option.errors, status: :unprocessable_entity
          end
        end
        def update
          if @part_option.update(part_option_params) 
            render json: @part_option
          else
            render json: @part_option.errors, status: :unprocessable_entity
          end
        end
        def destroy
          @part_option.destroy 
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
          return unless @product
          begin
            @part = @product.parts.find(params[:part_id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Part not found with ID #{params[:part_id]} for Product ##{@product.id}" }, status: :not_found
          end
        end
  
        def set_part_option
          return unless @part
          begin
            @part_option = @part.part_options.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "PartOption not found with ID #{params[:id]} for Part ##{@part.id}" }, status: :not_found
          end
        end
  
        def part_option_params
          params.require(:part_option).permit(:name, :price, :in_stock)
        end
      end
    end
  end
  