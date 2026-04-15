import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPurchaseOrders from '@salesforce/apex/PurchaseOrderController.getPurchaseOrders';
import savePurchaseOrder from '@salesforce/apex/PurchaseOrderController.savePurchaseOrder';
import saveLineItem from '@salesforce/apex/PurchaseOrderController.saveLineItem';

const STATUS_OPTIONS = [
    'Draft','Submitted','Approved','Rejected','Ordered','Partially Received','Received','Closed','Cancelled'
].map(value => ({ label: value, value }));

export default class PurchaseOrderManager extends LightningElement {
    @track orders = [];
    @track draft = { Status__c: 'Draft' };
    @track draftLine = {};
    selectedOrderId;

    columns = [
        { label: 'PO #', fieldName: 'Name' },
        { label: 'Supplier', fieldName: 'Supplier_Name__c' },
        { label: 'Requester', fieldName: 'Requester__c' },
        { label: 'Status', fieldName: 'Status__c' },
        { label: 'Total', fieldName: 'Total_Amount__c', type: 'currency' },
        {
            type: 'button',
            typeAttributes: { label: 'Select', title: 'Select', name: 'select', variant: 'brand-outline' }
        }
    ];

    connectedCallback() {
        this.refreshOrders();
    }

    get statusOptions() {
        return STATUS_OPTIONS;
    }

    handleInput(event) {
        this.draft = { ...this.draft, [event.target.dataset.field]: event.target.value };
    }

    handleLineInput(event) {
        this.draftLine = { ...this.draftLine, [event.target.dataset.field]: event.target.value };
    }

    async refreshOrders() {
        try {
            this.orders = await getPurchaseOrders();
        } catch (error) {
            this.showError(error);
        }
    }

    async saveOrder() {
        try {
            const saved = await savePurchaseOrder({ purchaseOrder: this.draft });
            this.selectedOrderId = saved.Id;
            this.draftLine = {};
            this.dispatchEvent(new ShowToastEvent({ title: 'Saved', message: `Purchase order ${saved.Name} saved.`, variant: 'success' }));
            this.draft = { Status__c: 'Draft' };
            await this.refreshOrders();
        } catch (error) {
            this.showError(error);
        }
    }

    async saveLine() {
        try {
            const payload = { ...this.draftLine, Purchase_Order__c: this.selectedOrderId };
            await saveLineItem({ lineItem: payload });
            this.dispatchEvent(new ShowToastEvent({ title: 'Saved', message: 'Line item saved.', variant: 'success' }));
            this.draftLine = {};
            await this.refreshOrders();
        } catch (error) {
            this.showError(error);
        }
    }

    handleRowAction(event) {
        if (event.detail.action.name === 'select') {
            this.selectedOrderId = event.detail.row.Id;
            this.dispatchEvent(new ShowToastEvent({ title: 'Selected', message: `Selected ${event.detail.row.Name}`, variant: 'info' }));
        }
    }

    showError(error) {
        const message = error?.body?.message || error?.message || 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message, variant: 'error' }));
    }
}
