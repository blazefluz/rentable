# db/seeds.rb
# Sample data for Rentable - Equipment Rental SaaS

puts "🌱 Seeding database..."

# Clear existing data (for development only)
if Rails.env.development?
  puts "Clearing existing data..."
  Booking.destroy_all
  KitItem.destroy_all
  Kit.destroy_all
  Product.destroy_all
end

# Create Products
puts "Creating products..."

camera1 = Product.create!(
  name: "Canon EOS R5",
  description: "45MP full-frame mirrorless camera with 8K video",
  daily_price: Money.new(15000_00, "NGN"), # ₦15,000/day
  quantity: 3,
  category: "Camera",
  barcode: "CAM-R5-001",
  active: true
)

camera2 = Product.create!(
  name: "Sony A7 III",
  description: "24MP full-frame mirrorless camera",
  daily_price: Money.new(10000_00, "NGN"), # ₦10,000/day
  quantity: 5,
  category: "Camera",
  barcode: "CAM-A7III-001",
  active: true
)

lens1 = Product.create!(
  name: "Canon RF 24-70mm f/2.8L",
  description: "Professional zoom lens",
  daily_price: Money.new(5000_00, "NGN"),
  quantity: 4,
  category: "Lens",
  active: true
)

tripod = Product.create!(
  name: "Manfrotto Carbon Fiber Tripod",
  description: "Professional tripod with fluid head",
  daily_price: Money.new(2000_00, "NGN"),
  quantity: 10,
  category: "Support",
  active: true
)

light = Product.create!(
  name: "Aputure 300d II LED Light",
  description: "300W daylight LED",
  daily_price: Money.new(8000_00, "NGN"),
  quantity: 6,
  category: "Lighting",
  active: true
)

mic = Product.create!(
  name: "Rode NTG3 Shotgun Microphone",
  description: "Broadcast quality shotgun mic",
  daily_price: Money.new(3000_00, "NGN"),
  quantity: 8,
  category: "Audio",
  active: true
)

puts "✅ Created #{Product.count} products"

# Create Kits
puts "Creating kits..."

beginner_kit = Kit.create!(
  name: "Beginner Video Kit",
  description: "Everything you need to start shooting video",
  daily_price: Money.new(18000_00, "NGN"),
  active: true
)

beginner_kit.kit_items.create!([
  { product: camera2, quantity: 1 },
  { product: lens1, quantity: 1 },
  { product: tripod, quantity: 1 },
  { product: mic, quantity: 1 }
])

pro_kit = Kit.create!(
  name: "Professional Cinema Kit",
  description: "Complete professional video production setup",
  daily_price: Money.new(35000_00, "NGN"),
  active: true
)

pro_kit.kit_items.create!([
  { product: camera1, quantity: 1 },
  { product: lens1, quantity: 1 },
  { product: tripod, quantity: 1 },
  { product: light, quantity: 2 },
  { product: mic, quantity: 1 }
])

puts "✅ Created #{Kit.count} kits"

# Create sample bookings
puts "Creating sample bookings..."

booking1 = Booking.create!(
  start_date: 3.days.from_now,
  end_date: 5.days.from_now,
  customer_name: "Adebayo Johnson",
  customer_email: "adebayo@example.com",
  customer_phone: "+234 803 123 4567",
  status: :confirmed,
  notes: "Wedding shoot in Lekki"
)

booking1.booking_line_items.create!(
  bookable: camera1,
  quantity: 1
)

booking1.booking_line_items.create!(
  bookable: lens1,
  quantity: 1
)

booking2 = Booking.create!(
  start_date: 7.days.from_now,
  end_date: 10.days.from_now,
  customer_name: "Chioma Nwosu",
  customer_email: "chioma@example.com",
  customer_phone: "+234 810 555 7890",
  status: :paid,
  notes: "Corporate event coverage"
)

booking2.booking_line_items.create!(
  bookable: beginner_kit,
  quantity: 1
)

puts "✅ Created #{Booking.count} bookings"

puts "\n🎉 Seeding complete!"
puts "\nSummary:"
puts "  Products: #{Product.count}"
puts "  Kits: #{Kit.count}"
puts "  Bookings: #{Booking.count}"
puts "\n💡 Try checking availability:"
puts "  Product.first.available?(3.days.from_now, 5.days.from_now, 2)"
