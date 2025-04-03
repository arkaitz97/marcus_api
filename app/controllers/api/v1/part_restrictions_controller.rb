module Api
    module V1
      class PartRestrictionsController < ApplicationController
        before_action :set_part_restriction, only: [:show, :destroy]
        def index
          @part_restrictions = PartRestriction.all
          render json: @part_restrictions
        end
        def show
          render json: @part_restriction
        end
        def create
          @part_restriction = PartRestriction.new(part_restriction_params)
  
          if @part_restriction.save
            render json: @part_restriction, status: :created
          else
            render json: @part_restriction.errors, status: :unprocessable_entity
          end
        end
  
        def destroy
          @part_restriction.destroy
          head :no_content
        end
  
        private
  
        def set_part_restriction
          begin
            @part_restriction = PartRestriction.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "PartRestriction not found with ID #{params[:id]}" }, status: :not_found
          end
        end
  
        def part_restriction_params
          params.require(:part_restriction).permit(:part_option_id, :restricted_part_option_id)
        end
      end
    end
  end
  