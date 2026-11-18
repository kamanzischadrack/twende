# Twende Vehicle Rental Management SRS v1.0

## 1. Overview

Twende is a vehicle rental and fleet operations platform for branch-based rental businesses operating across Rwanda and similar multi-branch environments. The product supports vehicle rental operations, fleet oversight, customer and driver management, damage and maintenance workflows, return reconciliation, finance, approvals, and reporting.

This frontend package is the Flutter client for the Twende operational stack. It is built around local-first data handling, offline-friendly workflows, role-based authorisation, and deterministic pricing and reconciliation rules.

## 2. Product goals

- Run rental operations across multiple branches and tenants.
- Standardise pricing, deposits, approval flows, and financial controls.
- Ensure vehicle availability checks include branch, document, maintenance, and schedule constraints.
- Support handover, return, inspection, and damage reconciliation workflows.
- Keep a complete audit trail for all financial and operational changes.
- Provide fast dashboards and reports for operations and management.

## 3. Core principles

- Local-first storage with persisted JSON document DB and in-memory fallback for tests/web.
- All reads flow through Riverpod providers derived from the store.
- All writes go through validated store commands that audit and queue sync operations.
- RBAC is enforced in both UI and route guards.
- Money is stored and computed in RWF, formatted only at the edge.
- Rental day logic is a 24-hour rolling window.
- IDs use domain prefixes such as `veh_`, `cst_`, `bk_`, `cnt_`, `inv_`, `trp_`, and `wo_`.
- Financial documents are never deleted; reversals use credit/debit notes.
- Signed contracts are immutable and amended only through amendment workflows.

## 4. Architecture contract

### 4.1 Frontend stack

- Flutter 3.35 / Dart 3.9
- Riverpod 2 (Notifier/Provider)
- go_router 14
- intl
- path_provider
- image_picker
- signature
- connectivity_plus
- flutter_secure_storage

### 4.2 Domain model

The app is organised around the following functional areas:

- Fleet management
- Customers and drivers
- Rates and pricing
- Availability and reservations
- Contracts and signatures
- Handover and return inspections
- Damage and incidents
- Maintenance work orders
- Trips and PODs
- Billing and refunds
- Approvals and audit
- Dashboard, reports, alerts, and settings

### 4.3 Domain engines

Pure-Dart domain engines are expected in `lib/shared/domain/` and must remain Flutter-free:

- `pricing_engine`
- `availability_checker`
- `reconciliation`
- `validation_rules`
- `profitability`
- `insights`

## 5. Business rules and controls

### 5.1 Availability and lifecycle

- Vehicles are unavailable when marked out of service, accident, sold, or archived.
- Availability must respect branch assignment, document validity, maintenance status, and schedule overlap.
- Safety and operational risk checks must block incompatible rentals.

### 5.2 Pricing and discounts

- Pricing is calculated against the valid rate plan for the trip period.
- Monthly, weekly, and daily caps are enforced.
- Discounts and refunds require approval above configured thresholds.
- Tax and deposit values are tenant-configurable and never hard-coded in business logic.

### 5.3 Return reconciliation

- Late return fees, excess mileage, fuel shortage, damage, and cleaning charges are aggregated into a single reconciliation statement.
- Deposit accounting supports refunds, credit notes, and balance due flows.
- High-value refunds require approval by policy.

### 5.4 Audit, sync, and permissions

- Every mutation writes an audit entry and queue for sync.
- RBAC denies by default; permissions are branch-scoped.
- Offline states must be handled on all screens.

## 6. Functional module map

### Fleet and documents

- Vehicle catalog and states
- Insurance, inspection, and road tax document tracking
- Maintenance scheduling and work orders
- Depreciation and book value tracking

### Rates and pricing

- Rate plans by category and vehicle
- Hour/day/week/month/trip/km/tonne-km units
- Extras catalogue
- Discount rules and validity windows
- Currency and FX snapshot support

### Customers and drivers

- Customer profiles and risk scoring
- Driver eligibility, licence checks, and driver hours
- Duplicate detection and merge history

### Availability and bookings

- Calendar-based booking availability
- Hold expiry and release flows
- Quote persistence and approval checks
- Booking status transitions and cancellation/no-show provisions

### Contracts and field operations

- Contract generation from booking
- Multi-language templates
- E-signature and amendment workflows
- Handover checklist and evidence capture

### Returns and billing

- Inspection comparison and final reconciliation
- Invoice generation and deposit ledger
- Credit/debit notes
- Aging and payment status tracking

### Operations and insights

- Alerts, notifications, and approval centre
- Dashboard KPIs and PDF/CSV reporting
- AI advisory features with grounded and explainable reasoning
- Tenant, branch, policy, and role configuration

## 7. Task board summary

| ID | Focus | Output |
| --- | --- | --- |
| T0 | Repair build and repo hygiene | Clean analysis/test baseline |
| T1 | Core store, models, RBAC, audit, sync, UI kit | Platform foundation |
| T2 | Fleet + documents + insurance | FLT01–10 |
| T3 | Rates + pricing service | RAT01–08 |
| T4 | Customers + drivers | CUS, DRV |
| T5 | Availability + conflict engine | CAL01–06 |
| T6 | Bookings + hold expiry + quotes | RES01–09 |
| T7 | Contracts + signature + amendment + PDF | CON01–06 |
| T8 | Handover + offline field checks | HND01–08 |
| T9 | Return + reconciliation + invoice | RET, FUE |
| T10 | Damage + incidents + fines | DMG01–05 |
| T11 | Billing + payments + deposits + aging | BIL01–10 |
| T12 | Maintenance work orders + schedules | MNT01–05 |
| T13 | Trips + POD + costs + margin | TRP01–05 |
| T14 | Extensions + swaps + early return | EXT01–04 |
| T15 | Approvals + audit viewer | §9.1, §10.2 |
| T16 | Alerts + notification centre | §14.3 |
| T17 | Dashboard + reports + CSV/PDF | §14.1–14.2 |
| T18 | AI insights | §7 |
| T19 | Tenant settings and admin config | ADM01–04 |
| T20 | i18n and accessibility | NFR10/11/12 |
| T21 | Performance, security, offline hardening | NFR01–14 |
| T22 | End-to-end lifecycle validation | §16 |

## 8. Definition of done

- `flutter analyze` shows zero errors and zero warnings.
- `flutter test` is green for the project.
- All new engines have unit tests.
- No hard-coded rates, taxes, thresholds, or deposits.
- Every mutation writes audit and sync data.
- Permission and branch scoping are enforced in UI and route guards.
- Loading, empty, error, and offline states exist for every screen.
- EN/FR/RW strings are added for user-visible text.
- No comments, `print`, or TODOs remain.
- `docs/agent-progress.md` is updated during execution.

## 9. Implementation expectation

The implementation must stay aligned with the repo’s actual app structure while following the Twende product requirements. The long-term objective is a robust fleet-rental management frontend that behaves like a production-ready operational system, not a prototype.

## 10. Screen-mapped implementation backlog

The prioritized remaining work, acceptance criteria, current implementation status, and mockup fallback expectations are tracked in [remaining-twende-backlog.md](./remaining-twende-backlog.md). Treat that backlog as the delivery breakdown for T1–T22; this SRS remains the product and architecture source of truth.

## 11. Change log

- v1.0: Initial Twende product specification and execution plan.
