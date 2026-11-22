CREATE TABLE "Businesses" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Businesses" PRIMARY KEY AUTOINCREMENT,
    "Name" TEXT NOT NULL,
    "Email" TEXT NOT NULL,
    "Phone" TEXT NOT NULL,
    "Address" TEXT NOT NULL,
    "LogoUrl" TEXT NOT NULL,
    "TaxId" TEXT NOT NULL,
    "IsActive" INTEGER NOT NULL,
    "CountryCode" TEXT NOT NULL,
    "SubscriptionPlan" INTEGER NOT NULL,
    "SubscriptionStartedAt" TEXT NULL,
    "SubscriptionExpiry" TEXT NULL,
    "IsTrial" INTEGER NOT NULL,
    "WrappedDataKey" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL
);


CREATE TABLE "PriceLists" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_PriceLists" PRIMARY KEY AUTOINCREMENT,
    "BusinessId" INTEGER NOT NULL,
    "Name" TEXT NOT NULL,
    "Description" TEXT NOT NULL,
    "IsDefault" INTEGER NOT NULL,
    "IsActive" INTEGER NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL
);


CREATE TABLE "AuditEntries" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_AuditEntries" PRIMARY KEY AUTOINCREMENT,
    "BusinessId" INTEGER NOT NULL,
    "BranchId" INTEGER NULL,
    "UserId" INTEGER NULL,
    "UserName" TEXT NOT NULL,
    "Action" TEXT NOT NULL,
    "EntityType" TEXT NOT NULL,
    "EntityId" INTEGER NULL,
    "Details" TEXT NOT NULL,
    "OccurredAt" TEXT NOT NULL,
    "PreviousHash" TEXT NOT NULL,
    "Hash" TEXT NOT NULL,
    "Signature" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_AuditEntries_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE RESTRICT
);


CREATE TABLE "Branches" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Branches" PRIMARY KEY AUTOINCREMENT,
    "Name" TEXT NOT NULL,
    "Code" TEXT NOT NULL,
    "Address" TEXT NOT NULL,
    "Phone" TEXT NOT NULL,
    "Email" TEXT NOT NULL,
    "ManagerName" TEXT NOT NULL,
    "IsActive" INTEGER NOT NULL,
    "Latitude" TEXT NOT NULL,
    "Longitude" TEXT NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_Branches_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE
);


CREATE TABLE "Categories" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Categories" PRIMARY KEY AUTOINCREMENT,
    "Name" TEXT NOT NULL,
    "Description" TEXT NOT NULL,
    "IsActive" INTEGER NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_Categories_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE
);


CREATE TABLE "StkPaymentIntents" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_StkPaymentIntents" PRIMARY KEY AUTOINCREMENT,
    "BusinessId" INTEGER NOT NULL,
    "SaleId" INTEGER NULL,
    "Amount" TEXT NOT NULL,
    "PhoneNumber" TEXT NOT NULL,
    "ApiRef" TEXT NOT NULL,
    "InvoiceId" TEXT NULL,
    "Status" INTEGER NOT NULL,
    "Attempts" INTEGER NOT NULL,
    "LastCheckedAt" TEXT NULL,
    "FailureReason" TEXT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_StkPaymentIntents_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE RESTRICT
);


CREATE TABLE "SubscriptionPayments" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_SubscriptionPayments" PRIMARY KEY AUTOINCREMENT,
    "BusinessId" INTEGER NOT NULL,
    "Plan" INTEGER NOT NULL,
    "Amount" TEXT NOT NULL,
    "Currency" TEXT NOT NULL,
    "PhoneNumber" TEXT NOT NULL,
    "Email" TEXT NOT NULL,
    "ApiReference" TEXT NOT NULL,
    "InvoiceId" TEXT NOT NULL,
    "Status" INTEGER NOT NULL,
    "CompletedAt" TEXT NULL,
    "LastCheckedAt" TEXT NULL,
    "Notes" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_SubscriptionPayments_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE
);


CREATE TABLE "Suppliers" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Suppliers" PRIMARY KEY AUTOINCREMENT,
    "Name" TEXT NOT NULL,
    "ContactPerson" TEXT NOT NULL,
    "Email" TEXT NOT NULL,
    "Phone" TEXT NOT NULL,
    "Address" TEXT NOT NULL,
    "City" TEXT NOT NULL,
    "PostalCode" TEXT NOT NULL,
    "Country" TEXT NOT NULL,
    "TaxId" TEXT NOT NULL,
    "Notes" TEXT NOT NULL,
    "IsActive" INTEGER NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_Suppliers_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE
);


CREATE TABLE "SyncLogs" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_SyncLogs" PRIMARY KEY AUTOINCREMENT,
    "EntityType" TEXT NOT NULL,
    "EntityId" INTEGER NOT NULL,
    "Status" INTEGER NOT NULL,
    "Action" TEXT NOT NULL,
    "ErrorMessage" TEXT NOT NULL,
    "SyncedAt" TEXT NULL,
    "BusinessId" INTEGER NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_SyncLogs_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE
);


CREATE TABLE "Customers" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Customers" PRIMARY KEY AUTOINCREMENT,
    "FirstName" TEXT NOT NULL,
    "LastName" TEXT NOT NULL,
    "Email" TEXT NOT NULL,
    "Phone" TEXT NOT NULL,
    "Address" TEXT NOT NULL,
    "City" TEXT NOT NULL,
    "PostalCode" TEXT NOT NULL,
    "Country" TEXT NOT NULL,
    "TaxId" TEXT NOT NULL,
    "Notes" TEXT NOT NULL,
    "CreditLimit" TEXT NOT NULL DEFAULT '0.0',
    "CurrentBalance" TEXT NOT NULL DEFAULT '0.0',
    "IsActive" INTEGER NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "BranchId" INTEGER NULL,
    "PriceListId" INTEGER NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_Customers_Branches_BranchId" FOREIGN KEY ("BranchId") REFERENCES "Branches" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_Customers_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE RESTRICT
);


CREATE TABLE "StockTransfers" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_StockTransfers" PRIMARY KEY AUTOINCREMENT,
    "Reference" TEXT NOT NULL,
    "FromBranchId" INTEGER NOT NULL,
    "ToBranchId" INTEGER NOT NULL,
    "Status" INTEGER NOT NULL,
    "Notes" TEXT NOT NULL,
    "RequestedBy" TEXT NOT NULL,
    "DispatchedAt" TEXT NULL,
    "ReceivedAt" TEXT NULL,
    "BusinessId" INTEGER NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_StockTransfers_Branches_FromBranchId" FOREIGN KEY ("FromBranchId") REFERENCES "Branches" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_StockTransfers_Branches_ToBranchId" FOREIGN KEY ("ToBranchId") REFERENCES "Branches" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_StockTransfers_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE
);


CREATE TABLE "Users" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Users" PRIMARY KEY AUTOINCREMENT,
    "FirstName" TEXT NOT NULL,
    "LastName" TEXT NOT NULL,
    "Email" TEXT NOT NULL,
    "Phone" TEXT NOT NULL,
    "Username" TEXT NOT NULL,
    "PasswordHash" TEXT NOT NULL,
    "Salt" TEXT NOT NULL,
    "Role" INTEGER NOT NULL,
    "IsActive" INTEGER NOT NULL,
    "IsOnline" INTEGER NOT NULL,
    "LastLoginAt" TEXT NULL,
    "ProfileImageUrl" TEXT NOT NULL,
    "RefreshToken" TEXT NOT NULL,
    "RefreshTokenExpiry" TEXT NULL,
    "RequiresPasswordChange" INTEGER NOT NULL,
    "FailedLoginAttempts" INTEGER NOT NULL,
    "LockoutEnd" TEXT NULL,
    "PinHash" TEXT NOT NULL,
    "PinSalt" TEXT NOT NULL,
    "PinFailedAttempts" INTEGER NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "BranchId" INTEGER NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_Users_Branches_BranchId" FOREIGN KEY ("BranchId") REFERENCES "Branches" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_Users_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE RESTRICT
);


CREATE TABLE "Products" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Products" PRIMARY KEY AUTOINCREMENT,
    "Barcode" TEXT NOT NULL,
    "Name" TEXT NOT NULL,
    "Description" TEXT NOT NULL,
    "PurchasePrice" TEXT NOT NULL,
    "AverageCost" TEXT NOT NULL DEFAULT '0.0',
    "SellingPrice" TEXT NOT NULL,
    "StockQuantity" REAL NOT NULL DEFAULT 0.0,
    "MinimumStockLevel" REAL NOT NULL DEFAULT 2.0,
    "LeadTimeDays" INTEGER NOT NULL DEFAULT 7,
    "Category" TEXT NOT NULL,
    "SubCategory" TEXT NOT NULL,
    "IsService" INTEGER NOT NULL,
    "ImageUrl" TEXT NOT NULL,
    "UnitOfMeasure" TEXT NOT NULL,
    "TaxRate" TEXT NOT NULL DEFAULT '0.0',
    "TracksBatches" INTEGER NOT NULL,
    "TracksSerialNumbers" INTEGER NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "SupplierId" INTEGER NULL,
    "CategoryId" INTEGER NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_Products_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_Products_Categories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "Categories" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_Products_Suppliers_SupplierId" FOREIGN KEY ("SupplierId") REFERENCES "Suppliers" ("Id") ON DELETE SET NULL
);


CREATE TABLE "Expenses" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Expenses" PRIMARY KEY AUTOINCREMENT,
    "Description" TEXT NOT NULL,
    "Amount" TEXT NOT NULL,
    "ExpenseDate" TEXT NOT NULL,
    "Category" INTEGER NOT NULL,
    "Notes" TEXT NOT NULL,
    "ReceiptUrl" TEXT NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "BranchId" INTEGER NULL,
    "UserId" INTEGER NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_Expenses_Branches_BranchId" FOREIGN KEY ("BranchId") REFERENCES "Branches" ("Id"),
    CONSTRAINT "FK_Expenses_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Expenses_Users_UserId" FOREIGN KEY ("UserId") REFERENCES "Users" ("Id")
);


CREATE TABLE "PurchaseOrders" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_PurchaseOrders" PRIMARY KEY AUTOINCREMENT,
    "OrderNumber" TEXT NOT NULL,
    "OrderDate" TEXT NOT NULL,
    "ExpectedDeliveryDate" TEXT NULL,
    "DeliveryDate" TEXT NULL,
    "Status" INTEGER NOT NULL,
    "SubTotal" TEXT NOT NULL,
    "TaxAmount" TEXT NOT NULL,
    "ShippingCost" TEXT NOT NULL,
    "DiscountAmount" TEXT NOT NULL,
    "TotalAmount" TEXT NOT NULL,
    "Notes" TEXT NOT NULL,
    "ShippingAddress" TEXT NOT NULL,
    "PaymentTerms" TEXT NOT NULL,
    "SupplierId" INTEGER NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "CreatedByUserId" INTEGER NULL,
    "BranchId" INTEGER NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_PurchaseOrders_Branches_BranchId" FOREIGN KEY ("BranchId") REFERENCES "Branches" ("Id"),
    CONSTRAINT "FK_PurchaseOrders_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_PurchaseOrders_Suppliers_SupplierId" FOREIGN KEY ("SupplierId") REFERENCES "Suppliers" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_PurchaseOrders_Users_CreatedByUserId" FOREIGN KEY ("CreatedByUserId") REFERENCES "Users" ("Id")
);


CREATE TABLE "Sales" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Sales" PRIMARY KEY AUTOINCREMENT,
    "InvoiceNumber" TEXT NOT NULL,
    "SaleDate" TEXT NOT NULL,
    "SubTotal" TEXT NOT NULL,
    "DiscountAmount" TEXT NOT NULL DEFAULT '0.0',
    "DiscountPercentage" TEXT NOT NULL DEFAULT '0.0',
    "TaxAmount" TEXT NOT NULL DEFAULT '0.0',
    "TotalAmount" TEXT NOT NULL,
    "RoundingAdjustment" TEXT NOT NULL DEFAULT '0.0',
    "AmountPaid" TEXT NOT NULL DEFAULT '0.0',
    "ChangeDue" TEXT NOT NULL DEFAULT '0.0',
    "PaymentMethod" INTEGER NOT NULL,
    "Status" INTEGER NOT NULL,
    "SalespersonName" TEXT NOT NULL,
    "SalespersonId" INTEGER NULL,
    "Notes" TEXT NOT NULL,
    "ReceiptNumber" TEXT NOT NULL,
    "IsSynced" INTEGER NOT NULL,
    "SyncedAt" TEXT NULL,
    "FiscalReceiptNumber" TEXT NOT NULL,
    "FiscalInternalData" TEXT NOT NULL,
    "FiscalSignature" TEXT NOT NULL,
    "FiscalStatus" TEXT NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "CustomerId" INTEGER NULL,
    "BranchId" INTEGER NULL,
    "UserId" INTEGER NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_Sales_Branches_BranchId" FOREIGN KEY ("BranchId") REFERENCES "Branches" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_Sales_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_Sales_Customers_CustomerId" FOREIGN KEY ("CustomerId") REFERENCES "Customers" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_Sales_Users_UserId" FOREIGN KEY ("UserId") REFERENCES "Users" ("Id")
);


CREATE TABLE "InventoryStocks" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_InventoryStocks" PRIMARY KEY AUTOINCREMENT,
    "ProductId" INTEGER NOT NULL,
    "Quantity" REAL NOT NULL,
    "Location" TEXT NOT NULL,
    "Notes" TEXT NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "BranchId" INTEGER NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_InventoryStocks_Branches_BranchId" FOREIGN KEY ("BranchId") REFERENCES "Branches" ("Id"),
    CONSTRAINT "FK_InventoryStocks_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_InventoryStocks_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE
);


CREATE TABLE "PriceListItems" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_PriceListItems" PRIMARY KEY AUTOINCREMENT,
    "PriceListId" INTEGER NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "ProductId" INTEGER NOT NULL,
    "MinQuantity" REAL NOT NULL,
    "UnitPrice" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_PriceListItems_PriceLists_PriceListId" FOREIGN KEY ("PriceListId") REFERENCES "PriceLists" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_PriceListItems_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE
);


CREATE TABLE "ProductBatches" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_ProductBatches" PRIMARY KEY AUTOINCREMENT,
    "ProductId" INTEGER NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "BatchNumber" TEXT NOT NULL,
    "ManufacturedDate" TEXT NULL,
    "ExpiryDate" TEXT NULL,
    "QuantityReceived" REAL NOT NULL,
    "QuantityRemaining" REAL NOT NULL,
    "UnitCost" TEXT NOT NULL,
    "SupplierId" INTEGER NULL,
    "Notes" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_ProductBatches_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE
);


CREATE TABLE "ProductUnits" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_ProductUnits" PRIMARY KEY AUTOINCREMENT,
    "ProductId" INTEGER NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "Name" TEXT NOT NULL,
    "Barcode" TEXT NOT NULL,
    "Factor" REAL NOT NULL,
    "SellingPrice" TEXT NOT NULL,
    "IsBaseUnit" INTEGER NOT NULL,
    "IsPurchaseUnit" INTEGER NOT NULL,
    "IsSellingUnit" INTEGER NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_ProductUnits_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE
);


CREATE TABLE "StockAlerts" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_StockAlerts" PRIMARY KEY AUTOINCREMENT,
    "ProductId" INTEGER NOT NULL,
    "CurrentStock" REAL NOT NULL,
    "ThresholdLevel" REAL NOT NULL,
    "Type" INTEGER NOT NULL,
    "IsAcknowledged" INTEGER NOT NULL,
    "AcknowledgedAt" TEXT NULL,
    "AcknowledgedByUserId" INTEGER NULL,
    "Notes" TEXT NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_StockAlerts_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_StockAlerts_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_StockAlerts_Users_AcknowledgedByUserId" FOREIGN KEY ("AcknowledgedByUserId") REFERENCES "Users" ("Id")
);


CREATE TABLE "StockMovements" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_StockMovements" PRIMARY KEY AUTOINCREMENT,
    "ProductId" INTEGER NOT NULL,
    "QuantityChange" REAL NOT NULL,
    "QuantityAfter" REAL NOT NULL,
    "MovementType" INTEGER NOT NULL,
    "Reference" TEXT NOT NULL,
    "Reason" TEXT NOT NULL,
    "PerformedBy" TEXT NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "BranchId" INTEGER NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_StockMovements_Branches_BranchId" FOREIGN KEY ("BranchId") REFERENCES "Branches" ("Id"),
    CONSTRAINT "FK_StockMovements_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_StockMovements_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE RESTRICT
);


CREATE TABLE "StockReservations" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_StockReservations" PRIMARY KEY AUTOINCREMENT,
    "ProductId" INTEGER NOT NULL,
    "Quantity" REAL NOT NULL,
    "Reference" TEXT NOT NULL,
    "Status" INTEGER NOT NULL,
    "ExpiresAt" TEXT NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "BranchId" INTEGER NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_StockReservations_Branches_BranchId" FOREIGN KEY ("BranchId") REFERENCES "Branches" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_StockReservations_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_StockReservations_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE RESTRICT
);


CREATE TABLE "StockTransferItems" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_StockTransferItems" PRIMARY KEY AUTOINCREMENT,
    "StockTransferId" INTEGER NOT NULL,
    "ProductId" INTEGER NOT NULL,
    "ProductName" TEXT NOT NULL,
    "Quantity" REAL NOT NULL,
    "ReceivedQuantity" REAL NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_StockTransferItems_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_StockTransferItems_StockTransfers_StockTransferId" FOREIGN KEY ("StockTransferId") REFERENCES "StockTransfers" ("Id") ON DELETE CASCADE
);


CREATE TABLE "PurchaseOrderItems" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_PurchaseOrderItems" PRIMARY KEY AUTOINCREMENT,
    "PurchaseOrderId" INTEGER NOT NULL,
    "ProductId" INTEGER NOT NULL,
    "ProductName" TEXT NOT NULL,
    "Quantity" REAL NOT NULL,
    "UnitPrice" TEXT NOT NULL,
    "TaxAmount" TEXT NOT NULL,
    "Total" TEXT NOT NULL,
    "ReceivedQuantity" REAL NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_PurchaseOrderItems_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_PurchaseOrderItems_PurchaseOrders_PurchaseOrderId" FOREIGN KEY ("PurchaseOrderId") REFERENCES "PurchaseOrders" ("Id") ON DELETE CASCADE
);


CREATE TABLE "Payments" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Payments" PRIMARY KEY AUTOINCREMENT,
    "Amount" TEXT NOT NULL,
    "PaymentDate" TEXT NOT NULL,
    "Method" INTEGER NOT NULL,
    "Status" INTEGER NOT NULL,
    "TransactionReference" TEXT NOT NULL,
    "PaymentReference" TEXT NOT NULL,
    "Notes" TEXT NOT NULL,
    "SaleId" INTEGER NULL,
    "CustomerId" INTEGER NULL,
    "BusinessId" INTEGER NOT NULL,
    "BranchId" INTEGER NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_Payments_Branches_BranchId" FOREIGN KEY ("BranchId") REFERENCES "Branches" ("Id"),
    CONSTRAINT "FK_Payments_Businesses_BusinessId" FOREIGN KEY ("BusinessId") REFERENCES "Businesses" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Payments_Customers_CustomerId" FOREIGN KEY ("CustomerId") REFERENCES "Customers" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_Payments_Sales_SaleId" FOREIGN KEY ("SaleId") REFERENCES "Sales" ("Id") ON DELETE RESTRICT
);


CREATE TABLE "SaleItems" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_SaleItems" PRIMARY KEY AUTOINCREMENT,
    "SaleId" INTEGER NOT NULL,
    "ProductId" INTEGER NOT NULL,
    "ProductName" TEXT NOT NULL,
    "ProductBarcode" TEXT NOT NULL,
    "Quantity" REAL NOT NULL,
    "UnitPrice" TEXT NOT NULL,
    "UnitName" TEXT NOT NULL,
    "UnitFactor" REAL NOT NULL,
    "UnitQuantity" REAL NOT NULL,
    "CostPrice" TEXT NOT NULL,
    "DiscountAmount" TEXT NOT NULL,
    "TaxAmount" TEXT NOT NULL,
    "Subtotal" TEXT NOT NULL,
    "Total" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_SaleItems_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_SaleItems_Sales_SaleId" FOREIGN KEY ("SaleId") REFERENCES "Sales" ("Id") ON DELETE CASCADE
);


CREATE TABLE "ProductSerials" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_ProductSerials" PRIMARY KEY AUTOINCREMENT,
    "ProductId" INTEGER NOT NULL,
    "BusinessId" INTEGER NOT NULL,
    "ProductBatchId" INTEGER NULL,
    "SerialNumber" TEXT NOT NULL,
    "Status" INTEGER NOT NULL,
    "ReceivedAt" TEXT NOT NULL,
    "SoldAt" TEXT NULL,
    "SaleId" INTEGER NULL,
    "SaleItemId" INTEGER NULL,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    "IsDeleted" INTEGER NOT NULL,
    CONSTRAINT "FK_ProductSerials_ProductBatches_ProductBatchId" FOREIGN KEY ("ProductBatchId") REFERENCES "ProductBatches" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_ProductSerials_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE
);


CREATE INDEX "IX_AuditEntries_BusinessId_Id" ON "AuditEntries" ("BusinessId", "Id");


CREATE INDEX "IX_AuditEntries_BusinessId_OccurredAt" ON "AuditEntries" ("BusinessId", "OccurredAt");


CREATE INDEX "IX_Branches_BusinessId" ON "Branches" ("BusinessId");


CREATE UNIQUE INDEX "IX_Businesses_Email" ON "Businesses" ("Email");


CREATE INDEX "IX_Categories_BusinessId" ON "Categories" ("BusinessId");


CREATE INDEX "IX_Customers_BranchId" ON "Customers" ("BranchId");


CREATE INDEX "IX_Customers_BusinessId" ON "Customers" ("BusinessId");


CREATE INDEX "IX_Expenses_BranchId" ON "Expenses" ("BranchId");


CREATE INDEX "IX_Expenses_BusinessId" ON "Expenses" ("BusinessId");


CREATE INDEX "IX_Expenses_UserId" ON "Expenses" ("UserId");


CREATE INDEX "IX_InventoryStocks_BranchId" ON "InventoryStocks" ("BranchId");


CREATE INDEX "IX_InventoryStocks_BusinessId" ON "InventoryStocks" ("BusinessId");


CREATE INDEX "IX_InventoryStocks_ProductId" ON "InventoryStocks" ("ProductId");


CREATE INDEX "IX_Payments_BranchId" ON "Payments" ("BranchId");


CREATE INDEX "IX_Payments_BusinessId" ON "Payments" ("BusinessId");


CREATE INDEX "IX_Payments_CustomerId" ON "Payments" ("CustomerId");


CREATE INDEX "IX_Payments_SaleId" ON "Payments" ("SaleId");


CREATE INDEX "IX_PriceListItems_BusinessId_PriceListId_ProductId" ON "PriceListItems" ("BusinessId", "PriceListId", "ProductId");


CREATE INDEX "IX_PriceListItems_PriceListId" ON "PriceListItems" ("PriceListId");


CREATE INDEX "IX_PriceListItems_ProductId" ON "PriceListItems" ("ProductId");


CREATE INDEX "IX_PriceLists_BusinessId_Name" ON "PriceLists" ("BusinessId", "Name");


CREATE INDEX "IX_ProductBatches_BusinessId_ProductId_ExpiryDate" ON "ProductBatches" ("BusinessId", "ProductId", "ExpiryDate");


CREATE INDEX "IX_ProductBatches_ProductId" ON "ProductBatches" ("ProductId");


CREATE UNIQUE INDEX "IX_Products_Barcode_BusinessId" ON "Products" ("Barcode", "BusinessId");


CREATE INDEX "IX_Products_BusinessId" ON "Products" ("BusinessId");


CREATE INDEX "IX_Products_CategoryId" ON "Products" ("CategoryId");


CREATE INDEX "IX_Products_SupplierId" ON "Products" ("SupplierId");


CREATE INDEX "IX_ProductSerials_BusinessId_SerialNumber" ON "ProductSerials" ("BusinessId", "SerialNumber");


CREATE INDEX "IX_ProductSerials_ProductBatchId" ON "ProductSerials" ("ProductBatchId");


CREATE INDEX "IX_ProductSerials_ProductId" ON "ProductSerials" ("ProductId");


CREATE INDEX "IX_ProductUnits_BusinessId_Barcode" ON "ProductUnits" ("BusinessId", "Barcode");


CREATE INDEX "IX_ProductUnits_ProductId" ON "ProductUnits" ("ProductId");


CREATE INDEX "IX_PurchaseOrderItems_ProductId" ON "PurchaseOrderItems" ("ProductId");


CREATE INDEX "IX_PurchaseOrderItems_PurchaseOrderId" ON "PurchaseOrderItems" ("PurchaseOrderId");


CREATE INDEX "IX_PurchaseOrders_BranchId" ON "PurchaseOrders" ("BranchId");


CREATE INDEX "IX_PurchaseOrders_BusinessId" ON "PurchaseOrders" ("BusinessId");


CREATE INDEX "IX_PurchaseOrders_CreatedByUserId" ON "PurchaseOrders" ("CreatedByUserId");


CREATE INDEX "IX_PurchaseOrders_SupplierId" ON "PurchaseOrders" ("SupplierId");


CREATE INDEX "IX_SaleItems_ProductId" ON "SaleItems" ("ProductId");


CREATE INDEX "IX_SaleItems_SaleId" ON "SaleItems" ("SaleId");


CREATE INDEX "IX_Sales_BranchId" ON "Sales" ("BranchId");


CREATE INDEX "IX_Sales_BusinessId" ON "Sales" ("BusinessId");


CREATE INDEX "IX_Sales_CustomerId" ON "Sales" ("CustomerId");


CREATE UNIQUE INDEX "IX_Sales_InvoiceNumber" ON "Sales" ("InvoiceNumber");


CREATE UNIQUE INDEX "IX_Sales_ReceiptNumber" ON "Sales" ("ReceiptNumber");


CREATE INDEX "IX_Sales_UserId" ON "Sales" ("UserId");


CREATE UNIQUE INDEX "IX_StkPaymentIntents_ApiRef" ON "StkPaymentIntents" ("ApiRef");


CREATE INDEX "IX_StkPaymentIntents_BusinessId_Status" ON "StkPaymentIntents" ("BusinessId", "Status");


CREATE INDEX "IX_StockAlerts_AcknowledgedByUserId" ON "StockAlerts" ("AcknowledgedByUserId");


CREATE INDEX "IX_StockAlerts_BusinessId" ON "StockAlerts" ("BusinessId");


CREATE INDEX "IX_StockAlerts_ProductId" ON "StockAlerts" ("ProductId");


CREATE INDEX "IX_StockMovements_BranchId" ON "StockMovements" ("BranchId");


CREATE INDEX "IX_StockMovements_BusinessId_CreatedAt" ON "StockMovements" ("BusinessId", "CreatedAt");


CREATE INDEX "IX_StockMovements_ProductId_CreatedAt" ON "StockMovements" ("ProductId", "CreatedAt");


CREATE INDEX "IX_StockReservations_BranchId" ON "StockReservations" ("BranchId");


CREATE INDEX "IX_StockReservations_BusinessId_Reference" ON "StockReservations" ("BusinessId", "Reference");


CREATE INDEX "IX_StockReservations_BusinessId_Status_ExpiresAt" ON "StockReservations" ("BusinessId", "Status", "ExpiresAt");


CREATE INDEX "IX_StockReservations_ProductId" ON "StockReservations" ("ProductId");


CREATE INDEX "IX_StockTransferItems_ProductId" ON "StockTransferItems" ("ProductId");


CREATE INDEX "IX_StockTransferItems_StockTransferId" ON "StockTransferItems" ("StockTransferId");


CREATE INDEX "IX_StockTransfers_BusinessId" ON "StockTransfers" ("BusinessId");


CREATE INDEX "IX_StockTransfers_FromBranchId" ON "StockTransfers" ("FromBranchId");


CREATE INDEX "IX_StockTransfers_ToBranchId" ON "StockTransfers" ("ToBranchId");


CREATE INDEX "IX_SubscriptionPayments_BusinessId" ON "SubscriptionPayments" ("BusinessId");


CREATE INDEX "IX_Suppliers_BusinessId" ON "Suppliers" ("BusinessId");


CREATE INDEX "IX_SyncLogs_BusinessId" ON "SyncLogs" ("BusinessId");


CREATE INDEX "IX_Users_BranchId" ON "Users" ("BranchId");


CREATE INDEX "IX_Users_BusinessId" ON "Users" ("BusinessId");


