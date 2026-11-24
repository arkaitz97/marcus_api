require "test_helper"

module Api
  module V1
    class PriceRulesControllerTest < ActionDispatch::IntegrationTest
      test "index returns the stored price rules" do
        get api_v1_price_rules_url, as: :json

        assert_response :success
        assert_equal 1, response.parsed_body.length
        assert_equal 15.00, response.parsed_body.first["price_premium"].to_f
      end

      test "create stores a premium for a pair of options" do
        assert_difference("PriceRule.count", 1) do
          post api_v1_price_rules_url,
               params: {
                 price_rule: {
                   part_option_a_id: part_options(:diamond).id,
                   part_option_b_id: part_options(:shiny).id,
                   price_premium: 12.50
                 }
               },
               as: :json
        end

        assert_response :created
        assert_equal 12.50, response.parsed_body["price_premium"].to_f
      end

      test "create rejects the same option twice" do
        option = part_options(:diamond)

        post api_v1_price_rules_url,
             params: { price_rule: { part_option_a_id: option.id, part_option_b_id: option.id, price_premium: 5 } },
             as: :json

        assert_response :unprocessable_entity
        assert_includes response.parsed_body["base"].join(" "), "same part option twice"
      end

      test "create rejects the inverse of an existing rule" do
        post api_v1_price_rules_url,
             params: {
               price_rule: {
                 part_option_a_id: part_options(:matte).id,
                 part_option_b_id: part_options(:full_suspension).id,
                 price_premium: 15
               }
             },
             as: :json

        assert_response :unprocessable_entity
        assert_includes response.parsed_body["base"].join(" "), "inverse price rule"
      end
    end
  end
end
