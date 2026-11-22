# InventoryPOS — Database Schema Reference

> Companion reference to
> [InventoryPOS-Project-Documentation.md](InventoryPOS-Project-Documentation.md)
> (Chapter 3). The authoritative, machine-generated DDL for the SQLite provider
> lives next to this file at [`../database/Migrations/Schema.sql`](../database/Migrations/Schema.sql).

| Field | Value |
|---|---|
| Engine | SQLite (local-first) via EF Core 8 |
| Context | `InventoryPOS.Data.Context.AppDbContext` |
| Entities | `InventoryPOS.Core.Entities` |
| Configurations | `InventoryPOS.Data.Configurations` |
| Migrations | `InventoryPOS.Data.Migrations` (18 migrations) |
| Optional encryption | SQLCipher whole-database encryption (opt-in) |

## How to regenerate the DDL

```powershell
dotnet ef dbcontext script `
  -p src\InventoryPOS.Data\InventoryPOS.Data.csproj `
  -s src\InventoryPOS.Data\InventoryPOS.Data.csproj `
  -o database\Migrations\Schema.sql
```

To add a schema change:

```powershell
dotnet ef migrations add <Name> `
  -p src\InventoryPOS.Data\InventoryPOS.Data.csproj `
  -s src\InventoryPOS.Data\InventoryPOS.Data.csproj
```

Migrations are applied automatically on startup by `DataService.InitializeAsync`.

## Conventions

- **Primary keys** — every table has an `INTEGER` autoincrement `Id`.
- **Audit columns** — every table derived from `BaseEntity` carries
  `CreatedAt`, `UpdatedAt` (ISO-8601 text) and `IsDeleted` (0/1).
- **Soft delete** — nothing is physically deleted by the app. A global query
  filter excludes `IsDeleted = 1` from every `BaseEntity` query.
- **Tenancy** — every business-owned table carries `BusinessId`. A global query
  filter restricts rows to the active tenant (`ITenantContext.BusinessId`), and
  is bypassed only when no tenant is active (seeding, sign-in) or explicitly via
  `IgnoreQueryFilters()`.
- **Enums** are persisted as `INTEGER`; money values as `TEXT` with fixed
  precision (e.g. `(18,2)` or `(18,4)` for cost).
- **Quantities** are `decimal` in the model and `REAL` in SQLite. The provider
  cannot aggregate, order, or compare `TEXT`-backed decimals, so a value
  converter stores physical units as `REAL`. This enables fractional/weighed
  units (`0.75 kg`) and keeps stock `SUM`/`ORDER BY` queries server-side.
- **Timestamps** are stored as SQLite `TEXT` in ISO-8601 form.

## Enumerations (persisted as INTEGER)

| Enum | Members |
|---|---|
| `UserRole` | Admin=1, Manager=2, Seller=3, Viewer=4 |
| `SubscriptionPlan` | Free=1, Basic=2, Pro=3, Enterprise=4 |
| `SaleStatus` | Pending=1, Completed=2, Cancelled=3, Refunded=4 |
| `PaymentMethod` | Cash=1, Mpesa=2, Debtor=3, BankTransfer=4, Cheque=5 |
| `PaymentStatus` | Pending=1, Completed=2, Failed=3, Refunded=4 |
| `PurchaseOrderStatus` | Draft=1, Submitted=2, Approved=3, Received=4, Cancelled=5 |
| `StockMovementType` | Opening=1, Sale=2, SaleCancelled=3, Refund=4, Purchase=5, Adjustment=6, TransferIn=7, TransferOut=8 |
| `StockTransferStatus` | Pending=1, InTransit=2, Received=3, Cancelled=4 |
| `ReservationStatus` | Active=1, Released=2, Consumed=3, Expired=4 |
| `StkIntentStatus` | Queued=1, Pending=2, Processing=3, Complete=4, Failed=5 |
| `SubscriptionPaymentStatus` | Pending=1, Processing=2, Paid=3, Activated=4, Failed=5 |
| `StockStatus` | InStock=1, LowStock=2, OutOfStock=3 |
| `AlertType` | LowStock=1, OutOfStock=2, Expiry=3 |
| `ExpenseCategory` | Utilities=1, Rent=2, Salaries=3, Supplies=4, Marketing=5, Maintenance=6, Transportation=7, Insurance=8, Taxes=9, Other=10 |
| `SyncStatus` | Pending=1, InProgress=2, Completed=3, Failed=4 |
| `ReceiptType` | Sale=1, Refund=2, Payment=3 |
| `TaxMode` | Exclusive=1, Inclusive=2 |

## Tables

### Tenancy & subscription

| Table | Key columns | Notes |
|---|---|---|
| `Businesses` | `Name`, `Email` (unique), `TaxId`, `CountryCode`, `SubscriptionPlan`, `SubscriptionExpiry`, `IsTrial`, `WrappedDataKey` | The tenant root. `WrappedDataKey` is the per-business AES-256-GCM data key. |
| `SubscriptionPayments` | `BusinessId`, `Plan`, `Amount`, `InvoiceId`, `Status`, `CompletedAt` | M-Pesa subscription purchases. FK → `Businesses` (cascade). |
| `StkPaymentIntents` | `BusinessId`, `SaleId`, `Amount`, `PhoneNumber`, `ApiRef` (unique), `InvoiceId`, `Status`, `Attempts` | Low-connectivity M-Pesa STK reconciliation. |
| `Branches` | `Name`, `Code`, `BusinessId` | Shops belonging to a business. FK → `Businesses` (cascade). |

### Identity & access

| Table | Key columns | Notes |
|---|---|---|
| `Users` | `Username`, `PasswordHash`, `Salt`, `Role`, `IsActive`, `LockoutEnd`, `PinHash`, `PinSalt`, `PinFailedAttempts`, `BusinessId`, `BranchId` | Password (PBKDF2) plus a separate shared-device switch PIN. |
| `AuditEntries` | `BusinessId`, `BranchId`, `UserId`, `Action`, `EntityType`, `EntityId`, `OccurredAt`, `PreviousHash`, `Hash`, `Signature` | Append-only, hash-chained tamper-evident trail. |

### Catalogue

| Table | Key columns | Notes |
|---|---|---|
| `Products` | `Barcode`+`BusinessId` (unique), `Name`, `PurchasePrice`, `AverageCost`, `SellingPrice`, `StockQuantity`, `MinimumStockLevel`, `LeadTimeDays`, `TaxRate`, `UnitOfMeasure`, `TracksBatches`, `TracksSerialNumbers`, `IsService`, `SupplierId`, `CategoryId` | `AverageCost` = weighted-average cost; `LeadTimeDays` feeds reorder suggestions; stock is always held in the product's base unit. |
| `ProductUnits` | `ProductId`, `BusinessId`, `Name`, `Barcode`, `Factor`, `SellingPrice`, `IsBaseUnit`, `IsPurchaseUnit`, `IsSellingUnit` | Pack sizes sold/bought as multiples of the base unit (e.g. carton = 24 each). Indexed by `(BusinessId, Barcode)`. FK → `Products` (cascade). |
| `ProductBatches` | `ProductId`, `BusinessId`, `BatchNumber`, `ManufacturedDate`, `ExpiryDate`, `QuantityReceived`, `QuantityRemaining`, `UnitCost`, `SupplierId` | Lot/batch tracking with FEFO draw-down. Indexed by `(BusinessId, ProductId, ExpiryDate)`. FK → `Products` (cascade). |
| `ProductSerials` | `ProductId`, `BusinessId`, `ProductBatchId`, `SerialNumber`, `Status`, `ReceivedAt`, `SoldAt`, `SaleId`, `SaleItemId` | One row per serialised unit. Indexed by `(BusinessId, SerialNumber)`. FK → `Products` (cascade), → `ProductBatches` (set null). |
| `PriceLists` | `BusinessId`, `Name`, `Description`, `IsDefault`, `IsActive` | Named price sets. One default per business, enforced on save. |
| `PriceListItems` | `PriceListId`, `BusinessId`, `ProductId`, `MinQuantity`, `UnitPrice` | Tiered price per base unit, applying from `MinQuantity` up. Indexed by `(BusinessId, PriceListId, ProductId)`. FK → `PriceLists` (cascade), → `Products` (cascade). |
| `Categories` | `Name`, `BusinessId` | |
| `Suppliers` | `Name`, `ContactPerson`, `TaxId`, `BusinessId` | |
| `InventoryStocks` | `ProductId`, `Quantity`, `Location`, `BranchId` | Per-location stock. |

### Sales & money

| Table | Key columns | Notes |
|---|---|---|
| `Sales` | `InvoiceNumber` (unique), `ReceiptNumber` (unique), `SaleDate`, `SubTotal`, `DiscountAmount`, `TaxAmount`, `RoundingAdjustment`, `TotalAmount`, `AmountPaid`, `ChangeDue`, `PaymentMethod`, `Status`, `IsSynced`, `FiscalReceiptNumber`, `FiscalSignature`, `FiscalStatus`, `CustomerId`, `BranchId` | `RoundingAdjustment` is the signed cash-rounding delta. Fiscal columns hold the e-invoice result. |
| `SaleItems` | `SaleId`, `ProductId`, `ProductName`, `Quantity`, `UnitPrice`, `UnitName`, `UnitFactor`, `UnitQuantity`, `CostPrice`, `DiscountAmount`, `TaxAmount`, `Subtotal`, `Total` | `Quantity` is in base stock units; `UnitQuantity`/`UnitName`/`UnitFactor` record the pack size sold. `CostPrice` snapshots cost for margin reporting. FK → `Sales` (cascade). |
| `Payments` | `SaleId`, `CustomerId`, `Amount`, `Method`, `Status`, `TransactionReference`, `PaymentReference` | Split tender and customer settlement. |
| `Expenses` | `Description`, `Amount`, `ExpenseDate`, `Category`, `BranchId`, `UserId` | |

### Inventory movement

| Table | Key columns | Notes |
|---|---|---|
| `StockMovements` | `ProductId`, `QuantityChange`, `QuantityAfter`, `MovementType`, `Reference`, `Reason`, `PerformedBy`, `BranchId` | Immutable stock ledger. Indexed by `(ProductId, CreatedAt)` and `(BusinessId, CreatedAt)`. |
| `StockAlerts` | `ProductId`, `CurrentStock`, `ThresholdLevel`, `Type`, `IsAcknowledged` | Low-stock / out-of-stock alerts. |
| `StockTransfers` | `Reference`, `FromBranchId`, `ToBranchId`, `Status`, `DispatchedAt`, `ReceivedAt` | Inter-branch transfers. |
| `StockTransferItems` | `StockTransferId`, `ProductId`, `Quantity`, `ReceivedQuantity` | FK → `StockTransfers` (cascade). |
| `StockReservations` | `ProductId`, `Quantity`, `Reference`, `Status`, `ExpiresAt`, `BranchId` | TTL holds shared across channels. Indexed by `(BusinessId, Status, ExpiresAt)`. |
| `PurchaseOrders` | `OrderNumber`, `SupplierId`, `Status`, `SubTotal`, `TaxAmount`, `ShippingCost`, `TotalAmount`, `DeliveryDate` | |
| `PurchaseOrderItems` | `PurchaseOrderId`, `ProductId`, `Quantity`, `UnitPrice`, `ReceivedQuantity` | FK → `PurchaseOrders` (cascade). |

### Sync

| Table | Key columns | Notes |
|---|---|---|
| `SyncLogs` | `EntityType`, `EntityId`, `Status`, `Action`, `ErrorMessage`, `SyncedAt` | Outbox/sync audit. |

## Foreign keys and delete behaviour

Most tenant-owned FKs use `Cascade` or `Restrict` to protect data integrity:

- `Cascade` — child rows belonging to a parent: `Branches`, `Categories`,
  `Suppliers`, `Customers`, `SubscriptionPayments`, `SaleItems`,
  `PurchaseOrderItems`, `StockTransferItems`, `StockMovements`, `StockAlerts`.
- `Restrict` — references that must not silently remove history: `Sales.BusinessId`,
  `Products.BusinessId`, `Payments.SaleId`, `StockMovements.ProductId`,
  `StockReservations`, `AuditEntries`, `StkPaymentIntents`.
- `SetNull` — optional references: `*.BranchId`, `Sales.CustomerId`,
  `Products.SupplierId`/`CategoryId`, `Users.BranchId`.

## Indexes

Highlighted indexes:

- Unique: `Businesses.Email`, `Products(Barcode, BusinessId)`,
  `Sales.InvoiceNumber`, `Sales.ReceiptNumber`, `StkPaymentIntents.ApiRef`.
- Composite/hot-path: `StockMovements(ProductId, CreatedAt)`,
  `StockMovements(BusinessId, CreatedAt)`, `AuditEntries(BusinessId, Id)`,
  `AuditEntries(BusinessId, OccurredAt)`,
  `StockReservations(BusinessId, Status, ExpiresAt)`,
  `StockReservations(BusinessId, Reference)`, `StkPaymentIntents(BusinessId, Status)`.

The full, exact list is in [`Schema.sql`](../database/Migrations/Schema.sql).

## Migration history

| # | Migration | Adds |
|---|---|---|
| 1 | `InitialCreate` | Core entities |
| 2 | `AddMultiTenancyAndSubscriptions` | Tenancy + subscription fields |
| 3 | `AddSubscriptionPayments` | `SubscriptionPayments` |
| 4 | `AddStockMovements` | Stock ledger |
| 5 | `AddSaleItemCostPrice` | `SaleItems.CostPrice` |
| 6 | `AddStockTransfers` | Transfers |
| 7 | `AddFiscalReceiptFields` | Fiscal columns on `Sales` |
| 8 | `AddSaleRoundingAdjustment` | `Sales.RoundingAdjustment` |
| 9 | `AddProductAverageCost` | `Products.AverageCost` |
| 10 | `AddProductLeadTimeDays` | `Products.LeadTimeDays` |
| 11 | `AddStockReservations` | `StockReservations` |
| 12 | `AddStkPaymentIntents` | `StkPaymentIntents` |
| 13 | `AddAuditTrailAndSharedDeviceSecurity` | `AuditEntries` + user PIN columns |
| 14 | `AddBusinessCountryCode` | `Businesses.CountryCode` |
| 15 | `ConvertQuantitiesToDecimal` | All quantity columns `INTEGER` → `REAL` (fractional units) |
| 16 | `AddProductUnits` | `ProductUnits` table + sale-line unit columns |
| 17 | `AddBatchAndSerialTracking` | `ProductBatches` + `ProductSerials` tables and product tracking flags |
| 18 | `AddPriceLists` | `PriceLists` + `PriceListItems` tables and `Customers.PriceListId` |

## Encryption at rest

Whole-database encryption (SQLCipher) is **opt-in** and off by default. When
enabled, the passphrase is kept in `SecureStorage` (key `DatabasePassphrase`) and
an existing plaintext database is migrated in place using
`ATTACH DATABASE … KEY` followed by `sqlcipher_export`. Enabling or disabling
requires an application restart. See `DatabaseEncryptionService`.
