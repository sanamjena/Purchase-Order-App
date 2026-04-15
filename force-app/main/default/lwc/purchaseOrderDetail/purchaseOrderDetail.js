import { LightningElement, api } from 'lwc';

export default class PurchaseOrderDetail extends LightningElement {
    @api purchaseOrder;

    get lineItems() {
        return this.purchaseOrder ? this.purchaseOrder.lineItems : [];
    }
}