require "test_helper"

module Api
  module V1
    class PartOptionsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @product = products(:bicycle)
        @part = parts(:frame)
      end

      test "index lists the options of one part" do
        get api_v1_product_part_part_options_url(@product, @part), as: :json

        assert_response :success
        assert_equal %w[Diamond Full-suspension Step-through],
                     response.parsed_body.map { |option| option["name"] }.sort
      end

      test "create stores the price and stock flag" do
        post api_v1_product_part_part_options_url(@product, @part),
             params: { part_option: { name: "Titanium", price: 210.50, in_stock: false } },
             as: :json

        assert_response :created
        body = response.parsed_body
        assert_equal "Titanium", body["name"]
        assert_equal 210.50, body["price"].to_f
        assert_equal false, body["in_stock"]
      end

      test "update flips the stock flag" do
        option = part_options(:eight_speed_chain)

        patch api_v1_product_part_part_option_url(@product, parts(:chain), option),
              params: { part_option: { in_stock: true } },
              as: :json

        assert_response :success
        assert_equal true, response.parsed_body["in_stock"]
        assert option.reload.in_stock
      end

      test "create rejects a negative price" do
        post api_v1_product_part_part_options_url(@product, @part),
             params: { part_option: { name: "Broken", price: -1 } },
             as: :json

        assert_response :unprocessable_entity
        assert_includes response.parsed_body["price"].join(" "), "greater than or equal to 0"
      end
    end
  end
end
