#!/bin/bash

# Simple API Test Script for Product Configurator (Includes Order & Dynamic Endpoint Tests)
# Corrected check_json_value helper to handle jq's // operator with false values.
# Adjusted expected price format in tests to match API output (e.g., 35.0 instead of 35.00).

# --- Configuration ---
BASE_URL="http://localhost:3000/api/v1"
JQ_CMD="jq" # Assumes jq is in PATH
CURL_CMD="curl -s" # Start with silent

# --- Helper Functions ---

# Function to check HTTP status code
# Arguments: message, expected_prefix, actual_status
check_status() {
  local message=$1
  local expected_status_prefix=${2:-2} # Default expected HTTP status prefix is '2' (2xx)
  local actual_status=$3

  if [[ -z "$actual_status" ]]; then
      echo "❌ FAILED: '$message'. No HTTP status code received."
      exit 1
  fi

  # Check if HTTP status starts with the expected prefix (e.g., 2 for 2xx, 4 for 4xx)
  if [[ "$actual_status" == ${expected_status_prefix}* ]]; then
      echo "✅ PASSED: '$message' (Status: $actual_status)."
  else
      echo "❌ FAILED: '$message'. Expected status ${expected_status_prefix}xx, but got $actual_status."
      # Display body from TMP_FILE if it exists and failure occurred
      if [ -f "$TMP_FILE" ]; then
          echo "--- Response Body ---"
          # Use direct file input for jq display as well
          $JQ_CMD '.' "$TMP_FILE" 2>/dev/null || cat "$TMP_FILE"
          echo "---------------------"
      fi
      exit 1
  fi
}


# Function to extract field (usually ID) from JSON response body file
# Assumes the file ONLY contains the JSON body
extract_id() {
  local json_file=$1
  local id_field=${2:-id} # Default field name is 'id'

  if [ ! -f "$json_file" ]; then
      echo "❌ ERROR: Cannot extract '$id_field', file '$json_file' not found."
      exit 1
  fi

  # Pass filename directly to jq instead of using cat | jq
  local extracted_id=$($JQ_CMD -r ".$id_field // empty" "$json_file" 2>/dev/null)

  if [[ -z "$extracted_id" || "$extracted_id" == "null" ]]; then
    echo "❌ ERROR: Could not extract '$id_field' from response file '$json_file'."
    echo "--- Response Body ---"
    $JQ_CMD '.' "$json_file" 2>/dev/null || cat "$json_file" # Print formatted JSON or raw output
    echo "---------------------"
    exit 1
  fi
  echo "$extracted_id" # Return the extracted ID
}

# Function to check JSON response body file for specific value
# Assumes the file ONLY contains the JSON body
check_json_value() {
    local json_file=$1
    local query=$2 # e.g., '.valid' or '.total_price'
    local expected_value=$3
    local message=$4

    if [ ! -f "$json_file" ]; then
      echo "❌ ERROR: Cannot check value for '$message', file '$json_file' not found."
      exit 1
    fi

    # Pass filename directly to jq. IMPORTANT: Remove the '// "..."' fallback
    # because it incorrectly triggers on a valid 'false' value.
    # If the query path doesn't exist, jq -r will output "null" or empty string,
    # which will correctly fail the comparison below.
    local actual_value=$($JQ_CMD -r "$query" "$json_file" 2>/dev/null)

    # Note: Comparing boolean values from jq -r requires care (it outputs 'true'/'false' strings)
    if [[ "$actual_value" == "$expected_value" ]]; then
        echo "✅ PASSED: '$message' - Found $query == $expected_value."
    else
        echo "❌ FAILED: '$message' - Expected $query == $expected_value, but got '$actual_value'."
        echo "--- Failing Response Body (from $json_file) ---"
        $JQ_CMD '.' "$json_file" 2>/dev/null || cat "$json_file"
        echo "---------------------"
        exit 1
    fi
}


# Temporary file for curl output BODY
TMP_FILE=$(mktemp)
# Cleanup temp file on exit
trap 'echo "🧹 Cleaning up temp file..."; rm -f $TMP_FILE' EXIT

# --- Test Execution ---

echo "🚀 Starting API Tests (including Orders & Dynamic Endpoints)..."
echo "Base URL: $BASE_URL"
echo "Requires 'curl' and 'jq'."
echo "Ensure Rails server is running!"
echo "Consider running 'bin/rails db:reset' first."
echo "----------------------------------------"

# == 1. Products ==
echo "🧪 Testing Products..."
# POST Create
echo "-- Creating Product..."
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products" \
  -H "Content-Type: application/json" \
  -d '{"product": {"name": "Test Product", "description": "Initial Description"}}' \
  -o $TMP_FILE -w '%{http_code}') # Write body to TMP_FILE, status to stdout
check_status "Create Product" 2 "$HTTP_STATUS" # Check status captured in variable
PRODUCT_ID=$(extract_id $TMP_FILE) # Extract ID from body file
echo "   -> Created Product ID: $PRODUCT_ID"
echo "--- Response Body ---"
$JQ_CMD '.' "$TMP_FILE" # Display body file using jq direct input
echo "----------------"
# GET Index
echo "-- Getting Product Index..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/products" -o $TMP_FILE -w '%{http_code}')
check_status "Get Product Index" 2 "$HTTP_STATUS"
# GET Show
echo "-- Getting Product $PRODUCT_ID..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/products/$PRODUCT_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Get Product Show" 2 "$HTTP_STATUS"
# PUT Update
echo "-- Updating Product $PRODUCT_ID..."
HTTP_STATUS=$($CURL_CMD -X PUT "$BASE_URL/products/$PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d '{"product": {"description": "Updated Description"}}' \
  -o $TMP_FILE -w '%{http_code}')
check_status "Update Product" 2 "$HTTP_STATUS"
# DELETE
echo "-- Deleting Product $PRODUCT_ID..."
# For DELETE 204, body is empty, -o is not strictly needed but harmless
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$PRODUCT_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Delete Product" 2 "$HTTP_STATUS" # Expect 204
# GET Show (Verify Delete)
echo "-- Verifying Product $PRODUCT_ID Deletion..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/products/$PRODUCT_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Verify Product Delete" 4 "$HTTP_STATUS" # Expect 404
echo "----------------------------------------"


# == 2. Parts (Nested under Products) ==
echo "🧪 Testing Parts..."
# Setup: Create a parent product
echo "-- Setup: Creating Parent Product for Parts..."
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products" \
  -H "Content-Type: application/json" \
  -d '{"product": {"name": "Part Parent Product", "description": "Holds parts"}}' \
  -o $TMP_FILE -w '%{http_code}')
check_status "Create Parent Product (Parts)" 2 "$HTTP_STATUS"
PARENT_PRODUCT_ID=$(extract_id $TMP_FILE)
echo "   -> Parent Product ID: $PARENT_PRODUCT_ID"
# POST Create Part
echo "-- Creating Part under Product $PARENT_PRODUCT_ID..."
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$PARENT_PRODUCT_ID/parts" \
  -H "Content-Type: application/json" \
  -d '{"part": {"name": "Test Part 1"}}' \
  -o $TMP_FILE -w '%{http_code}')
check_status "Create Part" 2 "$HTTP_STATUS"
PART_ID=$(extract_id $TMP_FILE)
echo "   -> Created Part ID: $PART_ID"
# GET Index Parts
echo "-- Getting Parts Index for Product $PARENT_PRODUCT_ID..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/products/$PARENT_PRODUCT_ID/parts" -o $TMP_FILE -w '%{http_code}')
check_status "Get Parts Index" 2 "$HTTP_STATUS"
# GET Show Part
echo "-- Getting Part $PART_ID for Product $PARENT_PRODUCT_ID..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/products/$PARENT_PRODUCT_ID/parts/$PART_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Get Part Show" 2 "$HTTP_STATUS"
# PUT Update Part
echo "-- Updating Part $PART_ID for Product $PARENT_PRODUCT_ID..."
HTTP_STATUS=$($CURL_CMD -X PUT "$BASE_URL/products/$PARENT_PRODUCT_ID/parts/$PART_ID" \
  -H "Content-Type: application/json" \
  -d '{"part": {"name": "Updated Test Part 1"}}' \
  -o $TMP_FILE -w '%{http_code}')
check_status "Update Part" 2 "$HTTP_STATUS"
# DELETE Part
echo "-- Deleting Part $PART_ID for Product $PARENT_PRODUCT_ID..."
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$PARENT_PRODUCT_ID/parts/$PART_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Delete Part" 2 "$HTTP_STATUS"
# GET Show Part (Verify Delete)
echo "-- Verifying Part $PART_ID Deletion..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/products/$PARENT_PRODUCT_ID/parts/$PART_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Verify Part Delete" 4 "$HTTP_STATUS"
# Cleanup: Delete parent product
echo "-- Cleanup: Deleting Parent Product $PARENT_PRODUCT_ID..."
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$PARENT_PRODUCT_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Delete Parent Product (Parts)" 2 "$HTTP_STATUS"
echo "----------------------------------------"


# == 3. PartOptions (Nested under Parts) ==
echo "🧪 Testing PartOptions..."
# Setup: Create Product and Part
echo "-- Setup: Creating Product & Part for Options..."
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products" -H "Content-Type: application/json" -d '{"product": {"name": "Option Parent Product"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Product (Options)" 2 "$HTTP_STATUS"
OPTION_PRODUCT_ID=$(extract_id $TMP_FILE)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$OPTION_PRODUCT_ID/parts" -H "Content-Type: application/json" -d '{"part": {"name": "Option Parent Part"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Part (Options)" 2 "$HTTP_STATUS"
OPTION_PART_ID=$(extract_id $TMP_FILE)
echo "   -> Product ID: $OPTION_PRODUCT_ID, Part ID: $OPTION_PART_ID"
# POST Create Option
echo "-- Creating Option under Part $OPTION_PART_ID..."
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options" \
  -H "Content-Type: application/json" \
  -d '{"part_option": {"name": "Option A", "price": "10.50"}}' \
  -o $TMP_FILE -w '%{http_code}')
check_status "Create Option" 2 "$HTTP_STATUS"
OPTION_ID=$(extract_id $TMP_FILE)
echo "   -> Created Option ID: $OPTION_ID"
# GET Index Options
echo "-- Getting Options Index for Part $OPTION_PART_ID..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options" -o $TMP_FILE -w '%{http_code}')
check_status "Get Options Index" 2 "$HTTP_STATUS"
# GET Show Option
echo "-- Getting Option $OPTION_ID for Part $OPTION_PART_ID..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options/$OPTION_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Get Option Show" 2 "$HTTP_STATUS"
# PUT Update Option (includes testing in_stock update)
echo "-- Updating Option $OPTION_ID (price and stock)..."
HTTP_STATUS=$($CURL_CMD -X PUT "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options/$OPTION_ID" \
  -H "Content-Type: application/json" \
  -d '{"part_option": {"name": "Option A Updated", "price": "12.99", "in_stock": false}}' \
  -o $TMP_FILE -w '%{http_code}')
check_status "Update Option (Stock)" 2 "$HTTP_STATUS"
# Verify stock update
echo "-- Verifying Option $OPTION_ID stock update..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options/$OPTION_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Verify Option Stock Get" 2 "$HTTP_STATUS"
check_json_value $TMP_FILE '.in_stock' 'false' "Verify Option in_stock is false" # This call now uses the corrected check_json_value
# DELETE Option
echo "-- Deleting Option $OPTION_ID for Part $OPTION_PART_ID..."
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options/$OPTION_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Delete Option" 2 "$HTTP_STATUS"
# GET Show Option (Verify Delete)
echo "-- Verifying Option $OPTION_ID Deletion..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options/$OPTION_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Verify Option Delete" 4 "$HTTP_STATUS"
# Cleanup: Delete parent part and product
echo "-- Cleanup: Deleting Parent Part $OPTION_PART_ID..."
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Delete Parent Part (Options)" 2 "$HTTP_STATUS"
echo "-- Cleanup: Deleting Parent Product $OPTION_PRODUCT_ID..."
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$OPTION_PRODUCT_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Delete Parent Product (Options)" 2 "$HTTP_STATUS"
echo "----------------------------------------"


# == 4. PartRestrictions (Top Level) ==
echo "🧪 Testing PartRestrictions..."
# Setup: Create Product -> Part -> Option A & Option B
echo "-- Setup: Creating Product, Part, and 2 Options for Restrictions..."
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products" -H "Content-Type: application/json" -d '{"product": {"name": "Restriction Product"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Product (Restrictions)" 2 "$HTTP_STATUS"
RESTRICT_PRODUCT_ID=$(extract_id $TMP_FILE)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts" -H "Content-Type: application/json" -d '{"part": {"name": "Restriction Part"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Part (Restrictions)" 2 "$HTTP_STATUS"
RESTRICT_PART_ID=$(extract_id $TMP_FILE)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts/$RESTRICT_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Restrict Option A", "price": "5"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Option A (Restrictions)" 2 "$HTTP_STATUS"
OPTION_A_ID=$(extract_id $TMP_FILE)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts/$RESTRICT_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Restrict Option B", "price": "6"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Option B (Restrictions)" 2 "$HTTP_STATUS"
OPTION_B_ID=$(extract_id $TMP_FILE)
echo "   -> Product ID: $RESTRICT_PRODUCT_ID, Part ID: $RESTRICT_PART_ID, Option A ID: $OPTION_A_ID, Option B ID: $OPTION_B_ID"
# POST Create Restriction
echo "-- Creating Restriction between Option $OPTION_A_ID and $OPTION_B_ID..."
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/part_restrictions" \
  -H "Content-Type: application/json" \
  -d "{\"part_restriction\": {\"part_option_id\": $OPTION_A_ID, \"restricted_part_option_id\": $OPTION_B_ID}}" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Create Restriction" 2 "$HTTP_STATUS"
RESTRICTION_ID=$(extract_id $TMP_FILE)
echo "   -> Created Restriction ID: $RESTRICTION_ID"
# GET Index Restrictions
echo "-- Getting Restrictions Index..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/part_restrictions" -o $TMP_FILE -w '%{http_code}')
check_status "Get Restrictions Index" 2 "$HTTP_STATUS"
# GET Show Restriction
echo "-- Getting Restriction $RESTRICTION_ID..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/part_restrictions/$RESTRICTION_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Get Restriction Show" 2 "$HTTP_STATUS"
# DELETE Restriction
echo "-- Deleting Restriction $RESTRICTION_ID..."
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/part_restrictions/$RESTRICTION_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Delete Restriction" 2 "$HTTP_STATUS"
# GET Show Restriction (Verify Delete)
echo "-- Verifying Restriction $RESTRICTION_ID Deletion..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/part_restrictions/$RESTRICTION_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Verify Restriction Delete" 4 "$HTTP_STATUS"
# Cleanup
echo "-- Cleanup: Deleting Options, Part, Product (Restrictions)..."
# Note: Restrictions are deleted when options are deleted due to FK constraints or if dependent: :destroy is added later
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts/$RESTRICT_PART_ID/part_options/$OPTION_A_ID" -o /dev/null -w '%{http_code}') # Use /dev/null for body
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts/$RESTRICT_PART_ID/part_options/$OPTION_B_ID" -o /dev/null -w '%{http_code}')
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts/$RESTRICT_PART_ID" -o /dev/null -w '%{http_code}')
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$RESTRICT_PRODUCT_ID" -o /dev/null -w '%{http_code}')
echo "   -> Cleanup done."
echo "----------------------------------------"


# == 5. PriceRules (Top Level) ==
echo "🧪 Testing PriceRules..."
# Setup: Create Product -> Part -> Option C & Option D
echo "-- Setup: Creating Product, Part, and 2 Options for Price Rules..."
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products" -H "Content-Type: application/json" -d '{"product": {"name": "Price Rule Product"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Product (Price Rules)" 2 "$HTTP_STATUS"
RULE_PRODUCT_ID=$(extract_id $TMP_FILE)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$RULE_PRODUCT_ID/parts" -H "Content-Type: application/json" -d '{"part": {"name": "Price Rule Part"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Part (Price Rules)" 2 "$HTTP_STATUS"
RULE_PART_ID=$(extract_id $TMP_FILE)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$RULE_PRODUCT_ID/parts/$RULE_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Rule Option C", "price": "20"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Option C (Price Rules)" 2 "$HTTP_STATUS"
OPTION_C_ID=$(extract_id $TMP_FILE)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$RULE_PRODUCT_ID/parts/$RULE_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Rule Option D", "price": "25"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Option D (Price Rules)" 2 "$HTTP_STATUS"
OPTION_D_ID=$(extract_id $TMP_FILE)
echo "   -> Product ID: $RULE_PRODUCT_ID, Part ID: $RULE_PART_ID, Option C ID: $OPTION_C_ID, Option D ID: $OPTION_D_ID"
# POST Create Price Rule
echo "-- Creating Price Rule between Option $OPTION_C_ID and $OPTION_D_ID..."
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/price_rules" \
  -H "Content-Type: application/json" \
  -d "{\"price_rule\": {\"part_option_a_id\": $OPTION_C_ID, \"part_option_b_id\": $OPTION_D_ID, \"price_premium\": \"5.50\"}}" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Create Price Rule" 2 "$HTTP_STATUS"
RULE_ID=$(extract_id $TMP_FILE)
echo "   -> Created Price Rule ID: $RULE_ID"
# GET Index Price Rules
echo "-- Getting Price Rules Index..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/price_rules" -o $TMP_FILE -w '%{http_code}')
check_status "Get Price Rules Index" 2 "$HTTP_STATUS"
# GET Show Price Rule
echo "-- Getting Price Rule $RULE_ID..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/price_rules/$RULE_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Get Price Rule Show" 2 "$HTTP_STATUS"
# DELETE Price Rule
echo "-- Deleting Price Rule $RULE_ID..."
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/price_rules/$RULE_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Delete Price Rule" 2 "$HTTP_STATUS"
# GET Show Price Rule (Verify Delete)
echo "-- Verifying Price Rule $RULE_ID Deletion..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/price_rules/$RULE_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Verify Price Rule Delete" 4 "$HTTP_STATUS"
# Cleanup
echo "-- Cleanup: Deleting Options, Part, Product (Price Rules)..."
# Note: Price Rules are deleted when options are deleted due to FK constraints or if dependent: :destroy is added later
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$RULE_PRODUCT_ID/parts/$RULE_PART_ID/part_options/$OPTION_C_ID" -o /dev/null -w '%{http_code}')
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$RULE_PRODUCT_ID/parts/$RULE_PART_ID/part_options/$OPTION_D_ID" -o /dev/null -w '%{http_code}')
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$RULE_PRODUCT_ID/parts/$RULE_PART_ID" -o /dev/null -w '%{http_code}')
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$RULE_PRODUCT_ID" -o /dev/null -w '%{http_code}')
echo "   -> Cleanup done."
echo "----------------------------------------"


# == 6. Orders (Top Level) ==
echo "🧪 Testing Orders..."
# Setup: Create Product -> Part -> 4 Options -> 1 Restriction -> 1 Price Rule
echo "-- Setup: Creating Product, Part, Options, Restriction, Price Rule for Orders..."
# Product
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products" -H "Content-Type: application/json" -d '{"product": {"name": "Order Test Product"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Product (Orders)" 2 "$HTTP_STATUS"
ORDER_TEST_PRODUCT_ID=$(extract_id $TMP_FILE)
# Part
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$ORDER_TEST_PRODUCT_ID/parts" -H "Content-Type: application/json" -d '{"part": {"name": "Order Test Part"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Part (Orders)" 2 "$HTTP_STATUS"
ORDER_TEST_PART_ID=$(extract_id $TMP_FILE)
# Option 1 (Base: $10)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$ORDER_TEST_PRODUCT_ID/parts/$ORDER_TEST_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Order Option 1", "price": "10.00"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Option 1 (Orders)" 2 "$HTTP_STATUS"
ORDER_OPTION_1_ID=$(extract_id $TMP_FILE)
# Option 2 (Base: $12, Restricted by Option 1)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$ORDER_TEST_PRODUCT_ID/parts/$ORDER_TEST_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Order Option 2", "price": "12.00"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Option 2 (Orders)" 2 "$HTTP_STATUS"
ORDER_OPTION_2_ID=$(extract_id $TMP_FILE)
# Option 3 (Base: $20, Price Rule with Option 1)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$ORDER_TEST_PRODUCT_ID/parts/$ORDER_TEST_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Order Option 3", "price": "20.00"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Option 3 (Orders)" 2 "$HTTP_STATUS"
ORDER_OPTION_3_ID=$(extract_id $TMP_FILE)
# Option 4 (Base: $15, Will be marked Out of Stock)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/products/$ORDER_TEST_PRODUCT_ID/parts/$ORDER_TEST_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Order Option 4", "price": "15.00"}}' -o $TMP_FILE -w '%{http_code}')
check_status "Create Option 4 (Orders)" 2 "$HTTP_STATUS"
ORDER_OPTION_4_ID=$(extract_id $TMP_FILE)
# Restriction (Option 1 restricts Option 2)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/part_restrictions" -H "Content-Type: application/json" -d "{\"part_restriction\": {\"part_option_id\": $ORDER_OPTION_1_ID, \"restricted_part_option_id\": $ORDER_OPTION_2_ID}}" -o $TMP_FILE -w '%{http_code}')
check_status "Create Restriction (Orders)" 2 "$HTTP_STATUS"
ORDER_TEST_RESTRICTION_ID=$(extract_id $TMP_FILE)
# Price Rule (Option 1 + Option 3 = +$5.00 premium)
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/price_rules" -H "Content-Type: application/json" -d "{\"price_rule\": {\"part_option_a_id\": $ORDER_OPTION_1_ID, \"part_option_b_id\": $ORDER_OPTION_3_ID, \"price_premium\": \"5.00\"}}" -o $TMP_FILE -w '%{http_code}')
check_status "Create Price Rule (Orders)" 2 "$HTTP_STATUS"
ORDER_TEST_RULE_ID=$(extract_id $TMP_FILE)
echo "   -> Setup Complete: Product=$ORDER_TEST_PRODUCT_ID, Part=$ORDER_TEST_PART_ID, Opt1=$ORDER_OPTION_1_ID, Opt2=$ORDER_OPTION_2_ID, Opt3=$ORDER_OPTION_3_ID, Opt4=$ORDER_OPTION_4_ID, Restr=$ORDER_TEST_RESTRICTION_ID, Rule=$ORDER_TEST_RULE_ID"

# POST Create Order - Valid Case
echo "-- Creating Valid Order (Options $ORDER_OPTION_1_ID, $ORDER_OPTION_3_ID)... Expected Price: 10 + 20 + 5 = 35.0"
VALID_ORDER_PAYLOAD="{\"order\": {\"customer_name\": \"Test Customer\", \"customer_email\": \"test@example.com\", \"selected_part_option_ids\": [$ORDER_OPTION_1_ID, $ORDER_OPTION_3_ID]}}"
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/orders" \
  -H "Content-Type: application/json" \
  -d "$VALID_ORDER_PAYLOAD" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Create Valid Order" 2 "$HTTP_STATUS" # Expect 201
ORDER_ID=$(extract_id $TMP_FILE)
echo "   -> Created Order ID: $ORDER_ID"
# Adjusted expected value to match API output format '35.0'
check_json_value $TMP_FILE '.total_price' '35.0' "Verify calculated price"
echo "--- Response Body ---"
$JQ_CMD '.' "$TMP_FILE" # Display body file
echo "----------------"

# POST Create Order - Invalid Case (Restriction Violated)
echo "-- Creating Invalid Order (Options $ORDER_OPTION_1_ID, $ORDER_OPTION_2_ID - Restriction)..."
INVALID_RESTRICTION_PAYLOAD="{\"order\": {\"customer_name\": \"Bad Customer\", \"customer_email\": \"bad@example.com\", \"selected_part_option_ids\": [$ORDER_OPTION_1_ID, $ORDER_OPTION_2_ID]}}"
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/orders" \
  -H "Content-Type: application/json" \
  -d "$INVALID_RESTRICTION_PAYLOAD" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Create Invalid Order (Restriction)" 4 "$HTTP_STATUS" # Expect 422

# POST Create Order - Invalid Case (Bad Option ID)
echo "-- Creating Invalid Order (Option 99999 - Non-existent)..."
INVALID_OPTION_PAYLOAD="{\"order\": {\"customer_name\": \"Ghost Customer\", \"customer_email\": \"ghost@example.com\", \"selected_part_option_ids\": [$ORDER_OPTION_1_ID, 99999]}}"
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/orders" \
  -H "Content-Type: application/json" \
  -d "$INVALID_OPTION_PAYLOAD" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Create Invalid Order (Bad Option ID)" 4 "$HTTP_STATUS" # Expect 404 (or 422 depending on controller logic)

# POST Create Order - Invalid Case (Missing Data)
echo "-- Creating Invalid Order (Missing selected options)..."
INVALID_MISSING_PAYLOAD="{\"order\": {\"customer_name\": \"Forgetful Customer\", \"customer_email\": \"forget@example.com\"}}"
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/orders" \
  -H "Content-Type: application/json" \
  -d "$INVALID_MISSING_PAYLOAD" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Create Invalid Order (Missing Data)" 4 "$HTTP_STATUS" # Expect 422

# GET Index Orders
echo "-- Getting Orders Index..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/orders" -o $TMP_FILE -w '%{http_code}')
check_status "Get Orders Index" 2 "$HTTP_STATUS"
echo "--- Response Body ---"
$JQ_CMD '.' "$TMP_FILE" # Display body file
echo "----------------"

# GET Show Order
echo "-- Getting Order $ORDER_ID..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/orders/$ORDER_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Get Order Show" 2 "$HTTP_STATUS"
echo "--- Response Body ---"
$JQ_CMD '.' "$TMP_FILE" # Display body file
echo "----------------"

# PATCH Update Order Status
echo "-- Updating Order $ORDER_ID Status to 'processing'..."
HTTP_STATUS=$($CURL_CMD -X PATCH "$BASE_URL/orders/$ORDER_ID" \
  -H "Content-Type: application/json" \
  -d '{"order": {"status": "processing"}}' \
  -o $TMP_FILE -w '%{http_code}')
check_status "Update Order Status" 2 "$HTTP_STATUS"
echo "--- Response Body ---"
$JQ_CMD '.' "$TMP_FILE" # Display body file
echo "----------------"

# DELETE Order
echo "-- Deleting Order $ORDER_ID..."
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/orders/$ORDER_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Delete Order" 2 "$HTTP_STATUS" # Expect 204

# GET Show Order (Verify Delete)
echo "-- Verifying Order $ORDER_ID Deletion..."
HTTP_STATUS=$($CURL_CMD "$BASE_URL/orders/$ORDER_ID" -o $TMP_FILE -w '%{http_code}')
check_status "Verify Order Delete" 4 "$HTTP_STATUS" # Expect 404

# Cleanup handled in the next section's cleanup

echo "----------------------------------------"

# == 7. Dynamic Configuration Endpoints ==
echo "🧪 Testing Dynamic Configuration Endpoints..."
# NOTE: Uses setup from Orders section (Product/Part/Options/Rules)
# Make sure the Stock Management changes (#1 in Guide) are applied to the API first!

# Setup: Mark Option 4 as Out of Stock
echo "-- Setup: Marking Option $ORDER_OPTION_4_ID as Out of Stock..."
HTTP_STATUS=$($CURL_CMD -X PATCH "$BASE_URL/products/$ORDER_TEST_PRODUCT_ID/parts/$ORDER_TEST_PART_ID/part_options/$ORDER_OPTION_4_ID" \
  -H "Content-Type: application/json" \
  -d '{"part_option": {"in_stock": false}}' \
  -o $TMP_FILE -w '%{http_code}')
check_status "Mark Option 4 Out of Stock" 2 "$HTTP_STATUS"

# Validate Selection - Valid Case
echo "-- Validating Selection: [$ORDER_OPTION_1_ID, $ORDER_OPTION_3_ID]"
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/product_configuration/validate_selection" \
  -H "Content-Type: application/json" \
  -d "{\"selected_part_option_ids\": [$ORDER_OPTION_1_ID, $ORDER_OPTION_3_ID]}" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Validate Selection - Valid" 2 "$HTTP_STATUS" # Expect 200 OK for validation endpoints
check_json_value $TMP_FILE '.valid' 'true' "Check validation result is true"

# Validate Selection - Invalid Case (Restriction)
echo "-- Validating Selection: [$ORDER_OPTION_1_ID, $ORDER_OPTION_2_ID] (Restriction)"
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/product_configuration/validate_selection" \
  -H "Content-Type: application/json" \
  -d "{\"selected_part_option_ids\": [$ORDER_OPTION_1_ID, $ORDER_OPTION_2_ID]}" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Validate Selection - Restriction" 2 "$HTTP_STATUS"
check_json_value $TMP_FILE '.valid' 'false' "Check validation result is false (Restriction)"

# Validate Selection - Invalid Case (Out of Stock)
echo "-- Validating Selection: [$ORDER_OPTION_1_ID, $ORDER_OPTION_4_ID] (Out of Stock)"
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/product_configuration/validate_selection" \
  -H "Content-Type: application/json" \
  -d "{\"selected_part_option_ids\": [$ORDER_OPTION_1_ID, $ORDER_OPTION_4_ID]}" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Validate Selection - Stock" 2 "$HTTP_STATUS"
check_json_value $TMP_FILE '.valid' 'false' "Check validation result is false (Stock)"

# Validate Selection - Invalid Case (Bad ID)
echo "-- Validating Selection: [$ORDER_OPTION_1_ID, 99999] (Bad ID)"
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/product_configuration/validate_selection" \
  -H "Content-Type: application/json" \
  -d "{\"selected_part_option_ids\": [$ORDER_OPTION_1_ID, 99999]}" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Validate Selection - Bad ID" 2 "$HTTP_STATUS" # Expect 200 OK from validator
check_json_value $TMP_FILE '.valid' 'false' "Check validation result is false (Bad ID)"

# Calculate Price - Valid Case (Base Only)
echo "-- Calculating Price: [$ORDER_OPTION_3_ID, $ORDER_OPTION_4_ID] (Base Only)... Expected: 20 + 15 = 35.0"
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/product_configuration/calculate_price" \
  -H "Content-Type: application/json" \
  -d "{\"selected_part_option_ids\": [$ORDER_OPTION_3_ID, $ORDER_OPTION_4_ID]}" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Calculate Price - Base Only" 2 "$HTTP_STATUS"
# Adjusted expected value to match API output format '35.0'
check_json_value $TMP_FILE '.total_price' '35.0' "Check calculated base price"

# Calculate Price - Valid Case (With Premium)
echo "-- Calculating Price: [$ORDER_OPTION_1_ID, $ORDER_OPTION_3_ID] (With Premium)... Expected: 10 + 20 + 5 = 35.0"
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/product_configuration/calculate_price" \
  -H "Content-Type: application/json" \
  -d "{\"selected_part_option_ids\": [$ORDER_OPTION_1_ID, $ORDER_OPTION_3_ID]}" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Calculate Price - With Premium" 2 "$HTTP_STATUS"
# Adjusted expected value to match API output format '35.0'
check_json_value $TMP_FILE '.total_price' '35.0' "Check calculated price with premium"

# Calculate Price - Invalid Case (Bad ID)
echo "-- Calculating Price: [$ORDER_OPTION_1_ID, 99999] (Bad ID)..."
HTTP_STATUS=$($CURL_CMD -X POST "$BASE_URL/product_configuration/calculate_price" \
  -H "Content-Type: application/json" \
  -d "{\"selected_part_option_ids\": [$ORDER_OPTION_1_ID, 99999]}" \
  -o $TMP_FILE -w '%{http_code}')
check_status "Calculate Price - Bad ID" 4 "$HTTP_STATUS" # Expect 404 Not Found

# Cleanup Order/Dynamic Test Data (Same data used for both)
echo "-- Cleanup: Deleting Rules, Restrictions, Options, Part, Product (Orders/Dynamic)..."
# Delete rules/restrictions first as PartOption doesn't have dependent: :destroy on them
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/part_restrictions/$ORDER_TEST_RESTRICTION_ID" -o /dev/null -w '%{http_code}')
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/price_rules/$ORDER_TEST_RULE_ID" -o /dev/null -w '%{http_code}')
# Deleting product cascades to parts -> options -> order_line_items
HTTP_STATUS=$($CURL_CMD -X DELETE "$BASE_URL/products/$ORDER_TEST_PRODUCT_ID" -o /dev/null -w '%{http_code}')
echo "   -> Cleanup done."


echo "----------------------------------------"
echo "🎉 All API tests completed!"
echo "----------------------------------------"

exit 0
