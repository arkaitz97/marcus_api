require "test_helper"

module Api
  module V1
    class ProductsControllerTest < ActionDispatch::IntegrationTest
      test "index returns every product with its description" do
        get api_v1_products_url, as: :json

        assert_response :success
        body = response.parsed_body
        assert_equal 2, body.length
        assert_equal %w[Cargo\ Bike Custom\ Bicycle], body.map { |product| product["name"] }.sort
        assert body.first.key?("description")
      end

      test "show returns the requested product" do
        get api_v1_product_url(products(:bicycle)), as: :json

        assert_response :success
        assert_equal "Custom Bicycle", response.parsed_body["name"]
      end

      test "show returns 404 for an unknown product" do
        get api_v1_product_url(id: 0), as: :json

        assert_response :not_found
        assert_match(/Product not found/, response.parsed_body["error"])
      end

      test "create persists a product and returns it" do
        assert_difference("Product.count", 1) do
          post api_v1_products_url,
               params: { product: { name: "Tandem", description: "Two riders." } },
               as: :json
        end

        assert_response :created
        body = response.parsed_body
        assert_equal "Tandem", body["name"]
        assert_equal "Two riders.", body["description"]
        assert body["id"].present?
      end

      test "create rejects a product without a name" do
        assert_no_difference("Product.count") do
          post api_v1_products_url, params: { product: { description: "No name." } }, as: :json
        end

        assert_response :unprocessable_entity
        assert_includes response.parsed_body["name"].join(" "), "can't be blank"
      end

      test "destroy removes the product and its parts" do
        product = products(:bicycle)

        assert_difference({ "Product.count" => -1, "Part.count" => -4 }) do
          delete api_v1_product_url(product), as: :json
        end

        assert_response :no_content
      end
    end
  end
end
