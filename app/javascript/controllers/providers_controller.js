import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="providers"

export default class extends Controller {

    static targets = ['tableBody'];

    connect() {

        this.loadProviders();


    };

    async loadProviders () {

        try {
            
            const response = await fetch('/api/providers');

            if (response.ok) {

                const data = await response.json();

                this.renderTable(data);

                console.log(data)

            } else {

                console.error('error')
            }

        } catch (error) {

            console.error(error)
            
        }


    };

    renderTable(data) {

        const tableBody = this.tableBodyTarget;

        data.forEach(provider => {

            const row = document.createElement('tr');

            row.innerHTML = `
                <td>${provider.npi ? provider.npi : 'N/A'}</td>
                <td>${provider.specialty ? provider.specialty : 'N/A'}</td>
                <td><a href="../dashboard/${provider._id}">${provider.cda_identifiers[0].extension ? provider.cda_identifiers[0].extension : 'N/A'}</a></td>
                <td><a href="../dashboard/${provider._id}">${provider.givenNames[0] && provider.familyName ? provider.familyName + ' ' + provider.givenNames[0] : 'N/A'}<a/></td>
                <td>${provider.tax_id ? provider.tax_id : 'N/A'}</td>
                <td>${provider.phone ? provider.phone : 'N/A'}</td>
                <td>${provider.practiceName ? provider.practiceName : 'N/A' }</td>
            `
            ;

            tableBody.appendChild(row);
            
        });


    }


}
