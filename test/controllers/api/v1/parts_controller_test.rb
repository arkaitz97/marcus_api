require "test_helper"

module Api
  module V1
    class PartsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @product = products(:bicycle)
      end

      test "index lists only the parts of the given product" do
        get api_v1_product_parts_url(@product), as: :json

        assert_response :success
        names = response.parsed_body.map { |part| part["name"] }
        assert_equal %w[Chain Frame Frame\ Finish Wheels], names.sort
        refute_includes names, "Cargo frame"
      end

      test "create adds a part to the product" do
        assert_difference("@product.parts.count", 1) do
          post api_v1_product_parts_url(@product), params: { part: { name: "Saddle" } }, as: :json
        end

        assert_response :created
        assert_equal "Saddle", response.parsed_body["name"]
        assert_equal @product.id, response.parsed_body["product_id"]
      end

      test "create returns 404 when the product does not exist" do
        post api_v1_product_parts_url(product_id: 0), params: { part: { name: "Saddle" } }, as: :json

        assert_response :not_found
      end

      test "show keeps the part scoped to its product" do
        other_part = parts(:cargo_frame)

        get api_v1_product_part_url(@product, other_part), as: :json

        assert_response :not_found
      end
    end
  end
end
