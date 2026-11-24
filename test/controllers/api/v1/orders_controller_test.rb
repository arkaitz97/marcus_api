require "test_helper"

module Api
  module V1
    class OrdersControllerTest < ActionDispatch::IntegrationTest
      test "index returns orders with their line items" do
        get api_v1_orders_url, as: :json

        assert_response :success
        orders = response.parsed_body
        assert_equal 2, orders.length
        pending = orders.find { |order| order["customer_email"] == "ane@example.com" }
        assert_equal 2, pending["order_line_items"].length
        assert pending["order_line_items"].first.key?("part_option")
      end

      test "show returns one order with its selected options" do
        get api_v1_order_url(orders(:pending_order)), as: :json

        assert_response :success
        body = response.parsed_body
        assert_equal "pending", body["status"]
        option_names = body["order_line_items"].map { |item| item["part_option"]["name"] }
        assert_equal %w[Full-suspension Matte], option_names.sort
      end

      test "create prices the selection, builds line items and starts pending" do
        assert_difference({ "Order.count" => 1, "OrderLineItem.count" => 2 }) do
          post api_v1_orders_url,
               params: {
                 order: {
                   customer_name: "Miren Agirre",
                   customer_email: "miren@example.com",
                   selected_part_option_ids: [ part_options(:diamond).id, part_options(:shiny).id ]
                 }
               },
               as: :json
        end

        assert_response :created
        body = response.parsed_body
        assert_equal "pending", body["status"]
        assert_equal 120.00, body["total_price"].to_f
        assert_equal 2, body["order_line_items"].length
      end

      test "create applies the price premium of a matching rule" do
        post api_v1_orders_url,
             params: {
               order: {
                 customer_name: "Miren Agirre",
                 customer_email: "miren@example.com",
                 selected_part_option_ids: [ part_options(:full_suspension).id, part_options(:matte).id ]
               }
             },
             as: :json

        assert_response :created
        assert_equal 180.00, response.parsed_body["total_price"].to_f
      end

      test "create rejects a selection that violates a restriction" do
        assert_no_difference("Order.count") do
          post api_v1_orders_url,
               params: {
                 order: {
                   customer_name: "Miren Agirre",
                   customer_email: "miren@example.com",
                   selected_part_option_ids: [ part_options(:mountain_wheels).id, part_options(:diamond).id ]
                 }
               },
               as: :json
        end

        assert_response :unprocessable_entity
        assert response.parsed_body["errors"].any? { |error| error.include?("violates restriction") }, response.body
      end

      test "create rejects an unknown option id" do
        post api_v1_orders_url,
             params: {
               order: {
                 customer_name: "Miren Agirre",
                 customer_email: "miren@example.com",
                 selected_part_option_ids: [ 999_999 ]
               }
             },
             as: :json

        assert_response :not_found
      end

      test "update moves an order to another valid status" do
        order = orders(:pending_order)

        patch api_v1_order_url(order), params: { order: { status: "completed" } }, as: :json

        assert_response :success
        assert_equal "completed", order.reload.status
      end

      test "update rejects a status outside the allowed set" do
        order = orders(:pending_order)

        patch api_v1_order_url(order), params: { order: { status: "refunded" } }, as: :json

        assert_response :unprocessable_entity
        assert order.reload.status == "pending"
      end

      test "destroy removes the order and its line items" do
        order = orders(:pending_order)

        assert_difference({ "Order.count" => -1, "OrderLineItem.count" => -2 }) do
          delete api_v1_order_url(order), as: :json
        end

        assert_response :no_content
      end
    end
  end
end
