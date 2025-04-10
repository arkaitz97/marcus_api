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
  
        def update
          if @order.update(order_update_params)
            render json: @order
          else
            render json: @order.errors, status: :unprocessable_entity
          end
        end
  
        def destroy
  
          if @order.destroy
            head :no_content
          else
            render json: { error: "Failed to delete order." }, status: :unprocessable_entity
          end
        end
  
        private
  
        def set_order
          begin
            @order = Order.includes(order_line_items: :part_option).find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Order not found with ID #{params[:id]}" }, status: :not_found
          end
        end
  
        def order_update_params
          params.require(:order).permit(:status) # Add other updatable fields if needed
        end
  
  
        def validate_option_selection(options)
          errors = []
          return ["No options selected."] if options.empty?
        
          # 1. Check stock status FIRST
          out_of_stock_options = options.reject(&:in_stock)
          out_of_stock_options.each do |option|
            errors << "Option '#{option.name}' (ID: #{option.id}) is out of stock."
          end
        
          # 2. Check if all options belong to the same product
          # Ensure part association is loaded if not already via includes on `options`
          product_ids = options.map { |opt| opt.part&.product_id }.compact.uniq
          errors << "Selected options must belong to the same product." if product_ids.length > 1
        
          option_ids = options.map(&:id)
          if option_ids.any?
            violated_restrictions = PartRestriction
                                      .includes(:part_option, :restricted_part_option)
                                      .where(part_option_id: option_ids, restricted_part_option_id: option_ids)
            violated_restrictions.each do |restriction|
              option_name = restriction.part_option&.name || "ID #{restriction.part_option_id}" # Fallback
              restricted_name = restriction.restricted_part_option&.name || "ID #{restriction.restricted_part_option_id}" # Fallback
              errors << "Selection violates restriction: '#{option_name}' conflicts with '#{restricted_name}'."
            end
          end
        end
  
        def calculate_total_price(options)
          base_price = options.sum(&:price)
  
          option_ids = options.map(&:id)
          premium = 0.0
  
          applicable_rules = PriceRule.where(part_option_a_id: option_ids, part_option_b_id: option_ids)
  
          applicable_rules.each do |rule|
            premium += rule.price_premium
          end
  
          BigDecimal(base_price.to_s) + BigDecimal(premium.to_s)
        end
  
      end
    end
  end
  
  