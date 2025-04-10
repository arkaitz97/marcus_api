module Api
    module V1
      class ProductConfigurationController < ApplicationController
  
        def validate_selection
          selected_option_ids = params.require(:selected_part_option_ids) # Ensure this param is sent
  
          unless selected_option_ids.is_a?(Array)
            render json: { errors: ["selected_part_option_ids must be an array"] }, status: :unprocessable_entity
            return
          end
  
          options = PartOption.includes(:part).where(id: selected_option_ids)
  
          if options.length != selected_option_ids.uniq.length
             render json: { valid: false, errors: ["One or more selected part option IDs are invalid."] }, status: :ok # Or 404/422? OK might be better for validation endpoint
             return
          end
  
          validation_errors = run_validation_logic(options) # Placeholder for actual logic
  
          if validation_errors.empty?
            render json: { valid: true, errors: [] }, status: :ok
          else
            render json: { valid: false, errors: validation_errors }, status: :ok # Use 200 OK for validation results
          end
        end
  
        def calculate_price
          selected_option_ids = params.require(:selected_part_option_ids)
  
          unless selected_option_ids.is_a?(Array)
            render json: { errors: ["selected_part_option_ids must be an array"] }, status: :unprocessable_entity
            return
          end
  
          options = PartOption.where(id: selected_option_ids)
  
          if options.length != selected_option_ids.uniq.length
             render json: { error: "One or more selected part option IDs are invalid." }, status: :not_found # 404 might be suitable here
             return
          end
  
          total_price = run_calculation_logic(options) # Placeholder for actual logic
  
          render json: { total_price: total_price.to_s }, status: :ok # Return price as string
        end
  
        private
  
        def run_validation_logic(options)
          errors = []
          return ["No options selected."] if options.empty?
          out_of_stock_options = options.reject(&:in_stock)
          out_of_stock_options.each { |o| errors << "Option '#{o.name}' (ID: #{o.id}) is out of stock." }
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
          errors.uniq
        end
  
        def run_calculation_logic(options)
           base_price = options.sum { |opt| opt.price || 0 } # Handle nil price just in case
           premium = BigDecimal("0.0")
           option_ids = options.map(&:id)
  
           if option_ids.length >= 2 # Premiums only apply to pairs
              applicable_rules = PriceRule.where(part_option_a_id: option_ids, part_option_b_id: option_ids)
              applicable_rules.each do |rule|
                premium += (rule.price_premium || 0) # Handle nil premium
              end
           end
           BigDecimal(base_price.to_s) + premium
        end
  
      end
    end
  end