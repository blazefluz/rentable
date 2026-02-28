# Epic: Delivery Route Optimization

**Epic ID**: ROUTE
**Status**: Backlog
**Priority**: CRITICAL
**Business Value**: HIGH
**Target Release**: Phase 2 - Q3 2026

---

## Overview

Intelligent route optimization for delivery and pickup logistics. Automatically generates optimal routes for drivers to minimize fuel costs, reduce delivery time, and maximize daily deliveries. Essential for rental companies with delivery services.

## Business Problem

Current manual route planning results in:
- 30-40% more fuel consumption than optimal routes
- Drivers spending 20-30% more time on the road
- 20% fewer deliveries per day vs. optimal capacity
- Missed delivery windows and angry customers
- Driver fatigue from inefficient routing
- Average cost: $150-300 per day in wasted fuel and time

## Success Metrics

- **Primary**: 25% reduction in total delivery route distance
- **Secondary**:
  - 30% more deliveries per driver per day
  - 95% on-time delivery rate
  - 20% reduction in fuel costs
  - <5 seconds to generate optimized route for 20 stops

## User Personas

1. **Delivery Coordinator** - Plans daily routes for multiple drivers
2. **Delivery Driver** - Follows optimized route, marks deliveries complete
3. **Operations Manager** - Monitors delivery performance metrics
4. **Customer** - Receives accurate delivery time windows

---

## User Stories

### Must Have (P0)
- [ ] ROUTE-101: Generate optimized route for multiple stops (13 pts)
- [ ] ROUTE-102: Real-time route navigation integration (Google Maps) (8 pts)
- [ ] ROUTE-103: Delivery time window estimation (5 pts)
- [ ] ROUTE-104: Mobile app for drivers with turn-by-turn directions (13 pts)
- [ ] ROUTE-105: Mark deliveries as completed with timestamp (5 pts)

### Should Have (P1)
- [ ] ROUTE-106: Re-optimize route for traffic/delays (8 pts)
- [ ] ROUTE-107: Multi-vehicle route optimization (distribute across drivers) (13 pts)
- [ ] ROUTE-108: Customer delivery notifications (SMS/email on way) (5 pts)
- [ ] ROUTE-109: Route history and replay (3 pts)
- [ ] ROUTE-110: Delivery zones and territory management (5 pts)

### Nice to Have (P2)
- [ ] ROUTE-111: Live driver tracking on map (8 pts)
- [ ] ROUTE-112: Route performance analytics (fuel saved, time saved) (5 pts)
- [ ] ROUTE-113: Delivery capacity planning (how many trucks needed) (5 pts)
- [ ] ROUTE-114: Customer self-schedule delivery time (8 pts)

**Total Story Points**: 102 pts (Must Have: 44 pts)

---

## Technical Architecture

### New Models
```ruby
class DeliveryRoute < ApplicationRecord
  belongs_to :company
  belongs_to :driver, class_name: 'User'
  has_many :route_stops, -> { order(sequence: :asc) }, dependent: :destroy

  enum status: [:planned, :in_progress, :completed, :cancelled]

  validates :scheduled_date, presence: true

  # Calculate total distance/duration
  def total_distance_miles
    route_stops.sum(:distance_to_next_miles)
  end

  def estimated_duration_minutes
    route_stops.sum(:estimated_duration_minutes)
  end
end

class RouteStop < ApplicationRecord
  belongs_to :delivery_route
  belongs_to :booking

  enum stop_type: [:pickup, :delivery, :both]
  enum status: [:pending, :en_route, :completed, :failed]

  validates :sequence, presence: true
  validates :address, presence: true

  # Geocoding
  geocoded_by :address
  after_validation :geocode, if: :address_changed?
end

class DeliveryZone < ApplicationRecord
  belongs_to :company

  # Polygon or radius definition
  validates :name, presence: true
end
```

### New Tables
- `delivery_routes` - Daily route plans
- `route_stops` - Individual stops on a route
- `delivery_zones` - Geographic service areas
- `route_optimization_cache` - Cache optimized routes for common patterns
- `driver_locations` - Real-time GPS tracking (optional)

### API Endpoints
```
# Route Planning
POST   /api/v1/delivery_routes/optimize        # Generate optimized route
GET    /api/v1/delivery_routes                 # List routes
GET    /api/v1/delivery_routes/:id             # Route details
PATCH  /api/v1/delivery_routes/:id/re_optimize # Re-optimize existing route

# Route Execution (Driver Mobile App)
GET    /api/v1/delivery_routes/my_route        # Driver's assigned route
POST   /api/v1/route_stops/:id/start           # Mark en route
POST   /api/v1/route_stops/:id/complete        # Mark completed
POST   /api/v1/route_stops/:id/failed          # Mark failed (customer not home)
POST   /api/v1/delivery_routes/:id/location    # Update GPS location

# Customer Tracking
GET    /api/v1/bookings/:id/delivery_status    # Where's my delivery?
GET    /api/v1/bookings/:id/delivery_eta       # When will it arrive?

# Analytics
GET    /api/v1/delivery_routes/analytics       # Performance metrics
```

### Services
```ruby
class RouteOptimizationService
  # Uses Google Maps Distance Matrix API + optimization algorithm
  def optimize(stops:, start_location:, end_location:, vehicle_capacity:)
    # 1. Get distance/duration matrix for all stop pairs
    # 2. Solve Traveling Salesman Problem (TSP) variant
    # 3. Return optimized sequence of stops
  end

  def calculate_time_windows(route)
    # Given optimized route, calculate realistic arrival times
  end

  private

  def solve_tsp(distance_matrix)
    # Use nearest neighbor heuristic or 2-opt improvement
    # Or call external service (Google OR-Tools, Routific)
  end
end

class DistanceMatrixService
  # Google Maps Distance Matrix API
  def get_distances(origins, destinations)
    # Returns travel time and distance between all point pairs
  end
end

class DeliveryNotificationService
  # Customer notifications
  def notify_on_the_way(booking, estimated_arrival)
  def notify_arrived(booking)
  def notify_completed(booking)
end

class RoutePerformanceService
  # Analytics
  def calculate_efficiency(route)
    actual_distance = route.actual_distance_miles
    optimal_distance = calculate_theoretical_optimal(route.route_stops)
    efficiency = (optimal_distance / actual_distance) * 100
  end
end
```

### Background Jobs
- `RouteOptimizerJob` - Heavy optimization calculations
- `DeliveryReminderJob` - Send customer notifications
- `RoutePerformanceReportJob` - Daily performance reports

---

## Route Optimization Algorithm

### Simple Implementation (Phase 1)
```ruby
# Nearest Neighbor Heuristic (fast, 80% optimal)
def nearest_neighbor_route(stops, start_location)
  route = [start_location]
  remaining = stops.dup
  current = start_location

  while remaining.any?
    # Find closest unvisited stop
    nearest = remaining.min_by { |stop| distance(current, stop) }
    route << nearest
    remaining.delete(nearest)
    current = nearest
  end

  route
end
```

### Advanced Implementation (Phase 2)
```ruby
# 2-opt improvement (iterative improvement, 95% optimal)
def two_opt_improve(route)
  improved = true
  while improved
    improved = false
    route.combination(2).each do |i, j|
      if swap_improves_route?(route, i, j)
        route = swap_segments(route, i, j)
        improved = true
      end
    end
  end
  route
end
```

### External Service (Future)
- Google OR-Tools (free, open-source)
- Routific API (paid, specialized for delivery)
- Route4Me API (paid)

---

## Google Maps Integration

### Distance Matrix API
```ruby
# Get travel times between all locations
require 'google_maps_service'

gmaps = GoogleMapsService::Client.new(key: ENV['GOOGLE_MAPS_API_KEY'])

origins = stops.map { |s| "#{s.latitude},#{s.longitude}" }
destinations = origins

matrix = gmaps.distance_matrix(
  origins,
  destinations,
  mode: 'driving',
  departure_time: Time.now.to_i,  # Account for current traffic
  traffic_model: 'best_guess'
)

# matrix.rows[i].elements[j].duration.value = seconds from i to j
```

### Directions API (Turn-by-turn)
```ruby
# Get detailed directions for optimized route
directions = gmaps.directions(
  "#{start_lat},#{start_lng}",
  "#{end_lat},#{end_lng}",
  waypoints: waypoints,
  optimize_waypoints: false,  # We already optimized
  departure_time: Time.now.to_i
)

# Returns detailed steps for navigation
```

---

## Mobile App Requirements

### Driver Features
- View assigned route for the day
- See all stops in optimized order
- One-tap navigation to next stop (opens Google Maps/Waze)
- Mark stop as completed
- Upload photo proof of delivery
- Report issues (customer not home, address wrong, etc.)
- View estimated time to complete route
- Offline mode (cached route)

### UI Mockup
```
╔════════════════════════════════╗
║  Today's Route - 12 Stops      ║
║  Total Distance: 45 mi         ║
║  Est. Completion: 4:30 PM      ║
╠════════════════════════════════╣
║  ▶ Next Stop (5 min away)      ║
║  📍 123 Main St                 ║
║  🚚 Pickup: Table & Chairs      ║
║  📞 Call Customer               ║
║  🧭 Navigate                    ║
║  ✓ Mark Complete                ║
╠════════════════════════════════╣
║  Stop 2 (15 min away)          ║
║  📍 456 Oak Ave                 ║
║  🚚 Delivery: Tent              ║
╠════════════════════════════════╣
║  ... (10 more stops)           ║
╚════════════════════════════════╝
```

---

## Dependencies

### Blocking
- Google Maps API key and billing enabled
- Booking system with addresses (existing)

### Integration Points
- SMS/Email notifications (EMAIL epic)
- Mobile app framework (MOBILE epic)
- Calendar integration (CAL epic)
- Proof of delivery photos (POD epic)

---

## Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Google Maps API costs | High | Medium | Set daily quota limits, cache results |
| Algorithm complexity (scale) | Medium | High | Start simple (nearest neighbor), iterate |
| Inaccurate addresses | High | Medium | Address validation, geocoding confidence scores |
| Real-time traffic changes | High | Medium | Allow manual re-optimization |
| Driver doesn't follow route | Medium | Low | GPS tracking, performance incentives |

---

## Cost Analysis

### Google Maps API Costs
- **Distance Matrix**: $5 per 1000 requests
- **Directions**: $5 per 1000 requests

Example monthly cost (20 routes/day, 30 days, avg 10 stops):
- Distance Matrix: 20 routes * 10 stops * 10 stops * 30 days = 60,000 requests = $300/mo
- Directions: 20 routes * 30 days = 600 requests = $3/mo
- **Total**: ~$300-400/mo

**ROI**: Saves $150/day in fuel/time = $4,500/mo → **14x ROI**

---

## Out of Scope

- Fleet management (vehicle maintenance tracking) - Different epic
- Driver payroll/hours tracking - Use external system
- Customer-facing real-time tracking (Uber-style) - Phase 3
- Drone delivery optimization - Not planned
- International routing - Phase 3

---

## Estimation

**Total Effort**: 20-30 days
- Backend: 12 days
- Mobile App: 10 days
- Frontend (dashboard): 5 days
- Testing: 5 days
- DevOps: 2 days

**Team Capacity**: 2 backend developers + 1 mobile developer + 1 QA
**Target Completion**: End of Sprint 22

---

## Success Criteria

- [ ] Generate optimized route for 20 stops in <5 seconds
- [ ] Route at least 20% shorter than manual planning
- [ ] Mobile app works offline with cached routes
- [ ] 95% on-time delivery rate
- [ ] Driver can complete route without calling dispatcher
- [ ] Real-time ETA accuracy within 15 minutes
- [ ] 90% test coverage
- [ ] Successfully tested with 50+ stops, 5 drivers

---

## Related Epics

- **MOBILE**: Mobile app framework (dependency)
- **EMAIL**: Delivery notifications (integration)
- **CAL**: Sync routes to driver calendars (integration)
- **POD**: Proof of delivery with photos (integration)
- **MAINT**: Maintenance schedules affect vehicle availability

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Epic created |
