import { LightningElement, track } from 'lwc';
import getPurchaseOrders from '@salesforce/apex/PurchaseOrderController.getPurchaseOrders';

export default class PurchaseOrderList extends LightningElement {
    @track purchaseOrders = [];
    @track sortedPurchaseOrders = [];
    @track error;
    @track searchKey = '';

    connectedCallback() {
        this.fetchPurchaseOrders();
    }

    fetchPurchaseOrders() {
        getPurchaseOrders()
            .then(result => {
                this.purchaseOrders = result;
                this.sortedPurchaseOrders = result;
            })
            .catch(error => {
                this.error = error;
                this.purchaseOrders = [];
            });
    }

    handleSearchKey(event) {
        this.searchKey = event.target.value;
        this.filterPurchaseOrders();
    }

    filterPurchaseOrders() {
        const searchKey = this.searchKey.toLowerCase();
        this.sortedPurchaseOrders = this.purchaseOrders.filter(order => {
            return order.Name.toLowerCase().includes(searchKey);
        });
    }

    sortPurchaseOrders(field, order) {
        const dir = order === 'asc' ? 1 : -1;
        this.sortedPurchaseOrders.sort((a, b) => {
            return dir * (a[field] > b[field] ? 1 : -1);
        });
    }
}