# Twende Remaining Features Backlog

This backlog maps the visible operational surfaces in the shared mockup to the Twende SRS and the current Flutter implementation. It is an implementation backlog, not a claim that every mockup panel is already a working feature.

## Status key

- **Partial**: a screen, model, or domain rule exists, but the complete workflow is not wired or persisted.
- **Missing**: the feature is not implemented to its acceptance criteria.
- **Foundation partial**: infrastructure exists, but it is not yet used consistently by application repositories and screens.

## Prioritized backlog

### P0 — trustworthy data and operation foundations

| Screen / surface | Priority | Feature | Acceptance criteria | SRS mapping | Status |
|---|---|---|---|---|---|
| All API-backed screens | P0 | Real-data-first API and demo fallback | When the API returns records, render those records. When it errors, times out, returns null, or has no usable records, render the applicable demo dataset and visibly mark it as demo/fallback data. Keep API errors available for diagnostics; never silently present fallback records as live data. Do not send demo records to a production sync queue. Add tests for success, empty response, and failure. | §3, §4, §5.4, §8; NFR offline requirements | Partial — fallback exists in some legacy services; not consistent across the Twende repositories. |
| All data screens | P0 | Store-backed repositories and Riverpod reads | Fleet, customer, contract, billing, and dashboard reads are derived from the local document store through providers. The persisted format has an explicit schema version and migration strategy. Writes persist across app restarts on supported platforms. Tests can inject an in-memory store. | §3, §4, §8 | Foundation partial — fleet, customer, contract, and billing repositories now persist through the store and retain demo fallback; maintenance, dashboard, and approvals still use mock repositories. |
| All write flows | P0 | Validated write, audit, and sync pipeline | Every successful domain write validates its input, updates the document, appends an audit record, queues a sync operation, persists the result, and notifies provider listeners. A failed persistence step is surfaced and does not report success. | §3, §5.4, §8 | Foundation partial — fleet/customer, inspection, and payment writes use audited store commands; demo-origin changes are excluded from production sync. Other feature writes still bypass the store, and sync replay is absent. |
| All screens / sync status | P0 | Offline and loading/error/empty states | Each screen distinguishes loading, valid empty results, errors, and offline state. The sync UI reflects actual connectivity and pending/failed queue counts; it does not claim data is synced when no sync occurred. | §5.4, §8; NFR08 | Missing / partial — status UI exists, but is not connected to connectivity or queue processing. |
| Settings / tenant administration | P0 | Tenant settings as the business-policy source | Authorized admins can edit tenant policy; persisted values load at startup and are consumed by pricing, availability, reconciliation, and approval logic. Invalid policy values are rejected with an actionable message. | §5.2, §6, §8; T19 | Partial — tenant config and persistence path exist; full editor, validation, and broad consumption remain. |

### P1 — fleet, availability, and booking revenue spine

| Screen / surface | Priority | Feature | Acceptance criteria | SRS mapping | Status |
|---|---|---|---|---|---|
| Fleet list / vehicle detail | P1 | Complete vehicle lifecycle | Authorized staff can create and edit vehicles with validated identity, category, branch, capacity, and operational fields. Status changes follow allowed transitions, require a reason where applicable, and are audited. Archived/sold vehicles cannot be booked. | §5.1, §6 Fleet; T2 | Partial — list/detail and status concepts exist; create/edit and transition enforcement are incomplete. |
| Vehicle detail / documents | P1 | Vehicle documents and expiry tracking | Staff can add document type, identifier, issue/expiry dates, and evidence. Expired or missing required documents block availability and show the reason. Expiry is evaluated against the requested rental window. | §5.1, §6 Fleet; T2, T5 | Partial — document model/check exists; UI and real persisted vehicle documents are incomplete. |
| Fleet / maintenance | P1 | Maintenance scheduling and work orders | Staff can create, schedule, update, and close work orders. Vehicles with blocking maintenance are unavailable for overlapping dates; completed work updates vehicle history and is audited. | §5, §6 Fleet; T12 | Partial — maintenance screen/model exist; durable lifecycle and availability integration remain. |
| Fleet / branch operations | P1 | Branch transfer workflow | A transfer records source/destination branch, effective time, reason, and responsible actor. Vehicle branch and availability update only after a valid transfer; history is retained. | §5.1, §6 Fleet; T2 | Missing. |
| Availability board | P1 | Date-based vehicle availability board | Staff can select a date range and view vehicle availability by day/week/month. Availability uses real bookings, work orders, vehicle status, branch, turnaround policy, and required-document validity. Conflicts show actionable reasons. | §5.1, §6 Availability; T5 | Partial — deterministic checker and screen exist; board and real data inputs are incomplete. |
| Availability board | P1 | Search, filters, and capacity summary | Filters include branch, category, status, and rental period; supported capacity fields can filter applicable vehicle classes. Results and per-category available capacity agree with the same availability evaluation. | §6 Availability; T5 | Partial — basic search/status filtering exists; broader filters and capacity calculation are missing. |
| Availability board → booking | P1 | Conflict-safe booking handoff | Selecting an available vehicle and date range opens booking creation with those values prefilled. The booking command rechecks availability before confirming; conflicting requests are rejected and explain why. | §5.1, §6 Availability and bookings; T5, T6 | Partial — booking form and availability engine exist but are not fully connected. |
| Booking creation / quote | P1 | Persisted quote and booking lifecycle | Quote inputs and breakdown are saved with the booking. Valid transitions are enforced from inquiry/pending through confirmed, cancelled/no-show, rental conversion, and completion. Booking confirmation reserves the vehicle atomically with the availability check. | §5.2, §6 Availability and bookings; T6 | Partial — quote UI/pricing logic exist; confirm is not yet a complete persisted lifecycle. |
| Booking creation / quote | P1 | Tenant-configured pricing, extras, and approvals | Quote calculations use active tenant policy and rate plans; extras and discounts appear in a reproducible breakdown. Discounts above the configured limit require approval before confirmation. | §5.2, §6 Rates and pricing; T3, T6 | Partial — pricing engine and tenant config exist; rate-plan persistence and approval wiring remain. |
| Customers / booking eligibility | P1 | Customer and driver eligibility | Customer and driver records include required identity/contact/licence details and expiry. Booking validation blocks ineligible or blacklisted drivers and flags watch-listed customers for approval. | §6 Customers and drivers; T4, T6 | Partial — basic customer records exist; complete profiles and enforcement are missing. |

### P2 — rental execution, returns, and finance

| Screen / surface | Priority | Feature | Acceptance criteria | SRS mapping | Status |
|---|---|---|---|---|---|
| Customer list / detail | P2 | Customer profile, duplicate checks, and history | Staff can search and maintain customer profiles, detect likely duplicates before creation, and review linked bookings, contracts, balances, and risk history. Sensitive identifiers are masked in list views. | §6 Customers and drivers; T4 | Partial — list/detail and basic fields exist; duplicate/merge and complete history are missing. |
| Contract detail | P2 | Contract generation, signing, and amendments | A confirmed booking can produce a contract containing the agreed parties, vehicle, dates, rate, deposit, and terms. Signed contracts cannot be edited in place; amendments create a linked, auditable version. | §6 Contracts and field operations; T7 | Partial — contract screen/model exist; complete generation/signing/amendment behavior remains. |
| Handover | P2 | Evidence-backed handover inspection | Staff record odometer, fuel, configured checklist, condition/damage, photos, timestamp, and customer/staff signature. Required evidence is validated before handover completion and stored offline safely. | §5.4, §6 Contracts and field operations; T8 | Partial — inspection UI elements exist; complete persistent workflow and offline evidence handling remain. |
| Return / inspection | P2 | Return inspection and comparison | Return records capture odometer, fuel, checklist, damages, photos, and signature, then compare against handover evidence and identify new damage. Completion updates the contract and vehicle lifecycle through audited commands. | §5.3, §6 Returns and billing; T9 | Partial — return/reconciliation UI exists; full evidence comparison and lifecycle integration remain. |
| Return / reconciliation | P2 | Policy-driven reconciliation | Late time, grace period, excess mileage, fuel, damage, and other configured charges are calculated by a tested domain engine. The statement shows each input and amount; deposit/refund/balance totals reconcile exactly. | §5.3, §6 Returns and billing; T9 | Partial — reconciliation engine/UI exist; complete configured inputs and persisted statement flow remain. |
| Billing / payments | P2 | Invoices, payments, deposits, and reversals | Invoices and payment events are persisted and linked to contracts. Balances and aging are derived from ledger entries. Financial records cannot be deleted; corrections use linked credit/debit notes or reversals. | §5.3, §6 Returns and billing; T11 | Partial — billing surface and models exist; ledger-backed workflows are incomplete. |
| Approvals | P2 | Approval queue and decisions | Configured discount, refund, and exception thresholds create approval requests. Only permitted roles can approve/reject; decisions include actor, time, reason, and audit history. | §5.2, §5.4, §6 Approvals; T15 | Partial — approval UI/model exists; real request creation and authorization remain. |
| Notifications / alerts | P2 | Operational alerts | Alerts are created from defined events such as document expiry, overdue return, maintenance due, and pending approvals. Each alert has a source, priority, status, and actionable destination; duplicate alerts are controlled. | §6 Operations and insights; T16 | Partial — notification surface exists; alert triggers are missing. |

### P3 — management insights and release readiness

| Screen / surface | Priority | Feature | Acceptance criteria | SRS mapping | Status |
|---|---|---|---|---|---|
| Dashboard | P3 | Branch-scoped operational KPIs | KPIs are calculated from persisted operational records for the selected period and authorized branch scope. Empty datasets show an empty state, not fabricated production totals. | §6 Operations and insights; T17 | Partial — dashboard surface exists; current data is not a complete store-backed operational view. |
| Reports / AI insights | P3 | Reports and export | Users can filter defined revenue, utilization, maintenance, and receivables reports by period/branch. Exported totals match displayed totals and respect permissions. | §6 Operations and insights; T17 | Partial — report screen exists; validated report datasets and export workflows remain. |
| Reports / AI insights | P3 | Grounded AI advisory | Recommendations cite the operational records and time window supporting them, distinguish observations from recommendations, and are unavailable or clearly marked when there is insufficient data. | §6 Operations and insights; §7; T18 | Missing / prototype-only. |
| All screens | P3 | RBAC, branch scoping, localization, and accessibility | Unauthorized users cannot view or mutate restricted data through either UI or route entry. Queries enforce branch scope. User-facing flows support EN/FR/RW and pass defined accessibility checks. | §4, §6, §8; T20 | Partial — route/permission foundation exists; comprehensive query scope and localization/accessibility coverage remain. |
| End-to-end lifecycle | P3 | Release and regression validation | Automated tests cover the critical lifecycle from availability search through booking, contract, handover, return, reconciliation, invoice, and audit/sync records. API and demo-fallback paths are tested separately. | §8; T21, T22 | Missing. |

## Mockup data fallback behavior

Keep the mockup's layout stable while replacing its data source as real data becomes available:

1. Prefer a successful API response containing usable records.
2. On API error, timeout, null/invalid payload, or an empty result where demo fallback is configured, show the matching mock dataset and label it as demo/fallback data.
3. For screens configured for demo fallback, an empty API result also falls back to the matching mock dataset. A screen may show a true empty state only when that behavior is explicitly required for the workflow.
4. Never silently mix mock and API records. Never represent demo data as a real customer, booking, payment, or operational event.
5. Keep fallback reads separate from production writes and sync. A user must not accidentally submit or synchronize demo records as real business data.
6. Preserve error/connection state so the UI can explain that fallback data is being shown and offer retry when appropriate.

## Suggested delivery sequence

1. Complete P0 repository/provider integration, error-safe write pipeline, tenant-policy validation, and transparent fallback behavior.
2. Deliver P1 as the revenue spine: vehicle data and documents → real availability → conflict-safe booking and quote.
3. Deliver P2 rental execution and finance: customer eligibility → contract → handover → return/reconciliation → invoice/payment → approvals.
4. Deliver P3 management, reports, AI, localization/accessibility, and end-to-end hardening.

Priorities are sequencing guidance. Every feature remains subject to the authorization, branch-scoping, audit, sync, offline, and test requirements in the SRS and `AGENTS.md`.
