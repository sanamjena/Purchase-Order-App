public with sharing class PurchaseOrderService {
    @TestVisible private static final Set<String> CLOSED_STATUSES = new Set<String>{'Closed', 'Cancelled'};

    public static List<Purchase_Order__c> getPurchaseOrders() {
        return [
            SELECT Id, Name, Supplier_Name__c, Supplier_Email__c, Requester__c, Status__c,
                   Order_Date__c, Expected_Delivery_Date__c, Tax_Amount__c, Shipping_Amount__c,
                   Discount_Amount__c, Subtotal_Amount__c, Total_Amount__c, LastModifiedDate
            FROM Purchase_Order__c
            ORDER BY LastModifiedDate DESC
            LIMIT 200
        ];
    }

    public static List<Purchase_Order_Line__c> getLinesForOrder(Id purchaseOrderId) {
        if (purchaseOrderId == null) {
            return new List<Purchase_Order_Line__c>();
        }
        return [
            SELECT Id, Name, Purchase_Order__c, Product_Name__c, SKU__c, Quantity__c, Unit_Price__c, Line_Total__c
            FROM Purchase_Order_Line__c
            WHERE Purchase_Order__c = :purchaseOrderId
            ORDER BY CreatedDate ASC
        ];
    }

    public static Purchase_Order__c savePurchaseOrder(Purchase_Order__c purchaseOrder) {
        if (purchaseOrder == null) {
            throw new AuraHandledException('Purchase order payload is required.');
        }

        normalizeDefaults(purchaseOrder);
        validateBusinessRules(purchaseOrder);

        if (purchaseOrder.Id == null) {
            if (!Schema.sObjectType.Purchase_Order__c.isCreateable()) {
                throw new AuraHandledException('Insufficient access to create purchase orders.');
            }
            insert purchaseOrder;
        } else {
            if (!Schema.sObjectType.Purchase_Order__c.isUpdateable()) {
                throw new AuraHandledException('Insufficient access to update purchase orders.');
            }
            update purchaseOrder;
        }

        return [
            SELECT Id, Name, Supplier_Name__c, Supplier_Email__c, Requester__c, Status__c,
                   Order_Date__c, Expected_Delivery_Date__c, Tax_Amount__c, Shipping_Amount__c,
                   Discount_Amount__c, Subtotal_Amount__c, Total_Amount__c
            FROM Purchase_Order__c
            WHERE Id = :purchaseOrder.Id
            LIMIT 1
        ];
    }

    public static Purchase_Order_Line__c saveLineItem(Purchase_Order_Line__c lineItem) {
        if (lineItem == null || lineItem.Purchase_Order__c == null) {
            throw new AuraHandledException('Line item with parent purchase order is required.');
        }
        if (lineItem.Quantity__c == null || lineItem.Quantity__c <= 0 ||
            lineItem.Unit_Price__c == null || lineItem.Unit_Price__c < 0) {
            throw new AuraHandledException('Line item quantity must be positive and price must not be negative.');
        }

        if (lineItem.Id == null) {
            if (!Schema.sObjectType.Purchase_Order_Line__c.isCreateable()) {
                throw new AuraHandledException('Insufficient access to create purchase order lines.');
            }
            insert lineItem;
        } else {
            if (!Schema.sObjectType.Purchase_Order_Line__c.isUpdateable()) {
                throw new AuraHandledException('Insufficient access to update purchase order lines.');
            }
            update lineItem;
        }

        return [
            SELECT Id, Name, Purchase_Order__c, Product_Name__c, SKU__c, Quantity__c, Unit_Price__c, Line_Total__c
            FROM Purchase_Order_Line__c
            WHERE Id = :lineItem.Id
            LIMIT 1
        ];
    }

    public static Map<String, Object> getDashboardMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();

        List<AggregateResult> statusAgg = [
            SELECT Status__c status, COUNT(Id) countVal, SUM(Total_Amount__c) totalVal
            FROM Purchase_Order__c
            GROUP BY Status__c
        ];

        Decimal openAmount = 0;
        Integer overdueCount = 0;
        Decimal currentMonthAmount = 0;
        Date firstDay = Date.today().toStartOfMonth();
        Date lastDay = firstDay.addMonths(1).addDays(-1);

        for (AggregateResult row : statusAgg) {
            String status = (String) row.get('status');
            Integer countVal = (Integer) row.get('countVal');
            Decimal totalVal = (Decimal) row.get('totalVal');
            if (totalVal == null) {
                totalVal = 0;
            }

            if (!CLOSED_STATUSES.contains(status)) {
                openAmount += totalVal;
            }

            metrics.put('status_' + status, new Map<String, Object>{
                'count' => countVal,
                'amount' => totalVal
            });
        }

        for (Purchase_Order__c orderRecord : [
            SELECT Id, Status__c, Expected_Delivery_Date__c, Order_Date__c, Total_Amount__c
            FROM Purchase_Order__c
            WHERE Status__c NOT IN :CLOSED_STATUSES
        ]) {
            if (orderRecord.Expected_Delivery_Date__c != null && orderRecord.Expected_Delivery_Date__c < Date.today()) {
                overdueCount++;
            }
            if (orderRecord.Order_Date__c != null && orderRecord.Order_Date__c >= firstDay && orderRecord.Order_Date__c <= lastDay) {
                currentMonthAmount += (orderRecord.Total_Amount__c == null ? 0 : orderRecord.Total_Amount__c);
            }
        }

        metrics.put('openAmount', openAmount);
        metrics.put('overdueCount', overdueCount);
        metrics.put('currentMonthAmount', currentMonthAmount);

        return metrics;
    }

    private static void normalizeDefaults(Purchase_Order__c purchaseOrder) {
        if (String.isBlank(purchaseOrder.Status__c)) {
            purchaseOrder.Status__c = 'Draft';
        }
        if (purchaseOrder.Order_Date__c == null) {
            purchaseOrder.Order_Date__c = Date.today();
        }
    }

    private static void validateBusinessRules(Purchase_Order__c purchaseOrder) {
        if (String.isBlank(purchaseOrder.Supplier_Name__c)) {
            throw new AuraHandledException('Supplier name is required.');
        }
        if (String.isBlank(purchaseOrder.Requester__c)) {
            throw new AuraHandledException('Requester is required.');
        }
        if (purchaseOrder.Expected_Delivery_Date__c != null && purchaseOrder.Order_Date__c != null
            && purchaseOrder.Expected_Delivery_Date__c < purchaseOrder.Order_Date__c) {
            throw new AuraHandledException('Expected delivery date cannot be earlier than order date.');
        }
    }
}
