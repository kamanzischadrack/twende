<USER_REQUEST>
which is remain for each user port"# Twende — Wireframes and Screen Specification (for Flutter implementation)

Source: Twende SRS v1.0 (Sections 3, 4, 6, 8, 9, 10, 13, 14). Requirement IDs such as `RES-04` or `BR-06` refer to that SRS.

## 0. How to use this document (read first, AI agent)

1. **Do not rewrite the existing app.** Inspect the current Flutter project first. For each screen below, mark it `exists / partial / missing`, then extend or create it in the project's existing structure and state management. Only use the suggestions in Section 2 if the project has no convention yet.
2. **Build order** is in Section 9. Build shared components (Section 3) before screens.
3. Each screen has: **Purpose**, **Roles**, **Wireframe**, **Data**, **Actions**, **States** (loading / empty / error / offline) and **Rules** (SRS IDs). Implement all states, not just the happy path.
4. Wireframes are layout intent, not pixel design. Use the design tokens in Section 1.4.
5. **Never trust the client for rules** (double booking, pricing, permissions). The client validates for UX and the backend enforces. The client must handle conflict and validation errors from the server gracefully.
6. Money values are integers in the smallest currency unit (RWF has no decimals). Never use `double` for money.

Legend used in wireframes: `[ Button ]` button, `( ) / (•)` radio, `[ ] / [x]` checkbox, `[____]` text input, `▼` dropdown, `●` status dot, `▸` navigates, `⚠` warning, `📷` camera, `✍` signature.

---

## 1. App shell, navigation and access

### 1.1 One codebase, three experiences

| Experience | Who | Form factor | Entry |
|---|---|---|---|
| **Staff app** | Admin, Owner, Rental Manager, Rental Officer, Fleet Manager, Finance | Phone, tablet, desktop/web (responsive) | Login → role-based home |
| **Driver app mode** | Driver / Chauffeur | Phone only | Login → Driver home (restricted shell) |
| **Customer portal** | Customer | Phone/web | Public portal + secure links (separate entry point, e.g. `/portal`) |

Decide at login from the user's role. Drivers and customers never see the staff navigation.

### 1.2 Responsive layout rules

| Width | Navigation | Lists | Detail |
|---|---|---|---|
| < 600 (phone) | Bottom bar (max 5 items) + "More" | Cards | Full-screen push |
| 600–1024 (tablet) | Navigation rail | Cards or compact table | Split view |
| > 1024 (desktop) | Left sidebar, grouped | Data table with filters | Split view or side panel |

Use `LayoutBuilder` / a shared `ResponsiveScaffold`. Handover, return, driver and portal screens are **phone-first** (large touch targets min 48dp, camera first).

### 1.3 Navigation groups (sidebar / "More" menu)

```
OPERATE            MANAGE               MONEY & INSIGHT
Dashboard          Fleet                Invoices
Availability       Customers            Payments
Bookings           Drivers              Deposits
Active rentals     Maintenance          Reports
Returns due        Damage & incidents   Ask your fleet
Trips              Rates                Settings
```
Items the role cannot `View` are hidden (not greyed out).

### 1.4 Design tokens (from the SRS cover; adjust to your existing theme)

- Navy `#0E1B2E` (background/primary dark), Amber `#F5A623` (accent), white text on navy.
- **Vehicle status colours** (use everywhere, with icon + label, never colour alone): Available = green, Reserved = blue, Rented = amber, Returned/Under Inspection = purple, Under Maintenance = orange, Accident = red, Out of Service = grey, Sold/Archived = dark grey.
- Fonts: one sans-serif family. Numbers right-aligned, currency as `RWF 450,000`.
- Dark and light theme both supported. WCAG 2.1 AA contrast (NFR-11).

### 1.5 Role → module access (defaults, from SRS 10.1)

`V` view, `C` create, `E` edit, `A` approve, `D` archive, `X` export, `—` none. Every cell must be driven by a permission set from the backend, not hard-coded.

| Module | Admin | Mgmt | Rental Mgr | Rental Off. | Fleet Mgr | Finance | Driver |
|---|---|---|---|---|---|---|---|
| Fleet & documents | VCEADX | VX | V | V | VCEDX | V | V* |
| Availability board | VCEADX | V | VCE | VC | VCE | V | — |
| Customers | VCEADX | VX | VCEAX | VCE | — | VX | — |
| Bookings | VCEADX | VX | VCEADX | VCE | V | V | — |
| Contracts | VCEADX | VX | VCEAX | VC | V | VX | — |
| Handover & return | VCEADX | V | VCEA | VCE | V | V | VC* |
| Billing & payments | VCEADX | VX | VC | VC | — | VCEAX | — |
| Refunds & discounts | VCEADX | VA | VCA | C | — | VCA | — |
| Maintenance | VCEADX | VX | V | V | VCEAX | V | C* |
| Drivers & trips | VCEADX | VX | VCE | V | VCEA | V | VE* |
| Damage & incidents | VCEADX | VX | VCEA | VC | VCEA | VCA | C* |
| Reports & dashboard | VX | VX | VX | V | VX | VX | — |
| Settings & users | VCEADX | V | — | — | — | — | — |

`*` Driver sees and acts only on **their own assigned jobs**. All users are also **scoped to their assigned branches**.

### 1.6 Route map (suggested, for `go_router`)

```
/login  /login/2fa
/                      → role home (redirect)
/dashboard
/availability
/bookings  /bookings/new  /bookings/:id
/rentals   /rentals/:id  /rentals/:id/handover  /rentals/:id/return
/rentals/:id/extend  /rentals/:id/swap
/returns-due
/trips  /trips/:id
/fleet  /fleet/new  /fleet/:id  /fleet/:id/documents
/customers  /customers/new  /customers/:id
/drivers  /drivers/:id
/maintenance  /maintenance/:id
/damage  /damage/:id   /incidents/:id
/rates
/invoices  /invoices/:id
/payments  /deposits  /finance/aging
/reports  /reports/:slug
/ask
/approvals  /approvals/:id
/notifications
/settings  /settings/users  /settings/roles  /settings/policies
/settings/branches  /settings/templates  /settings/audit
/driver  /driver/jobs/:id  /driver/jobs/:id/checklist  /driver/jobs/:id/expense
/driver/jobs/:id/incident  /driver/jobs/:id/pod
/portal  /portal/search  /portal/book  /portal/sign/:token  /portal/pay/:token
/portal/documents  /portal/privacy
```
Add a route guard: redirect if not logged in, if role lacks `View` on the module, or if the record is outside the user's branches.

---

## 2. Suggested Flutter structure (only if the project has none)

```
lib/
  core/        theme, router, api client, auth, permissions, offline queue, l10n, utils(money, dates)
  shared/      widgets (Section 3), models common to features
  features/
    auth/ dashboard/ availability/ bookings/ rentals/ handover/ returns/
    fleet/ customers/ drivers/ trips/ maintenance/ damage/ finance/
    reports/ ask_fleet/ approvals/ settings/ notifications/
    driver_app/ portal/
```
Each feature: `data/` (API + local DB), `domain/` (models), `presentation/` (screens, controllers).

Suggested packages: `go_router`, `flutter_riverpod`, `dio`, `freezed`/`json_serializable`, `drift` (local DB for offline), `connectivity_plus`, `workmanager` (background sync), `image_picker`/`camera`, `flutter_image_compress`, `signature`, `geolocator`, `google_mlkit_text_recognition` (on-device OCR) or a backend OCR call, `firebase_messaging`, `flutter_localizations` + `intl` (en, rw, fr), `fl_chart`, `data_table_2`, `pdfx`/`printing`, `url_launcher`.

---

## 3. Shared components (build these first)

| Component | Description | Used by |
|---|---|---|
| `StatusBadge(status)` | Coloured pill with icon + label for vehicle, booking, contract, invoice, damage statuses | Everywhere |
| `KpiCard(title, value, delta, onTap)` | Number card with trend | Dashboard |
| `ResponsiveScaffold` | Sidebar / rail / bottom bar by width and role | App shell |
| `FilterBar` | Search + chips + date range + branch picker; persists filters | All lists |
| `DataListView` | Table on desktop, cards on phone, pagination, pull-to-refresh, empty/error states | All lists |
| `QuoteSummary` | Rental, extras, discounts, tax, deposit, total breakdown; updates live | Booking, extension |
| `MoneyText` | Formats RWF, right aligned | Everywhere |
| `PhotoCaptureGrid(required: [...])` | Required-shot slots (front, rear, left, right, interior, odometer, fuel gauge), camera first, auto-compress, retake, offline save | Handover, return, trip |
| `DamageDiagram(vehicleType)` | Tap car/van/truck outline to add a mark (+ photos + note) | Handover, return, damage |
| `SignaturePad` | Draw signature, clear, confirm; stores image + timestamp + device | Contract, handover, POD |
| `ChecklistForm(template)` | Pass / fail / note items | Handover, return, pre-trip |
| `ApprovalCard` | Request summary, requester, amount, reason, Approve / Reject + comment | Approvals |
| `OfflineBanner` + `SyncQueueSheet` | Shows offline state, pending items, conflicts | Global |
| `PermissionGate(module, action)` | Hides or disables widgets by permission | Everywhere |
| `AuditChip` | "Edited by X at time" with link to audit entry | Detail screens |
| `ConfirmDialog` with reason | Required reason text for overrides and cancellations | Overrides |
| `LanguageSwitcher` | en / rw / fr | Settings, login |

---

## 4. Authentication and shared screens (all roles)

### A-01 Login and 2FA

```
┌──────────────────────────────┐
│        twende.               │
│   Let's go · Rental mgmt     │
│                              │
│ Phone or email               │
│ [__________________________] │
│ Password                     │
│ [__________________________]👁│
│ [        Sign in           ] │
│ Forgot password?             │
│ Language: English ▼          │
└──────────────────────────────┘
        ↓ (admin, finance, approvers)
┌──────────────────────────────┐
│ Enter 6-digit code           │
│ [_][_][_][_][_][_]           │
│ [ Verify ]   Resend in 30s   │
└──────────────────────────────┘
```
- **Data:** token, user, role, permissions, branches, tenant.
- **Rules:** 2FA mandatory for Admin, Finance, approvers. Session timeout. Lost-device forced logout. Biometric re-lock on mobile is optional.
- **States:** wrong credentials, locked account, offline (login needs network, cached session may open read-only for field roles).

### S-01 Notification centre

```
┌──────────────────────────────────────┐
│ Notifications        [Mark all read] │
│ Today                                │
│ ● Return due: RAC 123 B · 16:00  ▸   │
│ ● Approval waiting: Discount 15% ▸   │
│ Earlier                              │
│   Insurance expiring: RAD 456 C (7d)▸│
└──────────────────────────────────────┘
```
Alert types and recipients are in SRS 14.3. Each item deep-links to the record. Unread badge on the bell. Push via FCM.

### S-02 Approvals inbox (Owner, Rental Mgr, Finance, Fleet Mgr)

```
┌─────────────────────────────────────────┐
│ Approvals   [Pending 4] [Decided]       │
│ Type ▼  Branch ▼                        │
│ ┌─────────────────────────────────────┐ │
│ │ Discount 20%  · Contract RC-0231    │ │
│ │ By: Aline (Officer)  RWF 90,000     │ │
│ │ Reason: corporate repeat customer   │ │
│ │ [Reject]            [Approve]       │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```
- **Types:** discount, refund, damage charge, contract cancellation after handover, vehicle status override, work order above limit, credit rental, extension overriding a booking, large expense (SRS 9.1).
- **Action:** approve/reject with required comment. Records approver, time, decision, comment. Works on mobile.

### S-03 Global search
Search by plate, customer phone, contract/booking/invoice number. Results grouped by type.

---

## 5. Staff screens (by module)

### 5.1 Dashboard (Owner, Management, Managers) — `/dashboard`

**Purpose:** know the business health in 30 seconds (Section 14).

Phone (Owner):
```
┌──────────────────────────────┐
│ Good morning, Robert   🔔 3  │
│ Branch: All ▼  This month ▼  │
│ ┌────────┐┌────────┐         │
│ │Revenue ││Outstand││         │
│ │ 18.4M  ││ 2.1M ⚠ ││         │
│ └────────┘└────────┘         │
│ ┌────────┐┌────────┐         │
│ │Utiliz. ││Contrib.││         │
│ │  72%   ││ 9.8M   ││         │
│ └────────┘└────────┘         │
│ Fleet: ●12 Avail ●8 Rented   │
│        ●2 Maint  ●1 Accident │
│ ⚠ Needs attention            │
│  3 overdue · 2 approvals     │
│  4 docs expiring             │
│ Revenue trend  ▁▃▅▆▇         │
│ 💬 Ask your fleet…           │
└──────────────────────────────┘
```
Desktop: same KPIs in a row, today's pickups and returns tables, overdue list, alerts panel, revenue and utilization charts.
- **KPIs:** Fleet (total, available, reserved, rented, maintenance, out of service, trucks on trip); Business (revenue, outstanding, deposits held, refunds, rental days, utilization, average daily rate, revenue per vehicle, costs, contribution margin); Operations (active and overdue rentals, pickups and returns today, service due, expiring documents).
- **Actions:** tap any KPI to open the filtered list or report. Role changes what is shown (Rental Officer sees only operations KPIs, Finance sees money KPIs).
- **States:** skeleton loading, "no data yet" for new tenants, stale-data timestamp when offline.

### 5.2 Availability board (Manager, Officer, Fleet) — `/availability`

```
┌─────────────────────────────────────────────────────────────────┐
│ Availability  [Day|Week|Month] ◀ 10–16 Nov ▶  [Branch▼][Type▼]  │
│ Status▼ Seats▼ Capacity▼  Search plate…                         │
├──────────────┬────┬────┬────┬────┬────┬────┬────┤
│ Vehicle      │Mon │Tue │Wed │Thu │Fri │Sat │Sun │
├──────────────┼────┴────┴────┴────┴────┴────┴────┤
│ RAC 123 B SUV│ ██ Rented (R. Mugisha) ██│ ░░ buffer│ ● free   │
│ RAD 456 C Van│ ▒▒ Reserved ▒▒│  ● free …        │          │
│ RAF 789 T Trk│ ▓▓ Maintenance ▓▓▓▓│ ● free              │
│ RAB 321 A Sed│ ✖ conflict: insurance expired (red)         │
└──────────────┴──────────────────────────────────────────────────┘
 Category capacity:  SUV 3 free · Sedan 2 free · Truck 1 free
```
- **Interactions:** tap a free cell range (desktop: drag; phone: long-press then drag handles) → opens New Booking with vehicle and dates prefilled (CAL-04). Tap a bar → booking/rental/work order.
- **Conflicts:** red marker with reason: overlap, maintenance due, expired document, vehicle at another branch (CAL-05).
- **Search free vehicles:** a "Find available" bottom sheet (dates, category, seats/capacity) returns only vehicles with no conflicts, valid documents and no critical maintenance (CAL-03).
- **Phone:** show a day agenda list per vehicle instead of the full grid, with horizontal scroll for the week.
- **Rules:** BR-01, BR-03. Buffer time is drawn as a hatched block after returns.

### 5.3 New booking (Officer, Manager) — `/bookings/new`

One page, step-collapsible on phone.

```
┌─────────────────────────────────────────────────┐
│ New booking                                     │
│ 1 DATES        Pickup [Mon 16 Nov 09:00] ▼      │
│                Return [Thu 19 Nov 09:00] ▼      │
│                Branch [Kigali HQ ▼]  One-way ☐  │
│ 2 VEHICLE      Category [SUV ▼]  or  [Pick car] │
│                ◉ RAC 123 B Toyota RAV4  ● free  │
│ 3 CUSTOMER     [Search phone/ID…] [📷 Scan ID]  │
│                Aline Uwase · 078… · Normal ●    │
│                Licence ✓ valid to 2029          │
│ 4 EXTRAS       ☐ Driver  ☐ Child seat  ☐ GPS    │
│                Mileage plan: (•)200km/day ( )Unl│
│                Fuel: Full-to-full               │
│ 5 PAYMENT      Deposit RWF 200,000              │
│ ┌ QUOTE ───────────────────────────────────┐    │
│ │ Rental 3 days        RWF 150,000         │    │
│ │ Extras                         0         │    │
│ │ Discount (5%)       −   7,500            │    │
│ │ VAT 18%                25,650            │    │
│ │ Total               RWF 168,150          │    │
│ │ Deposit                 200,000          │    │
│ └──────────────────────────────────────────┘    │
│ [Save quote PDF] [Save booking] [Send MoMo req] │
└─────────────────────────────────────────────────┘
```
- **Scan ID** (AI-01): camera → OCR → fills name, ID number, nationality, licence number, expiry for **staff review** before saving.
- **Duplicate check:** on phone/email/ID/licence blur call the duplicate endpoint (CUS-03); offer "use existing customer".
- **Live quote:** call the backend pricing endpoint on every relevant change (debounced); the server result is authoritative (RAT-02, Section 8.1).
- **Discount above role limit:** show "Needs approval" and create an approval request; booking stays `Pending` (BR-08).
- **Customer risk:** Blacklisted → block with message; Watch → "manager approval required" (BR-11, CUS-06). AI risk flag shown as a hint (AI-07).
- **Validations:** return after pickup, not in the past (BR-05), licence valid for the whole period (BR-04), credit limit for corporate (BR-12).
- **Conflict on save:** server returns conflict → show message and alternative vehicles (RES-04).
- **Payment request:** MoMo/Airtel phone prompt, status chips `Pending / Paid / Failed`, polled until confirmed. Use an idempotency key per attempt (API-04).
- **Statuses:** Inquiry, Pending, Confirmed, Cancelled, No-show, Converted, Completed (RES-03). Unpaid pending bookings auto-release after the hold time, show a countdown (RES-09).

### 5.4 Booking detail — `/bookings/:id`
Header: number, status badge, customer, vehicle, dates. Tabs: **Summary · Payments · Documents · Activity**. Actions by status: Confirm, Edit, Cancel (reason + fee preview, RES-07), Mark no-show, **Convert to contract** (primary).

### 5.5 Active rentals — `/rentals`

```
┌──────────────────────────────────────────────┐
│ Active rentals  [Overdue 3] [All 18]  🔍      │
│ ⚠ RAC 123 B · A. Uwase · due 14:00 (+3h)     │
│   Balance RWF 120,000        [Call] [Extend] │
│ ● RAD 456 C · MTN Rwanda · due Fri 10:00     │
│   GPS: Huye · 1,240 km                       │
└──────────────────────────────────────────────┘
```
Filters: branch, status, overdue, customer type. Row actions: Call, Extend, Return, Add charge (fine, toll, parking), Log communication. Overdue = expected return + grace period (ACT-02).

### 5.6 Returns due — `/returns-due`
List grouped by **Overdue / Today / Tomorrow**. Primary action on each row: **Start return**.

### 5.7 Contract view — `/rentals/:id`
Header with status (Draft, Active, Extended, Closed, Cancelled). Tabs: **Overview · Charges · Payments · Handover/Return · Amendments · Documents · Communication log**.
- Signed contract is read-only; **Amend** creates an amendment needing its own signature (CON-05, BR-15).
- Buttons: Print, Share (WhatsApp/email), Extend, Swap vehicle, Add charge, Start return.

### 5.7a Contract generation and e-signature
Preview PDF (template per language) → choose signing: **sign on this device** (SignaturePad) or **send secure link** to the customer's phone → status Active → handover becomes enabled (CON-01…03).

### 5.8 Handover wizard (mobile, Officer/Driver) — `/rentals/:id/handover`

Target: completed in under 5 minutes. Stepper at top, auto-saved draft locally after every step.

```
Step 1/6  CHECKS         ┌──────────────────────────┐
 ✓ Licence valid         │ ⚠ Deposit not received   │
 ✓ Customer not blacklist│ [Request MoMo] [Override]│
 ✓ Vehicle rentable      └──────────────────────────┘
 ✗ Deposit paid                              [ Next ]

Step 2/6  READINGS
 Odometer [ 45,210 ] km   (prefilled; cannot be below last reading)
 Fuel     [E ▁▂▃▄▅▆▇ F]   ◉ 3/4
 Equipment: ☑ Spare ☑ Jack ☑ Tools ☑ First aid ☑ Extinguisher

Step 3/6  CHECKLIST      Exterior ✓  Interior ✓  Tyres ✓
                         Lights ✓  Windows ✓  Dashboard warnings ⚠ note

Step 4/6  DAMAGE         [car outline]  ● scratch front-left [📷][note]
                         [ + Add mark ]   "No existing damage" ☐

Step 5/6  PHOTOS (required)
 [📷Front][📷Rear][📷Left][📷Right]
 [📷Interior][📷Odometer][📷Fuel gauge]   7/7 ✓

Step 6/6  SIGN
 Customer confirms vehicle condition  ✍ [signature pad]
 Staff name · time · GPS captured
 [ Complete handover ]
```
- **Block complete** until: required photos, signature, deposit rule met (BR-16, BR-17, HND-08). Override needs permission + reason + approval record.
- **Truck extras (HND-06):** load check, straps, tarpaulin, cargo seal number, cargo photos, declared weight.
- **Offline:** everything saved locally with timestamp and device GPS; upload queue shows pending; on sync conflict (e.g. booking cancelled online) show a conflict screen to the manager, never overwrite silently (HND-07).
- **Result:** vehicle → Rented, contract → Active, handover PDF available.

### 5.9 Return wizard (mobile, Officer) — `/rentals/:id/return`

```
Step 1  READINGS   Return km [ 45,860 ] (≥ handover 45,210)
                   Fuel ◉ 1/2    Time: now (editable with reason)
Step 2  PHOTOS     same required slots as handover
Step 3  COMPARE    ┌─────────Handover─────┬─────────Return───────┐
                   │ [front photo]        │ [front photo]        │
                   │ Fuel 3/4 · 45,210 km │ Fuel 1/2 · 45,860 km │
                   └──────────────────────┴──────────────────────┘
                   ⚠ AI: possible new scratch, rear bumper [Confirm][Dismiss]
Step 4  CHARGES    Excess km (350 × 150)        52,500
                   Fuel shortage                  calc.
                   Late return (3h)               calc.
                   Cleaning / missing equipment   [ + ]
                   Damage                         [ + from step 3 ]
                   Each line editable only with permission + reason
Step 5  BILL       Invoice total · Deposit applied · Balance due / Refund
                   [Collect MoMo] [Cash] [Approve refund request]
Step 6  RELEASE    Send to: ◉ Inspection  ( ) Maintenance
                   [ Close rental ]
```
- **Rules:** reject return km lower than handover (RET-07, BR-06). Damage found creates linked Damage records (RET-04). AI damage flags need staff confirmation before any charge (AI-02). Charges above the damage threshold need approval (BR-09, DMG-05). Return at another branch applies the one-way fee and moves vehicle location (RET-06).
- Calculations come from the server; the client shows them and lets authorised staff adjust.

### 5.10 Extension and vehicle swap — `/rentals/:id/extend`, `/swap`
**Extend:** pick new return date/time → availability check → new price → amendment → signature/approval → updated expected return. If it conflicts with a confirmed booking, show the blocker and a suggested replacement vehicle for the other booking; override requires approval (EXT-01, EXT-02). **Swap:** performs a return record for vehicle A then a handover record for vehicle B (EXT-03). **Early return:** shows refund policy preview (EXT-04).

### 5.11 Trip board and trip detail (Manager, Fleet, Driver view) — `/trips`

```
┌────────────────────────────────────────────────────────────┐
│ Trips [Planned][In progress][Delivered][Closed]  + New trip │
│ ┌ T-0098 Kigali → Rusizi ───── ● In progress ────────────┐ │
│ │ Truck RAF 789 T · Driver J. Habimana · Cargo: cement 18t│ │
│ │ Revenue 1.2M · Costs 640k · Margin 560k (47%)           │ │
│ └─────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘
```
**Trip form:** truck, trailer, driver, customer, origin, stops, destination, cargo type, weight, volume, planned times, pricing basis (day / trip / km / tonne-km), driver and fuel included toggles. **Block** weight above payload, disallowed cargo for body type, driver overlap or wrong licence class (TRP-03, BR-13, BR-14, DRV-02).
**Trip detail:** timeline (pre-trip check → loaded → on road → delivered), cost list (fuel, tolls, allowance, border, parking, loading), POD, margin card. Multi-stop and return-load supported (TRP-05).

### 5.12 Fleet list and vehicle profile (Fleet Mgr) — `/fleet`, `/fleet/:id`

List columns: plate, make/model, category, branch, status, mileage, next service, doc expiry flag. Bulk import/export Excel/CSV with error report (FLT-08).

Vehicle profile:
```
┌───────────────────────────────────────────────┐
│ RAC 123 B · Toyota RAV4 2022   ● Available    │
│ [Status override] [Transfer branch] [Edit]    │
│ Tabs: Details | Documents | History | Maint.  │
│       | Damage | Profit                       │
│ Documents                                     │
│  Insurance   exp 12 Dec 2026  ⚠ 27 days       │
│  Registration exp 03 Mar 2027 ✓               │
│  Inspection  exp 10 Nov 2026  ✖ expired       │
│ Profit card (month)                           │
│  Revenue 2.4M − Maint 300k − Fuel 0 − Ins 150k│
│  − Depreciation 400k − Damage 0 = 1.55M       │
│  Utilization 68% · RevPAV 80k                 │
└───────────────────────────────────────────────┘
```
- Truck fields: payload, GVW, body type, axles, dimensions, allowed cargo (FLT-02).
- **Status:** shown as a controlled model; manual override needs permission + reason and is logged (BR-10, FLT-04). Do not allow free editing of status.
- History timeline: bookings, rentals, trips, inspections, maintenance, damage, fines, status changes (FLT-07).

### 5.13 Customers — `/customers`, `/customers/:id`
List with search by name/phone/ID, filter by type and risk status. Form fields per CUS-02, with duplicate detection and merge (CUS-03). Corporate: credit limit, payment terms, authorised bookers, approved drivers, contract rates (CUS-04).
Profile: details · verification (ID/licence images, masked in lists) · rentals · balance · deposits held · damage history · fines · **risk status** (Normal / Watch / Blacklisted with reason and who set it) · consent and data export/anonymise actions (CUS-08).

### 5.14 Drivers — `/drivers`
Profile: licence classes (incl. heavy goods), expiry, rate, branch, availability calendar, hours worked, trips, incidents, ratings. Assignment screen blocks overlaps and wrong licence class (DRV-02, BR-14).

### 5.15 Maintenance — `/maintenance`
Tabs: **Due soon · Work orders · Schedules · History**. Work order form: vehicle, type (preventive / corrective), garage, parts, labour, cost, start/end, downtime; reserves a slot on the availability board (MNT-04). Above cost limit → approval. AI maintenance prediction chip "Service likely in ~9 days" (AI-06).

### 5.16 Damage and incidents — `/damage`
Damage workflow statuses: Reported → Under Assessment → Approved → Under Repair → Repaired → Insurance Claim → Customer Charged → Closed (DMG-02). Detail shows diagram, photos (handover vs return), cost estimate vs actual, liability, claim, linked contract and customer. **Charge customer** over threshold requires approval. Incidents (accident, fine, theft, breakdown, complaint) per DMG-03; traffic fines auto-match the contract and driver by vehicle and offence time and can be recharged (DMG-04).

### 5.17 Rates and pricing — `/rates`
Rate plans per category or vehicle: hourly, daily, weekly, monthly, km allowance, excess rate, validity, conditions (season, weekend, holiday, branch, customer type, one-way). Extras price list. **Price calculator preview** (enter duration → see breakdown) so staff can verify the cap logic from SRS 8.1 (e.g. 6 days is capped at the weekly price). AI price suggestions appear as dismissible cards with the reason (AI-05).

---

## 6. Money screens (Finance, Owner)

### 6.1 Invoices — `/invoices`, `/invoices/:id`
List: number, customer, contract, type (invoice / credit / debit), total, paid, status, EBM status. Detail: lines, tax, payments allocated, EBM reference, PDF. **No edit or delete** of issued documents, only **Reverse / Issue credit note** (BIL-05, BR-15).

### 6.2 Payments and reconciliation — `/payments`

```
┌─────────────────────────────────────────────────────┐
│ Payments  [Unmatched 6] [Pending 2] [All]  Day: today│
│ MoMo  +25078…  RWF 150,000  ref 8841  → [Match…]    │
│ Bank  Equity   RWF 900,000  ref TT22  → [Match…]    │
│ Cash  Counter  RWF  60,000  RC-0231   ✓ matched     │
│ [ Export day to accounting ]                        │
└─────────────────────────────────────────────────────┘
```
Statuses: Pending (timed out items re-polled), Paid, Failed. Match to invoice(s), partial and advance payments. Payment cannot exceed outstanding unless recorded as advance (BR-07).

### 6.3 Deposits and refunds — `/deposits`
Held, applied, refunded per contract. **Refund requests** list with Approve / Reject (BIL-04, BR-09).

### 6.4 Receivables aging — `/finance/aging`
Buckets 0-30 / 31-60 / 61-90 / 90+, per customer, drill into statement PDF, "Send reminder" (AI-04 drafts the message in en/rw/fr for review).

### 6.5 Reports — `/reports`
Report catalogue (SRS 14.2): vehicle utilization, rental revenue, contracts, customer history, vehicle history, vehicle profitability, outstanding and aging, deposits, damage, accidents, maintenance cost, fuel, mileage, overdue, fleet availability, bookings, cancellations and no-shows, driver performance, branch performance, truck trips and margin, traffic fines, monthly performance.
Common filters: date range, branch, vehicle, category, customer. Actions: PDF, Excel, **schedule email**. Profitability report is labelled "management information based on recorded costs".

### 6.6 Ask your fleet (Owner, Management) — `/ask`

```
┌────────────────────────────────────────────┐
│ Ask your fleet                             │
│ Try: "Who owes me?"  "Least profitable     │
│       truck this month?"                   │
│ ┌────────────────────────────────────────┐ │
│ │ You: Which truck made the least money? │ │
│ │ AI:  RAF 789 T: contribution 120k      │ │
│ │ [table of trucks]  [Open vehicle ▸]    │ │
│ │ Based on: Nov revenue and cost records │ │
│ └────────────────────────────────────────┘ │
│ [ Type a question…                    ➤ ]  │
└────────────────────────────────────────────┘
```
Show sources/figures used (explainable). Answers contain tables and deep links. AI never performs charges, refunds or status changes from chat (AI guardrails 7.2).

---

## 7. Administration (Admin) — `/settings`

| Screen | Content |
|---|---|
| Company | Profile, logo, languages, currencies, numbering formats, time zone |
| Branches & locations | Branch list, address, GPS, opening hours |
| Policies | Grace period, turnaround buffer, fuel policy, deposit rules, cancellation fees, licence age rules (min age, years held), approval thresholds by role |
| Tax | VAT rate, inclusive/exclusive, exemptions, per-line categories |
| Users | List, invite, branch scope, role, 2FA state, devices, force logout |
| Roles & permissions | Matrix editor: module × (V C E A D X) with branch scope |
| Approval chains | Per type: threshold, approver role |
| Contract templates | Per language, logo, legal clauses, preview |
| Integrations | Payment gateway, EBM, messaging, GPS, accounting |
| Subscription | Plan, usage, invoices |
| Audit log | Read-only, filter by user/record/date/action, shows before and after, IP, device; **no edit or delete for anyone** |

---

## 8. Driver app and Customer portal

### 8.1 Driver app (phone only) — `/driver`

Shows only the driver's own jobs.

```
HOME                          JOB DETAIL
┌───────────────────────┐    ┌────────────────────────────┐
│ Hi Jean       ● Online│    │ Trip T-0098                │
│ Today                 │    │ Kigali → Rusizi            │
│ ▸ T-0098 Kigali→Rusizi│    │ Truck RAF 789 T            │
│   08:00 · Cement 18t  │    │ Customer: ABC Ltd  [Call]  │
│ ▸ Chauffeur RC-0231   │    │ Cargo: cement · 18 t       │
│   14:00 · Aline U.    │    │ [Start pre-trip check]     │
│ Upcoming (2)          │    │ [Log expense] [Report issue]│
└───────────────────────┘    │ [Proof of delivery]        │
                             └────────────────────────────┘
```
- **Pre-trip checklist** (pass/fail/note, load photos, seal number, weight) → job moves to In progress.
- **Expense capture:** type (fuel, toll, border, parking, allowance, loading), amount, receipt photo, auto time + GPS. Works offline. Feeds trip cost and margin (TRP-02).
- **Incident report:** type, description, photos, location, urgent call button.
- **Proof of delivery (TRP-04):** photos, recipient name, signature, time, GPS → trip Delivered.
- **Offline-first** with sync queue and visible status. Daily driving hours and rest shown (DRV-03).
- Drivers cannot see prices, other drivers' jobs or customer financial data.

### 8.2 Customer portal — `/portal`

| Screen | Content and behaviour |
|---|---|
| Search | Dates, pickup branch, category, seats → available categories with price from live quote |
| Book / request | Details, extras, quote, ID/licence upload, consent checkbox. Mode set per tenant: instant confirm or request-then-staff-confirms (open question Q6) |
| Sign (`/portal/sign/:token`) | Contract PDF view → signature → done. Token expires, one-time use |
| Pay (`/portal/pay/:token`) | Amount due, choose MoMo / Airtel / card, confirm on phone, status updates automatically |
| My documents | Contracts, invoices, receipts, statements as PDFs |
| Booking status | Confirmation, reminders, change/cancel request |
| Privacy | Consent record, request data export or deletion (CUS-08, NFR-06) |

Language switch en / rw / fr on every page.

---

## 9. Cross-cutting behaviour (apply everywhere)

**Offline (NFR-08):** local DB (e.g. Drift) stores pending handovers, returns, photos, expenses, POD. Queue items have states `Pending / Syncing / Synced / Conflict / Failed`. Retry with backoff, upload photos in the background, resumable. Works at least 24 hours. Global banner: "Offline · 3 items waiting".

**Errors:** map server codes to messages: `409 conflict` (double booking, sync conflict), `422 validation` (field errors inline), `403 forbidden` (hide or explain), `402/approval_required` (create approval and show status).

**Money safety:** pay buttons disabled while a request is in flight; idempotency key per payment and booking action; never show "Paid" until the server confirms.

**Sensitive data:** mask ID and licence numbers in lists, show full only on detail with permission, never log them, no screenshots of ID in notifications.

**Localisation:** all strings in ARB files for `en`, `rw`, `fr`; dates, numbers and currency formatted per tenant; no text inside images.

**Accessibility:** touch targets ≥ 48dp, text scales to 200%, status never colour-only, semantic labels on icons.

**Audit:** actions that change money, status or approvals must send reason and approval reference with the request.

**Performance targets (NFR-01):** main screens < 2 s on 4G; availability search < 1 s; compress photos before upload.

---

## 10. Suggested build order

1. **Foundation:** theme, `ResponsiveScaffold`, auth + 2FA, permissions (`PermissionGate`, route guards), API client, offline queue, l10n.
2. **Core data:** Fleet, Customers (with ID scan), Rates.
3. **Booking path:** Availability board → New booking with live quote → Contract + e-sign → MoMo request.
4. **Field path (highest value):** Handover wizard → Return wizard → Charges and final bill → Deposit/refund.
5. **Active operations:** Active rentals, Returns due, Extension, Overdue alerts.
6. **Money:** Invoices, Payments reconciliation, Aging, Approvals inbox.
7. **Fleet control:** Maintenance, Damage and incidents, Document expiry alerts.
8. **Trucks:** Trips, Driver app, POD, Trip margin.
9. **Insight:** Dashboard, Reports, Vehicle profitability, then AI (Ask your fleet, damage detection, price suggestions).
10. **Admin and portal:** Settings, Users and roles, Audit log, Customer portal.

## 11. Acceptance checklist (from SRS 16)

- [ ] No double booking possible; conflict from server is handled with alternatives shown.
- [ ] Pricing shown matches the server for the SRS 8.1 examples (3, 6, 10, 13, 35 days).
- [ ] Handover and return complete on a mid-range Android phone in under 5 minutes.
- [ ] Handover cannot complete without required photos, signature and deposit rule.
- [ ] Return mileage lower than handover is rejected.
- [ ] Every role sees only allowed modules and only its branches; drivers see only their own jobs.
- [ ] Every approval type routes to an approver and records decision and comment.
- [ ] Offline handover/return/expense/POD saves and syncs without data loss; conflicts are surfaced.
- [ ] Issued invoices and signed contracts cannot be edited or deleted.
- [ ] en / rw / fr available and persisted."
</USER_REQUEST>
<ADDITIONAL_METADATA>
The current local time is: 2026-11-17T16:16:39+02:00.
</ADDITIONAL_METADATA>