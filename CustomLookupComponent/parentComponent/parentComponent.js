import { LightningElement, track, api } from 'lwc';

export default class CustomLookup extends LightningElement {
   handleCustomerSelected(event) {
        try {
            let account = event.detail.length ? event.detail[0] : null;
            if (account) {
                let isEmail = account.hasOwnProperty('subtitle');
                let arr = {
                    label: `${account.title} (${((isEmail && account.subtitle != null) ? account.subtitle : 'N/A')})`,
                    value: account.subtitle,
                    lender: account.title,
                    uId: window.performance.now(),
                    recordId: account.id,
                    isChecked: isEmail,
                    isDisabled: !isEmail,
                    isNewRecord: true,
                    status: 'Submitted',
                    submissionStatus: null
                }
                let duplicateChecker = this.emailAddress.filter(item => {
                    return item.value == account.subtitle;
                });
                if (!duplicateChecker.length) {
                    this.emailAddress = [...this.emailAddress, arr];
                }
                this.template.querySelector('c-application-custom-lookup').removeSelection();
                this.notifyParentComponent();
            }
        }
        catch (e) {
            console.log('OUTPUT : ', e);
        }
    }
}