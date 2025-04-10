puts "Seeding database..."
puts "Clearing existing data..."
OrderLineItem.destroy_all
Order.destroy_all
PartRestriction.destroy_all
PriceRule.destroy_all
PartOption.destroy_all
Part.destroy_all
Product.destroy_all
puts "Creating Product..."
bicycle = Product.create!(
  name: "Custom Bicycle",
  description: "Build your own custom bicycle with various parts and options."
)
puts " -> Created Product: #{bicycle.name}"
puts "Creating Parts..."
frame = Part.create!(product: bicycle, name: "Frame")
finish = Part.create!(product: bicycle, name: "Frame Finish")
wheels = Part.create!(product: bicycle, name: "Wheels")
rim_color = Part.create!(product: bicycle, name: "Rim Color")
chain = Part.create!(product: bicycle, name: "Chain")
puts " -> Created Parts: Frame, Frame Finish, Wheels, Rim Color, Chain"
options = {}
puts "Creating Part Options..."
options[:full_suspension] = PartOption.create!(part: frame, name: "Full-suspension", price: 130.00, in_stock: true)
options[:diamond] = PartOption.create!(part: frame, name: "Diamond", price: 90.00, in_stock: true) 
options[:step_through] = PartOption.create!(part: frame, name: "Step-through", price: 85.00, in_stock: true) 
puts " -> Frame options created."
options[:matte_finish] = PartOption.create!(part: finish, name: "Matte", price: 35.00, in_stock: true) 
options[:shiny_finish] = PartOption.create!(part: finish, name: "Shiny", price: 30.00, in_stock: true)
puts " -> Frame Finish options created (Matte price approximated)."
options[:road_wheels] = PartOption.create!(part: wheels, name: "Road wheels", price: 80.00, in_stock: true)
options[:mountain_wheels] = PartOption.create!(part: wheels, name: "Mountain wheels", price: 120.00, in_stock: true) 
options[:fat_wheels] = PartOption.create!(part: wheels, name: "Fat bike wheels", price: 150.00, in_stock: true) 
puts " -> Wheels options created."
options[:red_rim] = PartOption.create!(part: rim_color, name: "Red", price: 20.00, in_stock: true) 
options[:black_rim] = PartOption.create!(part: rim_color, name: "Black", price: 15.00, in_stock: true) 
options[:blue_rim] = PartOption.create!(part: rim_color, name: "Blue", price: 20.00, in_stock: true)
puts " -> Rim Color options created."
options[:single_speed_chain] = PartOption.create!(part: chain, name: "Single-speed chain", price: 43.00, in_stock: true)
options[:eight_speed_chain] = PartOption.create!(part: chain, name: "8-speed chain", price: 55.00, in_stock: false) 
puts " -> Chain options created."
puts "Creating Restrictions..."
PartRestriction.create!(
  part_option: options[:mountain_wheels],
  restricted_part_option: options[:diamond]
)
PartRestriction.create!(
  part_option: options[:mountain_wheels],
  restricted_part_option: options[:step_through]
)
puts " -> Mountain wheels restrictions created."
PartRestriction.create!(
  part_option: options[:fat_wheels],
  restricted_part_option: options[:red_rim]
)
puts " -> Fat bike wheels restrictions created."
puts "Creating Price Rules..."
PriceRule.create!(
  part_option_a: options[:full_suspension],
  part_option_b: options[:matte_finish],
  price_premium: 15.00
)
puts " -> Price rule created for Matte Finish + Full-suspension (Approximation)."
puts "Seeding finished."
