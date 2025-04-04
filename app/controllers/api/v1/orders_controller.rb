module Api
    module V1
      class OrdersController < ApplicationController
        before_action :set_order, only: [:show, :update, :destroy]
  
        def index
          @orders = Order.includes(order_line_items: { part_option: :part })
                         .order(created_at: :desc) # Example ordering
          render json: @orders, include: { order_line_items: { include: :part_option } } # Example serialization
        end
  
        def show
          render json: @order, include: { order_line_items: { include: :part_option } }
        end
  
        def create
          customer_params = params.require(:order).permit(:customer_name, :customer_email)
          selected_option_ids = params.require(:order).permit(selected_part_option_ids: [])[:selected_part_option_ids]
  
          unless selected_option_ids.is_a?(Array) && selected_option_ids.any?
            render json: { error: "selected_part_option_ids must be a non-empty array" }, status: :unprocessable_entity
            return
          end
  
          selected_options = PartOption.includes(part: :product).where(id: selected_option_ids)
  
          if selected_options.length != selected_option_ids.uniq.length
            render json: { error: "One or more selected part option IDs are invalid." }, status: :not_found
            return
          end
  
          validation_errors = validate_option_selection(selected_options)
          unless validation_errors.empty?
            render json: { errors: validation_errors }, status: :unprocessable_entity
            return
          end
  
          total_price = calculate_total_price(selected_options)
  
          @order = Order.new(customer_params.merge(total_price: total_price, status: 'pending'))
  
          Order.transaction do
            @order.save! # Use save! to raise exception on failure within transaction
            selected_options.each do |option|
              @order.order_line_items.create!(part_option: option)
            end
          end # Transaction commits here if no exceptions were raised
  
          render json: @order, include: { order_line_items: { include: :part_option } }, status: :created
  
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        rescue ActiveRecord::RecordNotSaved => e
          render json: { error: "Failed to save order: #{e.message}" }, status: :internal_server_error
        rescue => e # Catch other potential errors during processing
          Rails.logger.error("Order creation failed: #{e.message}\n#{e.backtrace.join("\n")}")
          render json: { error: "An unexpected error occurred during order creation." }, status: :internal_server_error
        end
  
        # PATCH/PUT /api/v1/orders/:id
        # Updates an existing order (e.g., changing status).
        # Use PATCH for partial updates.
        def update
          # Only allow updating specific fields, like status
          if @order.update(order_update_params)
            render json: @order
          else
            render json: @order.errors, status: :unprocessable_entity
          end
        end
  
        # DELETE /api/v1/orders/:id
        # Deletes an order (or changes status to 'cancelled').
        # Consider business logic: maybe only allow deletion/cancellation for 'pending' orders.
        def destroy
          # Example: Change status to cancelled instead of deleting
          # if @order.update(status: 'cancelled')
          #   head :no_content
          # else
          #   render json: @order.errors, status: :unprocessable_entity
          # end
  
          # Or, actual deletion:
          if @order.destroy
            head :no_content
          else
            # This might happen if there are callbacks preventing destroy
            render json: { error: "Failed to delete order." }, status: :unprocessable_entity
          end
        end
  
        # --- Private Methods ---
        private
  
        # Finds the Order based on :id parameter.
        def set_order
          begin
            # Include associations needed for show/update/destroy if applicable
            @order = Order.includes(order_line_items: :part_option).find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Order not found with ID #{params[:id]}" }, status: :not_found
          end
        end
  
        # Strong Parameters for updating an order (e.g., only status).
        def order_update_params
          params.require(:order).permit(:status) # Add other updatable fields if needed
        end
  
        # --- Order Creation Helper Methods ---
  
        # Validates the set of selected PartOptions.
        # Returns an array of error messages, empty if valid.
        def validate_option_selection(options)
          errors = []
          return ["No options selected."] if options.empty?
  
          # 1. Check if all options belong to the same product
          product_ids = options.map { |opt| opt.part.product_id }.uniq
          errors << "Selected options must belong to the same product." if product_ids.length > 1
  
          # 2. Check for part restrictions
          option_ids = options.map(&:id)
          # Find restrictions where BOTH options in the restriction rule are present in the selection
          violated_restrictions = PartRestriction.where(part_option_id: option_ids, restricted_part_option_id: option_ids)
                                                 .or(PartRestriction.where(part_option_id: option_ids.reverse, restricted_part_option_id: option_ids.reverse)) # Check inverse too for safety
  
          violated_restrictions.each do |restriction|
             errors << "Selection violates restriction: Option ##{restriction.part_option_id} conflicts with Option ##{restriction.restricted_part_option_id}."
          end
  
          # 3. Check if multiple options were selected for the same part (if needed)
          # part_ids = options.map { |opt| opt.part_id }
          # if part_ids.length != part_ids.uniq.length
          #   errors << "Multiple options selected for the same part. (Add specific part IDs if helpful)"
          # end
          # Note: This validation depends on business rules - sometimes multiple options per part are allowed.
  
          errors.uniq # Return unique error messages
        end
  
        # Calculates the total price based on selected options and price rules.
        def calculate_total_price(options)
          # 1. Sum base prices of all selected options
          base_price = options.sum(&:price)
  
          # 2. Find applicable price rules and sum premiums
          option_ids = options.map(&:id)
          premium = 0.0
  
          # Find rules where BOTH options in the rule are present in the selection
          applicable_rules = PriceRule.where(part_option_a_id: option_ids, part_option_b_id: option_ids)
  
          applicable_rules.each do |rule|
            premium += rule.price_premium
          end
  
          # Return total price as a BigDecimal
          BigDecimal(base_price.to_s) + BigDecimal(premium.to_s)
        end
  
      end
    end
  end
  
  