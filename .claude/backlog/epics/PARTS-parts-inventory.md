# Epic: Parts Inventory Management

**Epic ID**: PARTS
**Status**: Backlog
**Priority**: MEDIUM
**Business Value**: MEDIUM
**Target Release**: Phase 2 - Q3 2026

---

## Overview

Track spare parts inventory for equipment maintenance and repairs. Ensures technicians have necessary parts on hand, reducing equipment downtime.

## Business Problem

- Equipment sits broken waiting for parts (avg 5-7 days downtime)
- No visibility into parts inventory levels
- Over-ordering or under-ordering parts
- Parts cost tracking difficult

## Success Metrics

- **Primary**: 50% reduction in equipment downtime due to parts availability
- **Secondary**: 20% reduction in parts carrying costs

## User Stories (Total: 58 pts)

### Must Have (P0)
- [ ] PARTS-101: Parts catalog management (8 pts)
- [ ] PARTS-102: Parts inventory tracking (8 pts)
- [ ] PARTS-103: Link parts to equipment models (5 pts)
- [ ] PARTS-104: Parts usage during maintenance (5 pts)
- [ ] PARTS-105: Low stock alerts (3 pts)

### Should Have (P1)
- [ ] PARTS-106: Parts ordering workflow (8 pts)
- [ ] PARTS-107: Vendor management for parts (5 pts)
- [ ] PARTS-108: Parts cost allocation to equipment (5 pts)

---

## Technical Architecture

```ruby
class Part < ApplicationRecord
  belongs_to :company
  has_many :inventory_transactions

  validates :part_number, :name, presence: true
end

class InventoryTransaction < ApplicationRecord
  belongs_to :part
  belongs_to :maintenance_log, optional: true
  enum transaction_type: [:purchase, :usage, :return, :adjustment]
end
```

---

## Estimation

**Total Effort**: 10-12 days
**Target**: Sprint 21-22
