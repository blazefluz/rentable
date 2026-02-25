# Rental MVP Project Guide – Booqable-style Equipment Rental SaaS

**Project Name (working):** Rentable 
**Goal:** Build a functional single-tenant MVP rental/booking system in **one week** (or as close as possible), similar to Booqable but simpler. Target use case: renting equipment (cameras, tools, AV gear, lights, etc.) in worldwide context.  
**Owner:** Rentable
**Timeline:** Aggressive 7-day sprint starting ~Feb 2025/2026  
**License:** 100% original code – proprietary for now (no AGPL/copyleft issues)  
**Inspiration source (conceptual only):** AdamRMS open-source project (https://github.com/adam-rms/adam-rms, https://adam-rms.com) – theatre/AV/broadcast rental system.  which is in backup folder

→ **NO code copying**. Use it only for domain ideas: asset tracking with clash prevention, kits/bundles, project/event grouping, calendar views, detailed asset info (barcodes, maintenance), invoicing/ledger basics, multi-site if relevant later.

## Core Philosophy & Constraints
- Ship fast → focus on **core loop**: Admin adds items/kits → public/customer sees availability → books dates → pays (test) → confirmation.
- Single-tenant MVP (one "shop"/business) – multi-tenant later if needed.
- Nigeria-first: Support NGN (Naira), Paystack payments primary, Stripe test fallback.
- Mobile-first UI (many users on phones in Lagos).
- Developer joy + maintainability: idiomatic **API-only Rails** backend + **React** frontend, clean separation of concerns.

## Fixed Tech Stack (2026 best practices)

### Backend (Rails API)
- Ruby 3.3+ / Rails 8 (latest stable) — `--api` mode (no views, no Hotwire, no Sprockets)
- PostgreSQL (local + Railway/Render)
- Authentication: JWT tokens (via `devise` + `devise-jwt`, or `rodauth`) — stateless, cookie-free
- Serialization: `jsonapi-serializer` or plain `render json:`
- Database: Active Record + migrations
- Money/Prices: `money-rails` + `monetize` gem (support :ngn, :usd)
- Images: Active Storage (local disk or Supabase/S3) — serve signed URLs to frontend
- Background: Solid Queue or `good_job` (simple)
- Payments: `stripe` gem (primary, test mode) + Paystack via HTTP (no official gem needed)
- CORS: `rack-cors` gem — allow React dev origin + production domain
- Testing: RSpec + FactoryBot (focus on availability logic + API responses)
- Deployment: Railway.app, Render, or Fly.io

### Frontend (React)
- React 18+ with Vite (TypeScript)
- Styling: Tailwind CSS + shadcn/ui (or daisyUI)
- State / data fetching: TanStack Query (react-query) for server state
- Routing: React Router v6
- Forms: React Hook Form + Zod validation
- Calendar: FullCalendar React component
- Auth: JWT stored in `httpOnly` cookie (preferred) or `localStorage`
- HTTP client: `axios` or native `fetch` with a shared API client wrapper
- Deployment: Vercel, Netlify, or same Railway/Render service as static files

## Core Domain Entities ( from AdamRMS/Booqable concepts)
1. **Product / Asset**
   - name:string
   - description:text
   - daily_price:integer (monetized → Money)
   - quantity:integer (default 1 – how many identical units)
   - serial_numbers:text/array (for unique tracking, optional)
   - category:string or belongs_to :Category
   - images (Active Storage)
   - barcode:string (optional)

2. **Kit / Bundle**
   - name, description, daily_price
   - has_many :kit_items → join table with product_id + qty_required

3. **Booking / Hire**
   - start_date:datetime
   - end_date:datetime
   - customer_name, customer_email, customer_phone
   - status:enum (draft, pending, confirmed, paid, cancelled, completed)
   - total_price: Money
   - notes:text
   - has_many :booking_items (polymorphic or separate for products/kits) with qty

4. **Customer** (minimal – or derive from booking)
   - name, email, phone (unique on email?)

5. **Category/Group** (optional but useful)
   - name, for filtering/notifications later

## Key Business Rules (inspired by AdamRMS clash prevention & rental logic)
- **Availability calculation** (critical):
  - For a Product: free_qty(date_range) = quantity - sum(qty from overlapping confirmed/paid bookings)
  - Overlap: bookings where start < proposed_end AND end > proposed_start
  - Allow same-day turnaround: if one ends at 18:00 and next starts 18:00 → no overlap (use date comparison carefully, perhaps normalize to dates or half-days)
  - For Kit: available only if **all** component Products have enough free_qty for required qty
  - Statuses that count toward overlap: confirmed + paid (maybe pending if strict)
- **Pricing (simple MVP)**: daily_price × number_of_days (inclusive: (end - start).to_i + 1)
  - Later: weekly rates, deposits, discounts
- **Booking creation**: optimistic check → pessimistic lock/re-check on save to prevent races

## 7-Day Aggressive Plan
**Day 0:** `rails new rentable --api --database=postgresql`, add gems (rack-cors, devise-jwt, money-rails, rspec-rails), scaffold React app (Vite + TS + Tailwind), wire up CORS  
**Day 1:** Models + migrations + associations + monetize; seed data; JSON serializers  
**Day 2:** AvailabilityService + scopes; API endpoints for Products/Kits with availability  
**Day 3:** Auth endpoints (register/login/logout JWT); admin-scoped routes + Products/Kits CRUD API  
**Day 4:** React: product list + show pages + date-range picker + availability check (react-query)  
**Day 5:** React booking flow + Rails booking creation endpoint + Paystack/Stripe webhook  
**Day 6:** React calendar view (FullCalendar) + admin dashboard + mobile polish  
**Day 7:** RSpec tests (availability logic + API specs), deploy both apps, demo video

## Claude Prompt Template (use this structure every time)
You are a senior Rails 8 API + React expert building this rental MVP (see attached project guide).

Current task: [describe precisely, e.g. "Build the AvailabilityService and expose it via a JSON API endpoint"]

Rules from project guide:
- Backend: Rails 8 API-only, JWT auth, rack-cors, money-rails, Paystack primary
- Frontend: React 18 + TypeScript + Vite, TanStack Query, React Hook Form, Tailwind + shadcn/ui
- Entities & rules: [paste relevant section above or summarize]
- Inspiration: AdamRMS concepts only (clash prevention, kits, calendar, asset details)
- No ERB views, no Hotwire, no Turbo — Rails is JSON API only

Please output in sections:
1. Migrations / schema changes (if any)
2. Model code (associations, enums, monetize, validations)
3. Service / Concern / Query object for logic
4. Rails controller + actions (JSON responses only, strong params)
5. Routes (`namespace :api, defaults: { format: :json }` pattern)
6. Serializer (jsonapi-serializer or plain hash)
7. React component(s) / hook(s) that consume the endpoint
8. Test ideas — RSpec request specs for API + unit specs for logic
9. New gems or npm packages to add

Code must be clean, commented, idiomatic Rails 2026 + modern React/TypeScript.

Next suggested step: [suggest what to do after this]

Start now.

## Final Notes for Claude
- Always prioritize working core (availability + booking) over polish.
- Ask clarifying questions if something is ambiguous.
- Keep responses focused – one feature per major prompt.
- Output code in fenced blocks with language.
- If error-prone (e.g. date overlaps), suggest tests first.

Ready to build – start with Rails API-only setup + core models + availability checker!