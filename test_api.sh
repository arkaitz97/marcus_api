#!/bin/bash

# Simple API Test Script for Product Configurator

# --- Configuration ---
BASE_URL="http://localhost:3000/api/v1"
# Use -s for silent curl when just checking status or extracting IDs
# Use | jq for pretty printing JSON output
JQ_CMD="jq" # Assumes jq is in PATH
CURL_CMD="curl -s" # Start with silent

# --- Helper Functions ---

# Function to check the last command's exit status and print message
check_status() {
  local status=$?
  local message=$1
  local expected_status=${2:-2} # Default expected HTTP status prefix is '2' (2xx)

  # Check command exit status (0 means curl executed successfully)
  if [ $status -ne 0 ]; then
    echo "❌ ERROR: curl command failed for '$message'."
    exit 1
  fi

  # Check HTTP status code from curl output file ($TMP_FILE)
  local http_status=$(cat $TMP_FILE | $JQ_CMD -r '.http_status // empty')
  if [[ -z "$http_status" ]]; then
     echo "⚠️ WARNING: Could not extract HTTP status for '$message'. Check curl output."
     # Optionally show body on warning:
     # echo "--- Response Body ---"
     # cat $TMP_FILE | $JQ_CMD '.'
     # echo "---------------------"
     return # Don't exit, but warn
  fi

  # Check if HTTP status starts with the expected prefix (e.g., 2 for 2xx, 4 for 4xx)
  if [[ "$http_status" != ${expected_status}* ]]; then
    echo "❌ FAILED: '$message'. Expected status ${expected_status}xx, but got $http_status."
    echo "--- Response Body ---"
    cat $TMP_FILE | $JQ_CMD '.' # Print JSON body on failure
    echo "---------------------"
    exit 1
  else
    echo "✅ PASSED: '$message' (Status: $http_status)."
  fi
}

# Function to extract ID from JSON response
extract_id() {
  local json_file=$1
  local id_field=${2:-id} # Default field name is 'id'
  local extracted_id=$(cat $json_file | $JQ_CMD -r ".$id_field // empty")

  if [[ -z "$extracted_id" || "$extracted_id" == "null" ]]; then
    echo "❌ ERROR: Could not extract '$id_field' from response."
    echo "--- Response Body ---"
    cat $json_file | $JQ_CMD '.'
    echo "---------------------"
    exit 1
  fi
  echo "$extracted_id" # Return the extracted ID
}

# Temporary file for curl output
TMP_FILE=$(mktemp)
# Cleanup temp file on exit
trap 'rm -f $TMP_FILE' EXIT

# --- Test Execution ---

echo "🚀 Starting API Tests..."
echo "Base URL: $BASE_URL"
echo "Requires 'curl' and 'jq'."
echo "Ensure Rails server is running!"
echo "----------------------------------------"

# == 1. Products ==
echo "🧪 Testing Products..."
# POST Create
echo "-- Creating Product..."
$CURL_CMD -X POST "$BASE_URL/products" \
  -H "Content-Type: application/json" \
  -d '{"product": {"name": "Test Product", "description": "Initial Description"}}' \
  -w '\n{"http_status":%{http_code}}' -o $TMP_FILE # Write body and status to file
check_status "Create Product" 2 # Expect 201
PRODUCT_ID=$(extract_id $TMP_FILE)
echo "   -> Created Product ID: $PRODUCT_ID"
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d' # Print body, remove status line
echo "----------------"

# GET Index
echo "-- Getting Product Index..."
$CURL_CMD "$BASE_URL/products" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Get Product Index" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# GET Show
echo "-- Getting Product $PRODUCT_ID..."
$CURL_CMD "$BASE_URL/products/$PRODUCT_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Get Product Show" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# PUT Update
echo "-- Updating Product $PRODUCT_ID..."
$CURL_CMD -X PUT "$BASE_URL/products/$PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d '{"product": {"description": "Updated Description"}}' \
  -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Update Product" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# DELETE
echo "-- Deleting Product $PRODUCT_ID..."
$CURL_CMD -X DELETE "$BASE_URL/products/$PRODUCT_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Delete Product" 2 # Expect 204

# GET Show (Verify Delete)
echo "-- Verifying Product $PRODUCT_ID Deletion..."
$CURL_CMD "$BASE_URL/products/$PRODUCT_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Verify Product Delete" 4 # Expect 404

echo "----------------------------------------"

# == 2. Parts (Nested under Products) ==
echo "🧪 Testing Parts..."
# Setup: Create a parent product
echo "-- Setup: Creating Parent Product for Parts..."
$CURL_CMD -X POST "$BASE_URL/products" \
  -H "Content-Type: application/json" \
  -d '{"product": {"name": "Part Parent Product", "description": "Holds parts"}}' \
  -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Parent Product (Parts)" 2
PARENT_PRODUCT_ID=$(extract_id $TMP_FILE)
echo "   -> Parent Product ID: $PARENT_PRODUCT_ID"

# POST Create Part
echo "-- Creating Part under Product $PARENT_PRODUCT_ID..."
$CURL_CMD -X POST "$BASE_URL/products/$PARENT_PRODUCT_ID/parts" \
  -H "Content-Type: application/json" \
  -d '{"part": {"name": "Test Part 1"}}' \
  -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Part" 2
PART_ID=$(extract_id $TMP_FILE)
echo "   -> Created Part ID: $PART_ID"
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# GET Index Parts
echo "-- Getting Parts Index for Product $PARENT_PRODUCT_ID..."
$CURL_CMD "$BASE_URL/products/$PARENT_PRODUCT_ID/parts" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Get Parts Index" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# GET Show Part
echo "-- Getting Part $PART_ID for Product $PARENT_PRODUCT_ID..."
$CURL_CMD "$BASE_URL/products/$PARENT_PRODUCT_ID/parts/$PART_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Get Part Show" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# PUT Update Part
echo "-- Updating Part $PART_ID for Product $PARENT_PRODUCT_ID..."
$CURL_CMD -X PUT "$BASE_URL/products/$PARENT_PRODUCT_ID/parts/$PART_ID" \
  -H "Content-Type: application/json" \
  -d '{"part": {"name": "Updated Test Part 1"}}' \
  -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Update Part" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# DELETE Part
echo "-- Deleting Part $PART_ID for Product $PARENT_PRODUCT_ID..."
$CURL_CMD -X DELETE "$BASE_URL/products/$PARENT_PRODUCT_ID/parts/$PART_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Delete Part" 2

# GET Show Part (Verify Delete)
echo "-- Verifying Part $PART_ID Deletion..."
$CURL_CMD "$BASE_URL/products/$PARENT_PRODUCT_ID/parts/$PART_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Verify Part Delete" 4

# Cleanup: Delete parent product
echo "-- Cleanup: Deleting Parent Product $PARENT_PRODUCT_ID..."
$CURL_CMD -X DELETE "$BASE_URL/products/$PARENT_PRODUCT_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Delete Parent Product (Parts)" 2

echo "----------------------------------------"

# == 3. PartOptions (Nested under Parts) ==
echo "🧪 Testing PartOptions..."
# Setup: Create Product and Part
echo "-- Setup: Creating Product & Part for Options..."
$CURL_CMD -X POST "$BASE_URL/products" -H "Content-Type: application/json" -d '{"product": {"name": "Option Parent Product"}}' -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Product (Options)" 2
OPTION_PRODUCT_ID=$(extract_id $TMP_FILE)
$CURL_CMD -X POST "$BASE_URL/products/$OPTION_PRODUCT_ID/parts" -H "Content-Type: application/json" -d '{"part": {"name": "Option Parent Part"}}' -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Part (Options)" 2
OPTION_PART_ID=$(extract_id $TMP_FILE)
echo "   -> Product ID: $OPTION_PRODUCT_ID, Part ID: $OPTION_PART_ID"

# POST Create Option
echo "-- Creating Option under Part $OPTION_PART_ID..."
$CURL_CMD -X POST "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options" \
  -H "Content-Type: application/json" \
  -d '{"part_option": {"name": "Option A", "price": "10.50"}}' \
  -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Option" 2
OPTION_ID=$(extract_id $TMP_FILE)
echo "   -> Created Option ID: $OPTION_ID"
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# GET Index Options
echo "-- Getting Options Index for Part $OPTION_PART_ID..."
$CURL_CMD "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Get Options Index" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# GET Show Option
echo "-- Getting Option $OPTION_ID for Part $OPTION_PART_ID..."
$CURL_CMD "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options/$OPTION_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Get Option Show" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# PUT Update Option
echo "-- Updating Option $OPTION_ID for Part $OPTION_PART_ID..."
$CURL_CMD -X PUT "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options/$OPTION_ID" \
  -H "Content-Type: application/json" \
  -d '{"part_option": {"name": "Option A Updated", "price": "12.99"}}' \
  -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Update Option" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# DELETE Option
echo "-- Deleting Option $OPTION_ID for Part $OPTION_PART_ID..."
$CURL_CMD -X DELETE "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options/$OPTION_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Delete Option" 2

# GET Show Option (Verify Delete)
echo "-- Verifying Option $OPTION_ID Deletion..."
$CURL_CMD "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID/part_options/$OPTION_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Verify Option Delete" 4

# Cleanup: Delete parent part and product
echo "-- Cleanup: Deleting Parent Part $OPTION_PART_ID..."
$CURL_CMD -X DELETE "$BASE_URL/products/$OPTION_PRODUCT_ID/parts/$OPTION_PART_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Delete Parent Part (Options)" 2
echo "-- Cleanup: Deleting Parent Product $OPTION_PRODUCT_ID..."
$CURL_CMD -X DELETE "$BASE_URL/products/$OPTION_PRODUCT_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Delete Parent Product (Options)" 2

echo "----------------------------------------"

# == 4. PartRestrictions (Top Level) ==
echo "🧪 Testing PartRestrictions..."
# Setup: Create Product -> Part -> Option A & Option B
echo "-- Setup: Creating Product, Part, and 2 Options for Restrictions..."
$CURL_CMD -X POST "$BASE_URL/products" -H "Content-Type: application/json" -d '{"product": {"name": "Restriction Product"}}' -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Product (Restrictions)" 2
RESTRICT_PRODUCT_ID=$(extract_id $TMP_FILE)
$CURL_CMD -X POST "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts" -H "Content-Type: application/json" -d '{"part": {"name": "Restriction Part"}}' -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Part (Restrictions)" 2
RESTRICT_PART_ID=$(extract_id $TMP_FILE)
$CURL_CMD -X POST "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts/$RESTRICT_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Restrict Option A", "price": "5"}}' -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Option A (Restrictions)" 2
OPTION_A_ID=$(extract_id $TMP_FILE)
$CURL_CMD -X POST "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts/$RESTRICT_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Restrict Option B", "price": "6"}}' -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Option B (Restrictions)" 2
OPTION_B_ID=$(extract_id $TMP_FILE)
echo "   -> Product ID: $RESTRICT_PRODUCT_ID, Part ID: $RESTRICT_PART_ID, Option A ID: $OPTION_A_ID, Option B ID: $OPTION_B_ID"

# POST Create Restriction
echo "-- Creating Restriction between Option $OPTION_A_ID and $OPTION_B_ID..."
$CURL_CMD -X POST "$BASE_URL/part_restrictions" \
  -H "Content-Type: application/json" \
  -d "{\"part_restriction\": {\"part_option_id\": $OPTION_A_ID, \"restricted_part_option_id\": $OPTION_B_ID}}" \
  -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Restriction" 2
RESTRICTION_ID=$(extract_id $TMP_FILE)
echo "   -> Created Restriction ID: $RESTRICTION_ID"
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# GET Index Restrictions
echo "-- Getting Restrictions Index..."
$CURL_CMD "$BASE_URL/part_restrictions" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Get Restrictions Index" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# GET Show Restriction
echo "-- Getting Restriction $RESTRICTION_ID..."
$CURL_CMD "$BASE_URL/part_restrictions/$RESTRICTION_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Get Restriction Show" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# DELETE Restriction
echo "-- Deleting Restriction $RESTRICTION_ID..."
$CURL_CMD -X DELETE "$BASE_URL/part_restrictions/$RESTRICTION_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Delete Restriction" 2

# GET Show Restriction (Verify Delete)
echo "-- Verifying Restriction $RESTRICTION_ID Deletion..."
$CURL_CMD "$BASE_URL/part_restrictions/$RESTRICTION_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Verify Restriction Delete" 4

# Cleanup
echo "-- Cleanup: Deleting Options, Part, Product (Restrictions)..."
$CURL_CMD -X DELETE "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts/$RESTRICT_PART_ID/part_options/$OPTION_A_ID" > /dev/null 2>&1
$CURL_CMD -X DELETE "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts/$RESTRICT_PART_ID/part_options/$OPTION_B_ID" > /dev/null 2>&1
$CURL_CMD -X DELETE "$BASE_URL/products/$RESTRICT_PRODUCT_ID/parts/$RESTRICT_PART_ID" > /dev/null 2>&1
$CURL_CMD -X DELETE "$BASE_URL/products/$RESTRICT_PRODUCT_ID" > /dev/null 2>&1
echo "   -> Cleanup done."

echo "----------------------------------------"

# == 5. PriceRules (Top Level) ==
echo "🧪 Testing PriceRules..."
# Setup: Create Product -> Part -> Option C & Option D
echo "-- Setup: Creating Product, Part, and 2 Options for Price Rules..."
$CURL_CMD -X POST "$BASE_URL/products" -H "Content-Type: application/json" -d '{"product": {"name": "Price Rule Product"}}' -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Product (Price Rules)" 2
RULE_PRODUCT_ID=$(extract_id $TMP_FILE)
$CURL_CMD -X POST "$BASE_URL/products/$RULE_PRODUCT_ID/parts" -H "Content-Type: application/json" -d '{"part": {"name": "Price Rule Part"}}' -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Part (Price Rules)" 2
RULE_PART_ID=$(extract_id $TMP_FILE)
$CURL_CMD -X POST "$BASE_URL/products/$RULE_PRODUCT_ID/parts/$RULE_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Rule Option C", "price": "20"}}' -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Option C (Price Rules)" 2
OPTION_C_ID=$(extract_id $TMP_FILE)
$CURL_CMD -X POST "$BASE_URL/products/$RULE_PRODUCT_ID/parts/$RULE_PART_ID/part_options" -H "Content-Type: application/json" -d '{"part_option": {"name": "Rule Option D", "price": "25"}}' -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Option D (Price Rules)" 2
OPTION_D_ID=$(extract_id $TMP_FILE)
echo "   -> Product ID: $RULE_PRODUCT_ID, Part ID: $RULE_PART_ID, Option C ID: $OPTION_C_ID, Option D ID: $OPTION_D_ID"

# POST Create Price Rule
echo "-- Creating Price Rule between Option $OPTION_C_ID and $OPTION_D_ID..."
$CURL_CMD -X POST "$BASE_URL/price_rules" \
  -H "Content-Type: application/json" \
  -d "{\"price_rule\": {\"part_option_a_id\": $OPTION_C_ID, \"part_option_b_id\": $OPTION_D_ID, \"price_premium\": \"5.50\"}}" \
  -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Create Price Rule" 2
RULE_ID=$(extract_id $TMP_FILE)
echo "   -> Created Price Rule ID: $RULE_ID"
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# GET Index Price Rules
echo "-- Getting Price Rules Index..."
$CURL_CMD "$BASE_URL/price_rules" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Get Price Rules Index" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# GET Show Price Rule
echo "-- Getting Price Rule $RULE_ID..."
$CURL_CMD "$BASE_URL/price_rules/$RULE_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Get Price Rule Show" 2
echo "--- Response ---"
cat $TMP_FILE | $JQ_CMD '.' | sed '$d'
echo "----------------"

# DELETE Price Rule
echo "-- Deleting Price Rule $RULE_ID..."
$CURL_CMD -X DELETE "$BASE_URL/price_rules/$RULE_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Delete Price Rule" 2

# GET Show Price Rule (Verify Delete)
echo "-- Verifying Price Rule $RULE_ID Deletion..."
$CURL_CMD "$BASE_URL/price_rules/$RULE_ID" -o $TMP_FILE -w '\n{"http_status":%{http_code}}'
check_status "Verify Price Rule Delete" 4

# Cleanup
echo "-- Cleanup: Deleting Options, Part, Product (Price Rules)..."
$CURL_CMD -X DELETE "$BASE_URL/products/$RULE_PRODUCT_ID/parts/$RULE_PART_ID/part_options/$OPTION_C_ID" > /dev/null 2>&1
$CURL_CMD -X DELETE "$BASE_URL/products/$RULE_PRODUCT_ID/parts/$RULE_PART_ID/part_options/$OPTION_D_ID" > /dev/null 2>&1
$CURL_CMD -X DELETE "$BASE_URL/products/$RULE_PRODUCT_ID/parts/$RULE_PART_ID" > /dev/null 2>&1
$CURL_CMD -X DELETE "$BASE_URL/products/$RULE_PRODUCT_ID" > /dev/null 2>&1
echo "   -> Cleanup done."

echo "----------------------------------------"
echo "🎉 All API tests completed!"
echo "----------------------------------------"

exit 0

