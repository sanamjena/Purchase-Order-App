# Purchase Order Management App (Salesforce)

A Salesforce DX application for managing Purchase Orders from request through receipt, including line-item pricing, approval-friendly statuses, and operational KPI visibility.

---

## What this project includes

### Data model
- `Purchase_Order__c` (parent object)
  - Supplier details
  - Requester
  - Lifecycle status
  - Order and delivery dates
  - Tax, shipping, discount
  - Rollup and formula-based totals
- `Purchase_Order_Line__c` (child object)
  - Master-detail to purchase order
  - Product/SKU
  - Quantity and unit price
  - Calculated line total

### Business logic
- `PurchaseOrderService` (Apex)
  - Query purchase orders and line items
  - Create/update orders and line items
  - Basic business validation
  - Dashboard metrics aggregation
- `PurchaseOrderController` (Apex)
  - `@AuraEnabled` endpoints for Lightning Web Components

### User experience
- `purchaseOrderManager` LWC
  - Create and review purchase orders
  - Select an order and add line items
- `purchaseOrderDashboard` LWC
  - KPI summary for open amount, overdue count, and current-month value
- Lightning app: **Purchase Order Management**
- Tabs for both custom objects
- Permission set: **Purchase_Order_Manager**
- Approval workflow support (submit/approve/reject) through Apex + LWC actions
- Budget governance with remaining-budget and over-budget KPIs
- RFP → RFQ → Purchase Order conversion process for strategic sourcing
- Experience Cloud user distribution for RFP outreach with send tracking

### Guardrails
- Validation rule: expected delivery cannot be before order date
- Validation rule: line quantity must be greater than zero
- Validation rule: closed orders require positive total amount

---

## Prerequisites

- A Salesforce org (Developer, Sandbox, or Scratch Org)
- [Salesforce CLI (`sf`)](https://developer.salesforce.com/tools/salesforcecli)
- Access to assign permission sets in the target org

---

## Project structure

```text
force-app/main/default/
  applications/        # Lightning app
  classes/             # Apex services/controllers/tests
  lwc/                 # Lightning Web Components
  objects/             # Custom objects, fields, validation rules, list views
  permissionsets/      # Permission set metadata
  tabs/                # Object tabs
manifest/package.xml   # Manifest-based deployment support
scripts/validate_metadata.py
```

---

## Deployment

### 1) Authorize your org

```bash
sf org login web --alias targetOrg
```

### 2) Deploy source format metadata

```bash
sf project deploy start --target-org targetOrg --source-dir force-app
```

### 3) (Optional) Deploy using package manifest

```bash
sf project deploy start --target-org targetOrg --manifest manifest/package.xml
```

### 4) Assign permission set

```bash
sf org assign permset --target-org targetOrg --name Purchase_Order_Manager
```

### 5) Open the app

From App Launcher, open **Purchase Order Management**.

---

## Local validation and testing

### Metadata sanity checks (local)

```bash
python scripts/validate_metadata.py
```

### Apex unit tests (in org)

```bash
sf apex run test --target-org targetOrg --tests PurchaseOrderServiceTest,PurchaseOrderControllerTest --code-coverage --result-format human
```

---

## Post-deployment setup suggestions

- Add `purchaseOrderManager` and `purchaseOrderDashboard` to your Home/App pages via Lightning App Builder.
- Create list views by status (e.g., Submitted, Ordered, Overdue) for purchasing teams.
- Add approval process and email notifications if your org requires formal purchasing approvals.
- Define RFP and RFQ approval ownership by department for audit readiness.

---

## Notes

- This package is **unmanaged metadata** intended for direct deployment in your org.
- No external integrations are required to run the current version.
- If Salesforce CLI is unavailable in your environment, local XML validation can still be run using `python scripts/validate_metadata.py`.
