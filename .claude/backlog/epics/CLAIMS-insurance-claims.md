# Epic: Insurance Claims Management

**Epic ID**: CLAIMS
**Status**: Backlog
**Priority**: LOW
**Business Value**: MEDIUM
**Target Release**: Phase 3 - Q4 2026

---

## Overview

Track and manage insurance claims for damaged or lost equipment. Integrates with proof of delivery and maintains claim documentation.

## Business Problem

- Manual claim tracking in spreadsheets
- Lost documentation when filing claims
- No visibility into claim status
- Average claim takes 30-60 days to resolve

## Success Metrics

- **Primary**: 50% faster claim resolution (15-30 days)
- **Secondary**: 100% claim documentation retention, 90% claim approval rate

## User Stories (Total: 48 pts)

### Must Have (P0)
- [ ] CLAIMS-101: Create insurance claim record (5 pts)
- [ ] CLAIMS-102: Link claim to booking and POD (5 pts)
- [ ] CLAIMS-103: Upload claim documentation (photos, reports) (5 pts)
- [ ] CLAIMS-104: Track claim status (submitted, under review, approved, denied) (5 pts)

### Should Have (P1)
- [ ] CLAIMS-105: Calculate claim amount based on damage (8 pts)
- [ ] CLAIMS-106: Integration with insurance provider APIs (13 pts)
- [ ] CLAIMS-107: Claim reporting and analytics (5 pts)

---

## Technical Architecture

```ruby
class InsuranceClaim < ApplicationRecord
  belongs_to :booking
  belongs_to :proof_of_delivery
  belongs_to :filed_by, class_name: 'User'

  has_many_attached :documentation

  enum status: [:draft, :submitted, :under_review, :approved, :denied, :closed]
  enum claim_type: [:damage, :loss, :theft, :liability]

  validates :claim_amount_cents, :incident_date, presence: true
end
```

---

## Estimation

**Total Effort**: 8-12 days
**Target**: Sprint 29-30
