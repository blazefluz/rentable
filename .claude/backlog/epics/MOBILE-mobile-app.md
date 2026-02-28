# Epic: Mobile Application (iOS & Android)

**Epic ID**: MOBILE
**Status**: Backlog
**Priority**: HIGH
**Business Value**: HIGH
**Target Release**: Phase 2 - Q3 2026

---

## Overview

Native mobile apps for field staff (drivers, technicians) and customers. Enables on-the-go booking management, delivery tracking, and equipment management.

## Business Problem

- Field staff tied to office computers for updates
- Customers want mobile-first booking experience
- Paper-based field processes inefficient
- Missed opportunities for mobile bookings (40% of web traffic is mobile)

## Success Metrics

- **Primary**: 50% of bookings come from mobile app
- **Secondary**: 4.5+ star rating in app stores, 80% staff adoption

## User Stories (Total: 89 pts)

### Must Have (P0) - Driver App
- [ ] MOBILE-101: View daily delivery route (8 pts)
- [ ] MOBILE-102: Mark deliveries complete (5 pts)
- [ ] MOBILE-103: Capture POD photos and signatures (8 pts)
- [ ] MOBILE-104: Offline mode support (13 pts)

### Must Have (P0) - Customer App
- [ ] MOBILE-201: Browse and search products (8 pts)
- [ ] MOBILE-202: Create booking (8 pts)
- [ ] MOBILE-203: Track delivery status (5 pts)
- [ ] MOBILE-204: View booking history (5 pts)

### Should Have (P1)
- [ ] MOBILE-105: Push notifications (5 pts)
- [ ] MOBILE-106: In-app messaging (8 pts)
- [ ] MOBILE-107: Payment via mobile wallet (Apple Pay, Google Pay) (8 pts)

---

## Technical Stack

- **Framework**: React Native (iOS + Android from one codebase)
- **State Management**: Redux Toolkit
- **Offline Storage**: WatermelonDB
- **Backend**: Existing Rails API

---

## Estimation

**Total Effort**: 30-40 days
**Target**: Sprint 20-24
