require "test_helper"

module Api
  module V1
    class ProductConfigurationControllerTest < ActionDispatch::IntegrationTest
      test "validate_selection accepts a compatible, in-stock selection" do
        post api_v1_product_configuration_validate_selection_url,
             params: { selected_part_option_ids: [ part_options(:full_suspension).id, part_options(:matte).id ] },
             as: :json

        assert_response :success
        assert_equal true, response.parsed_body["valid"]
        assert_empty response.parsed_body["errors"]
      end

      test "validate_selection reports a restriction conflict" do
        post api_v1_product_configuration_validate_selection_url,
             params: { selected_part_option_ids: [ part_options(:mountain_wheels).id, part_options(:diamond).id ] },
             as: :json

        assert_response :success
        body = response.parsed_body
        assert_equal false, body["valid"]
        assert body["errors"].any? { |error| error.include?("violates restriction") }
      end

      test "validate_selection reports an out-of-stock option" do
        post api_v1_product_configuration_validate_selection_url,
             params: { selected_part_option_ids: [ part_options(:eight_speed_chain).id ] },
             as: :json

        assert_response :success
        assert_equal false, response.parsed_body["valid"]
        assert response.parsed_body["errors"].any? { |error| error.include?("out of stock") }
      end

      test "validate_selection rejects options from different products" do
        post api_v1_product_configuration_validate_selection_url,
             params: {
               selected_part_option_ids: [ part_options(:diamond).id, part_options(:cargo_frame_option).id ]
             },
             as: :json

        assert_response :success
        assert_includes response.parsed_body["errors"], "Selected options must belong to the same product."
      end

      test "calculate_price sums option prices and matching premiums" do
        post api_v1_product_configuration_calculate_price_url,
             params: { selected_part_option_ids: [ part_options(:full_suspension).id, part_options(:matte).id ] },
             as: :json

        assert_response :success
        assert_equal 180.00, response.parsed_body["total_price"].to_f
      end

      test "calculate_price without a premium returns the sum of prices" do
        post api_v1_product_configuration_calculate_price_url,
             params: { selected_part_option_ids: [ part_options(:diamond).id ] },
             as: :json

        assert_response :success
        assert_equal 90.00, response.parsed_body["total_price"].to_f
      end

      test "calculate_price returns 404 for an unknown option" do
        post api_v1_product_configuration_calculate_price_url,
             params: { selected_part_option_ids: [ 999_999 ] },
             as: :json

        assert_response :not_found
      end
    end
  end
end
