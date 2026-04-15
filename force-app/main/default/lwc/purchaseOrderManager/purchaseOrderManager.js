import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPurchaseOrders from '@salesforce/apex/PurchaseOrderController.getPurchaseOrders';
import savePurchaseOrder from '@salesforce/apex/PurchaseOrderController.savePurchaseOrder';
import saveLineItem from '@salesforce/apex/PurchaseOrderController.saveLineItem';
import submitForApproval from '@salesforce/apex/PurchaseOrderController.submitForApproval';
import setApprovalDecision from '@salesforce/apex/PurchaseOrderController.setApprovalDecision';

const STATUS_OPTIONS = [
    'Draft','Submitted','Approved','Rejected','Ordered','Partially Received','Received','Closed','Cancelled'
].map(value => ({ label: value, value }));

const PRIORITY_OPTIONS = ['Low', 'Medium', 'High', 'Critical'].map(value => ({ label: value, value }));

export default class PurchaseOrderManager extends LightningElement {
    @track orders = [];
    @track draft = { Status__c: 'Draft', Priority__c: 'Medium', Approval_Status__c: 'Not Submitted' };
    @track draftLine = {};
    selectedOrderId;

    columns = [
        { label: 'PO #', fieldName: 'Name' },
        { label: 'Supplier', fieldName: 'Supplier_Name__c' },
        { label: 'Department', fieldName: 'Department__c' },
        { label: 'Priority', fieldName: 'Priority__c' },
        { label: 'Approval', fieldName: 'Approval_Status__c' },
        { label: 'Status', fieldName: 'Status__c' },
        { label: 'Budget', fieldName: 'Budget_Amount__c', type: 'currency' },
        { label: 'Remaining', fieldName: 'Remaining_Budget__c', type: 'currency' },
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

    get priorityOptions() {
        return PRIORITY_OPTIONS;
    }

    get disableApprovalActions() {
        return !this.selectedOrderId;
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
            this.draft = { Status__c: 'Draft', Priority__c: 'Medium', Approval_Status__c: 'Not Submitted' };
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

    async submitApproval() {
        await this.performApprovalAction('Pending Approval', 'submitted');
    }

    async approveOrder() {
        await this.performApprovalAction('Approved', 'approved');
    }

    async rejectOrder() {
        await this.performApprovalAction('Rejected', 'rejected');
    }

    async performApprovalAction(decision, verb) {
        try {
            if (decision === 'Pending Approval') {
                await submitForApproval({ purchaseOrderId: this.selectedOrderId });
            } else {
                await setApprovalDecision({ purchaseOrderId: this.selectedOrderId, decision });
            }
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: `Purchase order ${verb}.`, variant: 'success' }));
            await this.refreshOrders();
        } catch (error) {
            this.showError(error);
        }
    }

    handleRowAction(event) {
        if (event.detail.action.name === 'select') {
            this.selectedOrderId = event.detail.row.Id;
            this.draft = { ...event.detail.row };
            this.dispatchEvent(new ShowToastEvent({ title: 'Selected', message: `Selected ${event.detail.row.Name}`, variant: 'info' }));
        }
    }

    showError(error) {
        const message = error?.body?.message || error?.message || 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message, variant: 'error' }));
    }
}
