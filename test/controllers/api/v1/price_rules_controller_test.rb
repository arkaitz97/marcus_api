module Api
  module V1
    class PriceRulesController < ApplicationController
      before_action :set_price_rule, only: [:show, :destroy]
      def index
        @price_rules = PriceRule.all
        render json: @price_rules
      end

      def show
        render json: @price_rule
      end

      def create
        @price_rule = PriceRule.new(price_rule_params)

        if @price_rule.save
          render json: @price_rule, status: :created
        else
          render json: @price_rule.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @price_rule.destroy
        head :no_content
      end

      private

      def set_price_rule
        begin
          @price_rule = PriceRule.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "PriceRule not found with ID #{params[:id]}" }, status: :not_found
        end
      end

      def price_rule_params
        params.require(:price_rule).permit(:part_option_a_id, :part_option_b_id, :price_premium)
      end
    end
  end
end
