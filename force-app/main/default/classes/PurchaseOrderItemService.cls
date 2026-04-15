public with sharing class PurchaseOrderItemService {

    // List to hold Purchase Order items
    private List<PurchaseOrderItem> items;

    // Constructor
    public PurchaseOrderItemService() {
        this.items = new List<PurchaseOrderItem>();
    }

    // Method to add a Purchase Order Item
    public void addItem(PurchaseOrderItem item) {
        if (item != null) {
            items.add(item);
        }
    }

    // Method to calculate total cost of all items
    public Decimal calculateTotal() {
        Decimal total = 0;
        for (PurchaseOrderItem item : items) {
            total += item.quantity * item.unitPrice;
        }
        return total;
    }

    // Method to manage inventory
    public void manageInventory(PurchaseOrderItem item, Integer change) {
        // Implement inventory adjustment logic here
        // change can be positive (add stock) or negative (remove stock)
        // Example logic: update inventory based on change
    }
}

// Sample Purchase Order Item class
public class PurchaseOrderItem {
    public String productName;
    public Integer quantity;
    public Decimal unitPrice;

    public PurchaseOrderItem(String productName, Integer quantity, Decimal unitPrice) {
        this.productName = productName;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
    }
}