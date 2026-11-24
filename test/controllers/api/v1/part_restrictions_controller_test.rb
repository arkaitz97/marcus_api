require "test_helper"

module Api
  module V1
    class PartRestrictionsControllerTest < ActionDispatch::IntegrationTest
      test "index returns the stored restriction pairs" do
        get api_v1_part_restrictions_url, as: :json

        assert_response :success
        assert_equal 2, response.parsed_body.length
      end

      test "create links two options" do
        assert_difference("PartRestriction.count", 1) do
          post api_v1_part_restrictions_url,
               params: {
                 part_restriction: {
                   part_option_id: part_options(:step_through).id,
                   restricted_part_option_id: part_options(:road_wheels).id
                 }
               },
               as: :json
        end

        assert_response :created
        assert_equal part_options(:step_through).id, response.parsed_body["part_option_id"]
      end

      test "create rejects a restriction of an option on itself" do
        option = part_options(:diamond)

        post api_v1_part_restrictions_url,
             params: { part_restriction: { part_option_id: option.id, restricted_part_option_id: option.id } },
             as: :json

        assert_response :unprocessable_entity
        assert_includes response.parsed_body["base"].join(" "), "cannot restrict itself"
      end

      test "create rejects the inverse of an existing restriction" do
        post api_v1_part_restrictions_url,
             params: {
               part_restriction: {
                 part_option_id: part_options(:diamond).id,
                 restricted_part_option_id: part_options(:mountain_wheels).id
               }
             },
             as: :json

        assert_response :unprocessable_entity
        assert_includes response.parsed_body["base"].join(" "), "inverse restriction"
      end
    end
  end
end
