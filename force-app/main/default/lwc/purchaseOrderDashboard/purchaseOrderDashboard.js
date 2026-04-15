import { LightningElement, track } from 'lwc';
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

    get currentMonthAmount() {
        return this.metrics?.currentMonthAmount ?? 0;
    }

    async refresh() {
        this.metrics = await getDashboardMetrics();
    }
}
