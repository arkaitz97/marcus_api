# app/controllers/api/v1/parts_controller.rb
module Api
    module V1
      # Controller to handle CRUD operations for Parts, nested under Products.
      class PartsController < ApplicationController
        # --- Callbacks ---
        # Find the parent Product before any part action
        before_action :set_product
        # Find the specific Part for show, update, destroy actions
        before_action :set_part, only: [:show, :update, :destroy]
  
        # --- Actions ---
  
        # GET /api/v1/products/:product_id/parts
        # Responds with a list of parts belonging to the specified product.
        def index
          @parts = @product.parts # Fetch parts associated with the @product
          render json: @parts
        end
  
        # GET /api/v1/products/:product_id/parts/:id
        # Responds with the details of a single part belonging to the product.
        # @part is set by the :set_part before_action.
        def show
          render json: @part
        end
  
        # POST /api/v1/products/:product_id/parts
        # Creates a new part associated with the specified product.
        def create
          # Build a new Part associated with the @product using permitted params.
          # Using 'build' automatically sets the product_id.
          @part = @product.parts.build(part_params)
  
          if @part.save # Attempt to save the part
            # Success: Render the created part with 201 Created status
            render json: @part, status: :created
          else
            # Failure: Render validation errors with 422 Unprocessable Entity status
            render json: @part.errors, status: :unprocessable_entity
          end
        end
  
        # PATCH/PUT /api/v1/products/:product_id/parts/:id
        # Updates an existing part belonging to the product.
        # @part is set by the :set_part before_action.
        def update
          if @part.update(part_params) # Attempt to update the part
            # Success: Render the updated part
            render json: @part
          else
            # Failure: Render validation errors with 422 Unprocessable Entity status
            render json: @part.errors, status: :unprocessable_entity
          end
        end
  
        # DELETE /api/v1/products/:product_id/parts/:id
        # Deletes an existing part belonging to the product.
        # @part is set by the :set_part before_action.
        def destroy
          @part.destroy # Delete the part
          # Success: Respond with 204 No Content status
          head :no_content
        end
  
        # --- Private Methods ---
        private
  
        # Finds the parent Product based on :product_id from the URL parameters.
        # Handles RecordNotFound error if the product doesn't exist.
        def set_product
          begin
            @product = Product.find(params[:product_id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Product not found with ID #{params[:product_id]}" }, status: :not_found
          end
        end
  
        # Finds the Part based on :id within the scope of the @product.
        # Handles RecordNotFound error if the part doesn't exist or doesn't belong to the product.
        def set_part
          begin
            # Ensure we only find parts belonging to the @product found in set_product
            @part = @product.parts.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Part not found with ID #{params[:id]} for Product ##{@product.id}" }, status: :not_found
          end
        end
  
        # Strong Parameters: Only allows the 'name' attribute for a part.
        def part_params
          params.require(:part).permit(:name)
        end
      end
    end
  end
  