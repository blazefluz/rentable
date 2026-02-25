# db/seeds.rb
# Sample data for Rentable - Equipment Rental SaaS

puts "🌱 Seeding database..."

# Clear existing data (for development only)
if Rails.env.development?
  puts "Clearing existing data..."
  Payment.destroy_all
  BookingLineItem.destroy_all
  Booking.destroy_all
  KitItem.destroy_all
  Kit.destroy_all
  Product.destroy_all
  ProductType.destroy_all
  Location.destroy_all
  Client.destroy_all
  Manufacturer.destroy_all
  User.destroy_all
end

# Create Users
puts "Creating users..."

admin = User.create!(
  name: "Admin User",
  email: "admin@rentable.com",
  password: "password123",
  role: :admin
)

manager = User.create!(
  name: "Project Manager",
  email: "manager@rentable.com",
  password: "password123",
  role: :staff
)

puts "✅ Created #{User.count} users"

# Create Manufacturers
puts "Creating manufacturers..."

canon = Manufacturer.create!(
  name: "Canon",
  website: "https://www.canon.com",
  notes: "Leading camera manufacturer"
)

sony = Manufacturer.create!(
  name: "Sony",
  website: "https://www.sony.com"
)

rode = Manufacturer.create!(
  name: "Rode",
  website: "https://www.rode.com"
)

aputure = Manufacturer.create!(
  name: "Aputure",
  website: "https://www.aputure.com"
)

manfrotto = Manufacturer.create!(
  name: "Manfrotto",
  website: "https://www.manfrotto.com"
)

puts "✅ Created #{Manufacturer.count} manufacturers"

# Create Clients
puts "Creating clients..."

client1 = Client.create!(
  name: "ABC Productions Ltd",
  email: "contact@abcprod.com",
  phone: "+234 803 123 4567",
  address: "45 Ogunlana Drive, Surulere, Lagos",
  website: "https://abcproductions.com",
  notes: "Corporate client - 10% discount approved"
)

client2 = Client.create!(
  name: "XYZ Events",
  email: "info@xyzevents.com",
  phone: "+234 810 555 7890",
  address: "12 Admiralty Way, Lekki Phase 1, Lagos"
)

client3 = Client.create!(
  name: "Independent Filmmaker",
  email: "filmmaker@email.com",
  phone: "+234 901 234 5678"
)

puts "✅ Created #{Client.count} clients"

# Create Locations
puts "Creating locations..."

warehouse = Location.create!(
  name: "Main Warehouse",
  address: "78 Warehouse Road, Ikeja, Lagos",
  notes: "Primary storage facility"
)

section_a = Location.create!(
  name: "Section A - Cameras",
  parent: warehouse,
  notes: "Camera storage section"
)

section_b = Location.create!(
  name: "Section B - Lighting",
  parent: warehouse,
  notes: "Lighting equipment"
)

venue1 = Location.create!(
  name: "Eko Hotel & Suites",
  client: client1,
  address: "1415 Adetokunbo Ademola Street, Victoria Island, Lagos"
)

puts "✅ Created #{Location.count} locations"

# Create Product Types
puts "Creating product types..."

camera_type_r5 = ProductType.create!(
  name: "EOS R5",
  description: "45MP full-frame mirrorless camera with 8K video capability",
  category: "Camera",
  manufacturer: canon,
  daily_price: Money.new(150_00, "USD"),
  weekly_price: Money.new(900_00, "USD"),
  value_cents: 3500_00, # $3500 replacement value
  mass: 738.0, # grams
  product_link: "https://www.canon.com/eos-r5",
  custom_fields: {
    sensor: "Full Frame CMOS",
    video: "8K RAW",
    iso_range: "100-51200"
  }
)

camera_type_a7iii = ProductType.create!(
  name: "A7 III",
  description: "24MP full-frame mirrorless camera",
  category: "Camera",
  manufacturer: sony,
  daily_price: Money.new(100_00, "USD"),
  weekly_price: Money.new(600_00, "USD"),
  value_cents: 1998_00,
  mass: 650.0
)

lens_type = ProductType.create!(
  name: "RF 24-70mm f/2.8L IS USM",
  description: "Professional standard zoom lens",
  category: "Lens",
  manufacturer: canon,
  daily_price: Money.new(50_00, "USD"),
  weekly_price: Money.new(300_00, "USD"),
  value_cents: 2299_00,
  mass: 900.0
)

puts "✅ Created #{ProductType.count} product types"

# Create Products
puts "Creating products..."

camera1 = Product.create!(
  name: "Canon EOS R5 #001",
  description: "45MP full-frame mirrorless camera with 8K video",
  product_type: camera_type_r5,
  storage_location: section_a,
  daily_price: Money.new(150_00, "USD"),
  weekly_price: Money.new(900_00, "USD"),
  value_cents: 3500_00,
  quantity: 3,
  category: "Camera",
  barcode: "CAM-R5-001",
  asset_tag: "ASSET-001",
  serial_numbers: ["R5-SN-12345", "R5-SN-12346", "R5-SN-12347"],
  mass: 738.0,
  custom_fields: {
    firmware_version: "1.8.1",
    purchase_date: "2024-01-15",
    warranty_expires: "2027-01-15"
  },
  active: true,
  show_public: true
)

camera2 = Product.create!(
  name: "Sony A7 III #002",
  description: "24MP full-frame mirrorless camera",
  product_type: camera_type_a7iii,
  storage_location: section_a,
  daily_price: Money.new(100_00, "USD"),
  weekly_price: Money.new(600_00, "USD"),
  value_cents: 1998_00,
  quantity: 5,
  category: "Camera",
  barcode: "CAM-A7III-001",
  asset_tag: "ASSET-002",
  active: true
)

lens1 = Product.create!(
  name: "Canon RF 24-70mm f/2.8L #003",
  description: "Professional zoom lens",
  product_type: lens_type,
  storage_location: section_a,
  daily_price: Money.new(50_00, "USD"),
  weekly_price: Money.new(300_00, "USD"),
  value_cents: 2299_00,
  quantity: 4,
  category: "Lens",
  asset_tag: "ASSET-003",
  active: true
)

tripod = Product.create!(
  name: "Manfrotto Carbon Fiber Tripod",
  description: "Professional tripod with fluid head",
  storage_location: section_a,
  daily_price: Money.new(20_00, "USD"),
  weekly_price: Money.new(120_00, "USD"),
  value_cents: 500_00,
  quantity: 10,
  category: "Support",
  active: true
)

light = Product.create!(
  name: "Aputure 300d II LED Light",
  description: "300W daylight LED",
  storage_location: section_b,
  daily_price: Money.new(80_00, "USD"),
  weekly_price: Money.new(480_00, "USD"),
  value_cents: 800_00,
  quantity: 6,
  category: "Lighting",
  active: true
)

mic = Product.create!(
  name: "Rode NTG3 Shotgun Microphone",
  description: "Broadcast quality shotgun mic",
  storage_location: section_a,
  daily_price: Money.new(30_00, "USD"),
  weekly_price: Money.new(180_00, "USD"),
  value_cents: 699_00,
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
  daily_price: Money.new(180_00, "USD"), # $180/day
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
  daily_price: Money.new(350_00, "USD"), # $350/day
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
  client: client1,
  manager: manager,
  venue_location: venue1,
  start_date: 3.days.from_now,
  end_date: 5.days.from_now,
  delivery_start_date: 3.days.from_now - 2.hours,
  delivery_end_date: 5.days.from_now + 3.hours,
  customer_name: "Adebayo Johnson",
  customer_email: "adebayo@example.com",
  customer_phone: "+234 803 123 4567",
  status: :confirmed,
  notes: "Wedding shoot in Lekki",
  invoice_notes: "Payment due on delivery",
  default_discount: 5.0
)

booking1.booking_line_items.create!(
  bookable: camera1,
  quantity: 1,
  workflow_status: :packed,
  discount_percent: 5.0
)

booking1.booking_line_items.create!(
  bookable: lens1,
  quantity: 1,
  workflow_status: :packed,
  discount_percent: 5.0
)

# Add payment
booking1.payments.create!(
  payment_type: :payment_received,
  amount: Money.new(500_00, "USD"),
  payment_date: 1.day.ago,
  payment_method: "Bank Transfer",
  reference: "TRX-#{SecureRandom.hex(4).upcase}",
  comment: "50% deposit received"
)

booking2 = Booking.create!(
  client: client2,
  manager: manager,
  start_date: 7.days.from_now,
  end_date: 10.days.from_now,
  delivery_start_date: 7.days.from_now - 1.hour,
  delivery_end_date: 10.days.from_now + 2.hours,
  customer_name: "Chioma Nwosu",
  customer_email: "chioma@example.com",
  customer_phone: "+234 810 555 7890",
  status: :paid,
  notes: "Corporate event coverage"
)

booking2.booking_line_items.create!(
  bookable: beginner_kit,
  quantity: 1,
  workflow_status: :prepping
)

# Add full payment
booking2.payments.create!(
  payment_type: :payment_received,
  amount: booking2.total_price,
  payment_date: Time.current,
  payment_method: "Credit Card",
  reference: "TRX-#{SecureRandom.hex(4).upcase}",
  comment: "Full payment received"
)

# Create a booking with subhire and staff costs
booking3 = Booking.create!(
  client: client3,
  start_date: 14.days.from_now,
  end_date: 16.days.from_now,
  customer_name: "Independent Filmmaker",
  customer_email: "filmmaker@email.com",
  customer_phone: "+234 901 234 5678",
  status: :confirmed,
  notes: "Film production"
)

booking3.booking_line_items.create!(
  bookable: pro_kit,
  quantity: 1,
  workflow_status: :pending_pick
)

# Add subhire cost
booking3.payments.create!(
  payment_type: :subhire,
  amount: Money.new(200_00, "USD"),
  quantity: 1,
  supplier: "External Rental Co.",
  comment: "Rented additional 4K monitor",
  payment_date: Time.current
)

# Add staff cost
booking3.payments.create!(
  payment_type: :staff_cost,
  amount: Money.new(150_00, "USD"),
  quantity: 8, # hours
  comment: "Technician support - 8 hours",
  payment_date: Time.current
)

puts "✅ Created #{Booking.count} bookings with #{Payment.count} payments"

puts "\n🎉 Seeding complete!"
puts "\nSummary:"
puts "  Users: #{User.count}"
puts "  Manufacturers: #{Manufacturer.count}"
puts "  Clients: #{Client.count}"
puts "  Locations: #{Location.count}"
puts "  Product Types: #{ProductType.count}"
puts "  Products: #{Product.count}"
puts "  Kits: #{Kit.count}"
puts "  Bookings: #{Booking.count}"
puts "  Payments: #{Payment.count}"
puts "\n💡 Test credentials:"
puts "  Admin: admin@rentable.com / password123"
puts "  Manager: manager@rentable.com / password123"
puts "\n💡 Try checking availability:"
puts "  Product.first.available?(3.days.from_now, 5.days.from_now, 2)"
puts "  Booking.first.balance_due"
puts "  Location.find_by(name: 'Section A - Cameras').full_path"
