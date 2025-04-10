# db/seeds.rb
#
# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Seeding database..."

# Clear existing data (optional, but helpful for development seeding)
# Destroy in reverse order of dependency
puts "Clearing existing data..."
OrderLineItem.destroy_all
Order.destroy_all
PartRestriction.destroy_all
PriceRule.destroy_all
PartOption.destroy_all
Part.destroy_all
Product.destroy_all

# --- Create Product ---
puts "Creating Product..."
bicycle = Product.create!(
  name: "Custom Bicycle",
  description: "Build your own custom bicycle with various parts and options."
)
puts " -> Created Product: #{bicycle.name}"

# --- Create Parts ---
puts "Creating Parts..."
frame = Part.create!(product: bicycle, name: "Frame")
finish = Part.create!(product: bicycle, name: "Frame Finish")
wheels = Part.create!(product: bicycle, name: "Wheels")
rim_color = Part.create!(product: bicycle, name: "Rim Color")
chain = Part.create!(product: bicycle, name: "Chain")
puts " -> Created Parts: Frame, Frame Finish, Wheels, Rim Color, Chain"

# --- Create Part Options ---
# Store options in a hash for easier access when creating rules/restrictions
options = {}

puts "Creating Part Options..."

# Frame Options
options[:full_suspension] = PartOption.create!(part: frame, name: "Full-suspension", price: 130.00, in_stock: true)
options[:diamond] = PartOption.create!(part: frame, name: "Diamond", price: 90.00, in_stock: true) # Assigned price
options[:step_through] = PartOption.create!(part: frame, name: "Step-through", price: 85.00, in_stock: true) # Assigned price
puts " -> Frame options created."

# Frame Finish Options
# Note: The task describes context-dependent pricing for Matte finish.
# The current model uses base price + premium rules. We approximate here:
# Set a base price for Matte, and add a PriceRule premium for Full-suspension + Matte.
options[:matte_finish] = PartOption.create!(part: finish, name: "Matte", price: 35.00, in_stock: true) # Base price assumption
options[:shiny_finish] = PartOption.create!(part: finish, name: "Shiny", price: 30.00, in_stock: true)
puts " -> Frame Finish options created (Matte price approximated)."

# Wheels Options
options[:road_wheels] = PartOption.create!(part: wheels, name: "Road wheels", price: 80.00, in_stock: true)
options[:mountain_wheels] = PartOption.create!(part: wheels, name: "Mountain wheels", price: 120.00, in_stock: true) # Assigned price
options[:fat_wheels] = PartOption.create!(part: wheels, name: "Fat bike wheels", price: 150.00, in_stock: true) # Assigned price
puts " -> Wheels options created."

# Rim Color Options
options[:red_rim] = PartOption.create!(part: rim_color, name: "Red", price: 20.00, in_stock: true) # Assigned price
options[:black_rim] = PartOption.create!(part: rim_color, name: "Black", price: 15.00, in_stock: true) # Assigned price
options[:blue_rim] = PartOption.create!(part: rim_color, name: "Blue", price: 20.00, in_stock: true)
puts " -> Rim Color options created."

# Chain Options
options[:single_speed_chain] = PartOption.create!(part: chain, name: "Single-speed chain", price: 43.00, in_stock: true)
options[:eight_speed_chain] = PartOption.create!(part: chain, name: "8-speed chain", price: 55.00, in_stock: false) # Assigned price, set out of stock
puts " -> Chain options created."

# --- Create Restrictions ---
puts "Creating Restrictions..."
# If you select "mountain wheels," then the only frame available is the full-suspension.
# (Meaning: Mountain Wheels restricts Diamond and Step-through frames)
PartRestriction.create!(
  part_option: options[:mountain_wheels],
  restricted_part_option: options[:diamond]
)
PartRestriction.create!(
  part_option: options[:mountain_wheels],
  restricted_part_option: options[:step_through]
)
puts " -> Mountain wheels restrictions created."

# If you select "fat bike wheels," then the red rim color is unavailable.
PartRestriction.create!(
  part_option: options[:fat_wheels],
  restricted_part_option: options[:red_rim]
)
puts " -> Fat bike wheels restrictions created."

# --- Create Price Rules (Approximation for Matte Finish) ---
puts "Creating Price Rules..."
# Task: Matte finish over a full-suspension frame costs 50 EUR (vs base 35 EUR).
# Approximation: Add a premium when Matte Finish and Full-suspension are selected together.
# Premium = 50 (target) - 35 (base matte) = 15 EUR
PriceRule.create!(
  part_option_a: options[:full_suspension],
  part_option_b: options[:matte_finish],
  price_premium: 15.00
)
puts " -> Price rule created for Matte Finish + Full-suspension (Approximation)."

# --- Create Sample Order (Optional) ---
# puts "Creating Sample Order..."
# begin
#   order_options = [options[:full_suspension], options[:shiny_finish], options[:road_wheels], options[:blue_rim], options[:single_speed_chain]]
#   # Use logic similar to OrdersController#calculate_total_price (or refactored service)
#   # This is simplified here - assumes no premiums for this combo
#   calculated_price = order_options.sum(&:price)

#   sample_order = Order.create!(
#     customer_name: "John Doe",
#     customer_email: "john.doe@example.com",
#     status: "completed",
#     total_price: calculated_price
#   )
#   order_options.each do |option|
#     OrderLineItem.create!(order: sample_order, part_option: option)
#   end
#   puts " -> Created sample order ##{sample_order.id}"
# rescue => e
#   puts " -> Failed to create sample order: #{e.message}"
# end


puts "Seeding finished."
