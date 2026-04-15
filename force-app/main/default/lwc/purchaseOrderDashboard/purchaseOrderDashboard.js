import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDashboardMetrics from '@salesforce/apex/PurchaseOrderController.getDashboardMetrics';

export default class PurchaseOrderDashboard extends LightningElement {
    @track metrics;

    connectedCallback() {
        this.refresh();
    }

    get openAmount() {
        return this.metrics?.openAmount ?? 0;
    }

    get overdueCount() {
        return this.metrics?.overdueCount ?? 0;
    }

    get pendingApprovalCount() {
        return this.metrics?.pendingApprovalCount ?? 0;
    }

    get overBudgetCount() {
        return this.metrics?.overBudgetCount ?? 0;
    }

    get currentMonthAmount() {
        return this.metrics?.currentMonthAmount ?? 0;
    }

    async refresh() {
        try {
            this.metrics = await getDashboardMetrics();
        } catch (error) {
            const message = error?.body?.message || error?.message || 'Failed to load dashboard metrics.';
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message, variant: 'error' }));
        }
    }
}
