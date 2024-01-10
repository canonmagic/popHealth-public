import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="patient-details"
export default class extends Controller {

    static targets = ['fullName', 'patientId', 'gender', 'dob', 'race', 'ethnicity', 'language', 'providers'];

    connect() {

        this.patientId = null;

        this.extracIdFromURL();

    };


    extracIdFromURL() {

        const url = window.location.href;

        const segments = url.split('/');

        const id = segments[segments.length - 1];

        this.patientId = id;

        this.queryPatientData();

    }


    async queryPatientData() {

        try {
            
            const response = await fetch(`/api/patients/${this.patientId}?include_results=true`);

            if(response.ok) {

                const data = await response.json();

                this.setDataPatient(data);

            } else {

               console.log('Error');

            };

        } catch (error) {

            console.error(error);
            
        }

    };


    backToDashboardDetails(event) {

        event.preventDefault();

        window.history.back();

    };

    setDataPatient(dataPatient) {

        const fullName = `${dataPatient.familyName}, ${dataPatient.givenNames[0]}`;

        this.fullNameTarget.textContent = fullName.toUpperCase();

        this.patientIdTarget.textContent = dataPatient._id;

        this.genderTarget.textContent = dataPatient.cache_results[0].extendedData.gender;

        const dob = dataPatient.cache_results[0].extendedData.DOB;

        const formattedDOB = `${dob.year}-${dob.month}-${dob.day}`;

        this.dobTarget.textContent = formattedDOB;

        this.providersTarget.textContent = `${dataPatient.provider_name[0]} (${dataPatient.provider_ids[0]})`;

        //SIN IDEFNTIFICAR

        this.raceTarget.textContent = 'N/A';

        this.ethnicityTarget.textContent = 'N/A';

        this.languageTarget.textContent = 'N/A';

    }


}
