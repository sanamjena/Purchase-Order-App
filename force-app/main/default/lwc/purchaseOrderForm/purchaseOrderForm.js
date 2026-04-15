import { LightningElement, track } from 'lwc';

export default class PurchaseOrderForm extends LightningElement {
    @track purchaseOrder = {
        orderNumber: '',
        item: '',
        quantity: 0,
        recipient: '',
    };

    handleInputChange(event) {
        const field = event.target.name;
        this.purchaseOrder[field] = event.target.value;
    }

    validateFields() {
        const { orderNumber, item, quantity, recipient } = this.purchaseOrder;
        return orderNumber && item && quantity > 0 && recipient;
    }

    handleSubmit() {
        if (this.validateFields()) {
            console.log('Purchase Order Submitted:', this.purchaseOrder);
            // Here, you would typically call an Apex method to handle the purchase order submission.
        } else {
            console.error('Please fill in all fields correctly.');
        }
    }

    handleReset() {
        this.purchaseOrder = { orderNumber: '', item: '', quantity: 0, recipient: '' };
    }
}