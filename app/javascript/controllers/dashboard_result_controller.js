import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dashboard-result"

export default class extends Controller {
    
    static targets = ['dataPercentage', 'dataFraction', 'measureId', 'measureName', 'measurePeriod', 'measureDescription', 'initialPatientProp', 'numerator', 'denominator', 'exclusions', 'exceptions', 'resultsFilterProviders', 'providerNpi', 'providerTin', 'providerType', 'providerAddress', 'patientPayer', 'patientAge', 'patientAgeFrom', 'patientGender', 'patientRace', 'patientEthnicity', 'patientProblems', 'teamName'];

    providerId = null;

    measureHqmfId = null;

    startDate = null;

    endDate = null;

    measureIdResult = null;

    measureId = null;

    populationCriteria = 'ipp';

    cms_id = null;

    connect() {

        var filterPreference = JSON.parse(localStorage.getItem("filterPreference"));

        this.filterPreference = filterPreference;

        console.log(window.serverData)

        this.loadDataCurrentUser();

        this.extractDataFromURL();

        this.loadMeasureDetails(this.measureHqmfId);

        this.isResetFilterButtonActive();

        this.loadUserData();

    };

    drawPercentageCircle(canvasId, percentage) {

        const canvas = document.getElementById(canvasId);

        const ctx = canvas.getContext("2d");

        const centerX = canvas.width / 2;

        const centerY = canvas.height / 2;

        const radius = canvas.width / 2 - 5;

        const lineWidth = 10;

        const startAngle = -Math.PI / 2;

        const endAngle = startAngle + (percentage / 100) * 2 * Math.PI;

        const animationDuration = 1000;

        const startTime = performance.now();

        const animate = (currentTime) => {

            ctx.clearRect(0, 0, canvas.width, canvas.height);

            const elapsedTime = currentTime - startTime;

            const animationProgress = Math.min(elapsedTime / animationDuration, 1);

            const currentAngle = startAngle + animationProgress * (endAngle - startAngle);

            ctx.strokeStyle = "#3498db";

            ctx.lineWidth = lineWidth;

            ctx.beginPath();

            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);

            ctx.stroke();

            ctx.strokeStyle = "#2ecc71";

            ctx.beginPath();

            ctx.arc(centerX, centerY, radius, startAngle, currentAngle);

            ctx.stroke();

            ctx.fillStyle = "#000";

            ctx.font = "bold 20px Arial";

            ctx.textAlign = "center";

            ctx.textBaseline = "middle";

            ctx.fillText(percentage + "%", centerX, centerY);

            if (elapsedTime < animationDuration) {

                requestAnimationFrame(animate);
            }
        };

        requestAnimationFrame(animate);
    };

    extractDataFromURL(){

        const currentUrl = new URL(window.location.href);

        const buttonBackDashboard = document.getElementById('btnBackToDashboard');

        this.measureHqmfId = currentUrl.pathname.split('/').pop();

        const params = currentUrl.searchParams;

        this.providerId = params.get('providerId');

        this.startDate = parseInt(params.get('startDate'), 10);

        this.endDate = parseInt(params.get('endDate'), 10);

        buttonBackDashboard.href = `/dashboard/${this.providerId}`;

        console.log(this.measureHqmfId, this.providerId, this.startDate, this.endDate);

        this.checkAutho();

        //this.submitQueryCalculate(this.measureHqmfId, this.providerId, this.startDate, this.endDate);

    };

    checkAutho() {

        fetch(`/home/check_authorization/?id=${this.providerId}`)

            .then(response => {

                if (response.ok) {

                    return response.json();

                } else {

                    console.log('false')

                }
            })
            .then(data => {

            })

            .catch(error => {

                console.error(error)

            });

        let listOfMeasure = JSON.parse(localStorage.getItem('tableData'))

        for (let i = 0; i < listOfMeasure.length; i++) {

            let element = listOfMeasure[i];

            if (element.measureId === this.measureHqmfId) {

                this.submitQueryCalculate(element.measureId, element.providers, element.startDate, element.endDate);
            }

        }

    };

    async submitQueryCalculate(measureId, providerId, startDate, endDate) {

        this.showLoadingMessage();

        try {

            const url = '/api/queries';

            const requestData = {

                measure_id: measureId,
                effective_date: endDate,
                effective_start_date: startDate,
                patient_results: [],
                providers: [providerId]

            };

            const options = {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
                },
                body: JSON.stringify(requestData)
            };

            const response = await fetch(url, options);

            if (response.ok) {

                console.log(response)

                const responseData = await response.json();

                this.setQualityMetrics(responseData);

                this.measureIdResult = responseData._id;

                this.buildMeasureFilters([
                    { name: 'Initial Patient Pop.', value: responseData.IPP, code: 'ipp' },
                    { name: 'Numerator', value: responseData.NUMER, code: 'numer' },
                    { name: 'Denominator', value: responseData.DENOM, code: 'denom' },
                    { name: 'Exclusions', value: responseData.DENEX, code: 'denex' },
                    { name: 'Exceptions', value: responseData.DENEXCEP, code: 'denexcep' }
                ]);

                

                this.loadPatients(this.populationCriteria);

                this.hideLoadingMessage();

                //this.setDataMeasureFilter(responseData.IPP, responseData.NUMER,responseData.DENOM, responseData.DENEX)

            } else {

                console.error(response.statusText)
            }

        } catch (error) {

            console.error(error)

        }
    };

    extractDataFilterProvider(event) {

        event.preventDefault();

        const npis = Array.from(this.providerNpiTarget.selectedOptions).map(option => {
            return {
                id: option.value,
                text: option.text,
                code: option.title || ''
            }
        });

        const tinSelectedOptions = Array.from(this.providerTinTarget.selectedOptions).map(option => {
            return {
                id: option.value,
                text: option.text,
                code: option.title || ''
            }
        });

        const providerTypeTags = Array.from(this.providerTypeTarget.selectedOptions).map(option => {
            return {
                id: option.value,
                text: option.text,
                code: option.title || ''
            }
        });

        const addresses = Array.from(this.providerAddressTarget.selectedOptions).map(option => {
            return {
                id: option.value,
                text: option.text,
                code: option.title || ''
            }
        });

        const allOptions = {
            npis,
            tinSelectedOptions,
            providerTypeTags,
            addresses
        };

        const filteredOptions = Object.fromEntries(
            Object.entries(allOptions).filter(([key, value]) => {
                if (Array.isArray(value)) {
                    return value.length > 0;
                } else {
                    return value !== '';
                }
            })
        );

        Swal.fire({

            title: "Apply Provider Filters",
            text: "This will apply the selected provider filters. Do you want to proceed?",
            icon: "info",
            showCancelButton: true,
            confirmButtonColor: "#3085d6",
            cancelButtonColor: "#d33",
            confirmButtonText: "Yes, apply filters"

        }).then((result) => {
            if (result.isConfirmed) {

                try {

                    Swal.fire({

                        title: "Filters Applied!",
                        text: "The provider filters have been successfully applied.",
                        icon: "success",
                        timer: 2000,
                        timerProgressBar: true

                    });

                    setTimeout(() => {

                        const providerModalElement = $('#providerFilterModal');

                        providerModalElement.modal('hide');

                        this.applyFilterProvider(filteredOptions);

                    }, 2000);

                } catch (error) {

                    console.error(error);

                }

            }

        })

    };

    async applyFilterProvider(filters) {

        try {

            const url = `/api/queries/${this.measureId}/filter`;

            const formData = new URLSearchParams();

            for (const [key, value] of Object.entries(filters)) {

                if (Array.isArray(value)) {

                    value.forEach((item, index) => {

                        Object.entries(item).forEach(([subKey, subValue]) => {

                            formData.append(`${key}[${index}][${subKey}]`, subValue);

                        });

                    });

                } else {

                    formData.append(key, value);

                }

            };

            const options = {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                    'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
                },
                body: formData.toString()
            };

            const response = await fetch(url, options);

            if (response.status === 302) {

                console.log('Status 302 - Redirection');

            } else if (response.ok) {

                console.log('OK');

            } else {

                console.error(response.statusText);
            }

        } catch (error) {

            console.error(error);

        } finally {

            this.activateResetFilterButton();

            window.location.reload();

        }


    }

    extractDataFilterPatients(event) {

        event.preventDefault();

        const payers = Array.from(this.patientPayerTarget.selectedOptions).map(option => {
            return {
                id: option.value,
                text: option.title,
                code: option.title || ''
            }

        });

        const age = Array.from(this.patientAgeTarget.selectedOptions).map(option => option.value);

        const asOf = [this.patientAgeFromTarget.value];

        const genders = Array.from(this.patientGenderTarget.selectedOptions).map(option => option.value);

        const races = Array.from(this.patientRaceTarget.selectedOptions).map(option => {
            return {
                id: option.value,
                text: option.text,
                code: option.title || ''
            }   
        });

        const ethnicities = Array.from(this.patientEthnicityTarget.selectedOptions).map(option => {
            return {
                id: option.value,
                text: option.text,
                code: option.title || ''
            }
        });

        const problems = Array.from(this.patientProblemsTarget.selectedOptions).map(option => {
            return {
                id: option.value,
                text: option.text,
                code: option.code || ''
            }
        });

        const default_provider_id = this.providerId;

        const allOptions = {
            payers,
            age,
            asOf,
            genders,
            races,
            ethnicities,
            problems,
            default_provider_id

        };

        const filteredOptions = Object.fromEntries(
            Object.entries(allOptions).filter(([key, value]) => {
                if(Array.isArray(value)) {
                    return value.length > 0;
                } else {
                    return value !== '';
                }
            })
        );

        Swal.fire({

            title: "Apply Patient Filters",
            text: "This will apply the selected patient filters. Do you want to proceed?",
            icon: "info",
            showCancelButton: true,
            confirmButtonColor: "#3085d6",
            cancelButtonColor: "#d33",
            confirmButtonText: "Yes, apply filters"

        }).then((result) => {
            if (result.isConfirmed) {

                try {

                    Swal.fire({

                        title: "Filters Applied!",
                        text: "The patient filters have been successfully applied.",
                        icon: "success",
                        timer: 2000,
                        timerProgressBar: true

                    });

                    setTimeout(() => {

                        const patientModalElement = $('#patientsFilterModal');

                        patientModalElement.modal('hide');

                        localStorage.setItem("filterPreference", JSON.stringify(filteredOptions));

                        this.applyFilterPatient(filteredOptions);

                        console.log(filteredOptions)

                    }, 2000);

                } catch (error) {

                    console.error(error);

                }

            }

        })


    };

    async applyFilterPatient(filters) {

        try {

            const url = `/api/queries/${this.measureId}/filter`;

            const formData = new URLSearchParams();

            for (const [key, value] of Object.entries(filters)) {

                if (Array.isArray(value)) {

                    if(key === 'age') {

                        if(!Array.isArray(value)) {
                            value = [value];
                        }

                        formData.append(`${key}[]`, value.map(age => `${age}×`).join(''));

                    } else if(key === 'asOf' || key === 'genders') {

                        if(!Array.isArray(value)) {

                            value = [value]
                        }

                        formData.append(`${key}[]`, value.join(','));

                    }else {

                        value.forEach((item, index) => {

                            Object.entries(item).forEach(([subKey, subValue]) => {

                                formData.append(`${key}[${index}][${subKey}]`, subValue);

                            });

                        });
                    }

                } else {

                    formData.append(key, value);

                }

            };


            const options = {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                    'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
                },
                body: formData.toString()
            };

            const response = await fetch(url, options);

            if (response.status === 302) {

                console.log('Status 302 - Redirection');

            } else if (response.ok) {

                console.log('OK');

            } else {

                console.error(response.statusText);
            }

        } catch (error) {

            console.error(error);

        } finally {

            this.activateResetFilterButton();

            window.location.reload();

        }
    };

    /*

    async applyFilterProvider(filters){

        try {
            
            const url = `/api/queries/${this.measureId}/filter`;

            const options = {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
                },
                body: JSON.stringify(filters)
            };

            const response = await fetch(url, options);

            if(response.status === 302) {
                console.log('Status 302 - Redirection');
            } else if(response.ok) {
                console.log('OK');
            }else {
                console.error(response.statusText)
            }


        } catch (error) {
            console.error
            
        }

    };

    */


    /*    
    setQualityMetrics(dataResult) {

        let denominator = dataResult.DENEX !== null ? (parseInt(dataResult.DENOM) - parseInt(dataResult.DENEX)) : parseInt(dataResult.DENOM);

        denominator = dataResult.DENEXCEP !== null ? (denominator - parseInt(dataResult.DENEXCEP)) : denominator;

        const numerator = dataResult.NUMER;

        const percentage = (numerator / denominator) * 100;

        this.drawPercentageCircle('canvasQualityMetrics', percentage.toFixed(2))

        this.dataFractionTarget.textContent = `${numerator}/${denominator}`

    };
    */

    setQualityMetrics(dataResult) {

        let denominator = dataResult.DENEX !== null ? (parseInt(dataResult.DENOM) - parseInt(dataResult.DENEX)) : parseInt(dataResult.DENOM);

        denominator = dataResult.DENEXCEP !== null ? (denominator - parseInt(dataResult.DENEXCEP)) : denominator;

        const numerator = dataResult.NUMER;

        const percentage = (numerator / denominator) * 100;

        this.drawPercentageCircle('canvasQualityMetrics', percentage.toFixed(2))

        const numeratorTarget = document.querySelector('[data-dashboard-result-target="numerator"]');

        const denominatorTarget = document.querySelector('[data-dashboard-result-target="denominator"]');

        numeratorTarget.textContent = numerator;

        denominatorTarget.textContent = denominator;
        
    };

    buildMeasureFilters(filterData) {

        const filterList = document.querySelector('.ul-measure');

        filterList.innerHTML = '';

        filterData.forEach((filter) => {

            if(filter.value && parseInt(filter.value) > 0) {

                const listItem = document.createElement('li');

                listItem.classList.add('list-inside');

                const button = document.createElement('button');
                
                button.classList.add('nav-link', 'nav-link-inside');

                const buttonId = `btn-${filter.code}`;

                button.id = buttonId;

                const filterName = document.createTextNode(filter.name + ' ');

                const filterValue = document.createElement('span');

                filterValue.textContent = filter.value;

                filterValue.style.fontWeight = 'bold';

                filterValue.classList.add('pull-right');

                button.appendChild(filterName);

                button.appendChild(filterValue);

                listItem.appendChild(button);

                filterList.appendChild(listItem);

                button.setAttribute('data-action', 'click->dashboard-result#setDataPopulation')

            };
    
        });
    };

    /*
    setDataMeasureFilter(initialPatientProp, numerator, denominator, exclusions, exceptions) {

        this.initialPatientPropTarget.textContent = `${initialPatientProp}`;

        this.numeratorTarget.textContent = `${numerator}`;

        this.denominatorTarget.textContent = `${denominator}`;

        this.exclusionsTarget.textContent = `${exclusions}`;

        this.exceptionsTarget.textContent = `${exceptions}`;

    };
    */

    async loadMeasureDetails(measureHqmfId) {

        try {

            const response = await fetch(`/api/measures/${measureHqmfId}`);

            if(response.ok) {

                const data = await response.json();

                this.measureId = data.hqmf_id;

                this.cms_id = data.cms_id;

                this.setDataMeasure(data.cms_id, data.title, data.created_at, data.description);

            } else {

                console.log('Error');
            }

        } catch (error) {

            console.error(error)
            
        }


    };

    setDataMeasure(measureId, measureName, measurePeriod, measureDescription) {

        const createdYear = new Date(measurePeriod).getFullYear();

        this.measureIdTarget.textContent = `${measureId}`;

        this.measureNameTarget.textContent = `${measureName}`;

        this.measurePeriodTarget.textContent = `${createdYear}`;

        this.measureDescriptionTarget.textContent = `${measureDescription}`;

    };

    async setDataPopulation(event) {

        event.preventDefault();

        const button = event.target.id;

        const buttonId = button.replace('btn-','');

        this.populationCriteria = buttonId;

        this.loadPatients(this.populationCriteria);

    }

    async loadPatients(populationCriteria) {

        const population = populationCriteria;

        try {
            
            const response = await fetch(`/api/queries/${this.measureIdResult}/patient_results?${population}=true&provider_id=${this.providerId}`);

            if(response.ok) {

                const data = await response.json();

                const dataCount = Object.keys(data).length;

                const dataCountSpan = document.getElementById('patients-count');

                dataCountSpan.textContent = `${dataCount}`; 

                this.setDataPatients(data, population)

                console.log(data)

            } else {

                console.log('Error');

            }

        } catch (error) {

            console.error(error);
            
        };


    };

    setDataPatients(dataPatients, population) {

        const patientsTable = document.getElementById('patientResult');

        const buttonsInPopulationCriteria = document.querySelectorAll('.population-criteria button');

        buttonsInPopulationCriteria.forEach(button => {

            button.classList.remove('active');

            button.disabled = false;

        });

        const patientPopulation = document.getElementById(`btn-${population}`);

        patientPopulation.classList.add('active');

        patientPopulation.disabled = true;

        patientsTable.innerHTML = '';

        dataPatients.forEach(patient => {

            const idLink = document.createElement('a');

            const row = patientsTable.insertRow();

            const id = row.insertCell(0)

            const lastName = row.insertCell(1);

            const firstName = row.insertCell(2);

            const age = row.insertCell(3);

            const dob = row.insertCell(4);

            const gender = row.insertCell(5);

            const test = row.insertCell(6);

            const agePatient = this.calculateAgePatients(patient.extendedData.DOB);

            const formatedDOB = this.formatDOB(patient.extendedData.DOB);

            idLink.href = `patient-details/${patient.patient_id}`;

            idLink.textContent = `${patient._id}`;

            idLink.classList.add("pointer-link", "patient-link");

            id.appendChild(idLink);

            //id.innerHTML = `<a>${patient._id}</a>`;

            //id.href = `dashboard/${patient._id}`;

            //id.classList.add("pointer-link");

            firstName.textContent = patient.extendedData.first;

            lastName.textContent = patient.extendedData.last;

            age.textContent = agePatient;

            dob.textContent = formatedDOB;

            gender.textContent = patient.extendedData.gender;

            test.textContent = 'TEST';

        })

    };

    calculateAgePatients(dob) {

        const birthDate = new Date(dob.year, dob.month - 1, dob.day)

        const currentDate = new Date();

        let age = currentDate.getFullYear() - birthDate.getFullYear();

        const monthDiff = currentDate.getMonth() - birthDate.getMonth();

        if (monthDiff < 0 || (monthDiff === 0 && currentDate.getDate() < birthDate.getDate())) {
            age--;
        }

        return age;

    };

    formatDOB(dob) {

        const formattedDate = `${dob.month}/${dob.day}/${dob.year}`;

        return formattedDate;
    };

    showLoadingMessage() {

        document.getElementById('loading-overlay').style.display = 'flex';

    };

    hideLoadingMessage() {

        document.getElementById('loading-overlay').style.display = 'none';

    };

    async clearProviderAndPatientFilter(event) {

        event.preventDefault();

        const result = await Swal.fire({
            title: "Are you sure?",
            text: "This will clear all patient/provider filters. Do you want to proceed?",
            icon: "warning",
            showCancelButton: true,
            confirmButtonColor: "#3085d6",
            cancelButtonColor: "#d33",
            confirmButtonText: "Yes, clear filters"
        });

        if (result.isConfirmed) {

            const default_provider_id = this.providerId;

            try {
                const url = `/api/queries/${this.measureId}/clearfilters`;

                const formData = new URLSearchParams();

                formData.append('default_provider_id', default_provider_id);

                const options = {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
                    },
                    body: formData.toString()
                };

                const response = await fetch(url, options);

                if (response.status === 204) {

                    Swal.fire({

                        title: "Filters cleared!",
                        text: "All patient/provider filters have been cleared.",
                        icon: "success",
                        timer: 2000,
                        timerProgressBar: true
                    });

                    localStorage.removeItem("filterPreference");

                } else {

                    console.error(response.statusText);

                    Swal.fire({
                        title: "Error",
                        text: "Unable to delete the file. Please try again.",
                        icon: "error",
                        timer: 5000,
                        timerProgressBar: true
                    });
                }
            } catch (error) {

                console.error(error);

                Swal.fire({

                    title: "Error",
                    text: "An unexpected error occurred. Please try again.",
                    icon: "error",
                    timer: 5000,
                    timerProgressBar: true
                });

            } finally {

                this.deactivateResetFilterButton();

                setTimeout(() => {
                    
                    window.location.reload();

                }, 2000);
            }
        }




        /*

        const confirmation = window.confirm("Are you sure you want to clear all patient/provider filters?");

        if(!confirmation) {

            return;

        };

        const default_provider_id = this.providerId;

        try {

            const url = `/api/queries/${this.measureId}/clearfilters`;

            const formData = new URLSearchParams();

            formData.append('default_provider_id', default_provider_id);

            const options = {
                
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                    'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
                },
                body: formData.toString()
            }

            const response = await fetch(url, options);

            if (response.status === 204) {

                console.log('Status 204');

            } else if (response.ok) {

                console.log('OK');

            } else {

                console.error(response.statusText);
            }
            
        } catch (error) {

            console.error(error);
            
        } finally {

            window.location.reload();


        }

        */





        
    };

    isResetFilterButtonActive() {

        const value = sessionStorage.getItem('isButtonDisabled');

        const statusButton = JSON.parse(value);

        const button = document.getElementById('resetFilterButton');

        if (statusButton === false) {

            button.disabled = false;

        }
    }

    activateResetFilterButton() {

        const isButtonDisabled = false;

        sessionStorage.setItem('isButtonDisabled', isButtonDisabled.toString());

    };

    deactivateResetFilterButton() {

        const isButtonDisabled = true;

        sessionStorage.setItem('isButtonDisabled', isButtonDisabled.toString());

    };

    loadDataCurrentUser() {

        const button = document.getElementById('resetFilterButton')

        const storageData = window.serverData;

        if (storageData) {

            const currentUser = storageData.currentUser;

            const filters = currentUser.preferences.c4filters;

            if(filters && filters.length > 0) {

                this.addFilterList(filters);

                button.disabled = false;

            }
        }

    };
    
    addFilterList(filterNames) {

        const container = document.getElementById('filter-container');

        const headerFilter = document.createElement('p');

        headerFilter.textContent = 'Filters:';

        container.appendChild(headerFilter);

        const containerList = document.createElement('div');

        containerList.id = 'filter-content';

        const uniqueValues = Array.from(new Set(filterNames));

        uniqueValues.forEach(filterName => {

            const label = document.createElement('label');

            label.textContent = `#${filterName}`;

            label.classList.add('filter-label');

            containerList.appendChild(label);

        });

        container.appendChild(containerList);
    };

    generateReportPatients(event) {

        let fName = '/api/reports/';

        const reportId = event.target.getAttribute("data-report-patient-id");

        if(reportId == 1) {


        } else if(reportId == 2) {


        } else if(reportId == 3) {


        } else if(reportId == 4) {


        } else if(reportId == 5) {


        } else if (reportId == 6) {

            fName += 'cat1.zip/';

            fName = this.endDate ? (fName += `?effective_date=${this.endDate}`) : fName;
            
            fName = this.startDate ? (fName += `&effective_start_date=${this.startDate}`) : fName;

            fName = this.providerId ? (fName += `&provider_id=${this.providerId}`) : fName;

            fName = this.measureHqmfId ? (fName += `&id=${this.measureHqmfId}`) : fName;

            fName += '&patient_type=IPP';

            fName = this.cms_id ? (fName += `&cmsid=${this.cms_id}`) : fName;

            this.downloadReportZIP(fName);

        };

    };

    /*
    
    async downloadReportZIP(dataReport) {

        try {

            const response = await fetch(`${dataReport}`);

            if (response.ok) {

                const zipReport = await response.blob();

                const linkZip = document.createElement('a');

                linkZip.href = window.URL.createObjectURL(zipReport);

                linkZip.download = `report_patient.zip`;

                document.body.appendChild(linkZip);

                linkZip.click();

                document.body.removeChild(linkZip);

            } else {

                console.log('error')
            }

        } catch (error) {

            console.log(error)

        }

    }
    */

    async downloadReportZIP(dataReport) {

        const button = document.getElementById("exportButtonPatients");

        const originalContent = button.innerHTML;
        
        button.textContent = 'Downloading...'
        
        button.disabled = true;
        
        try {

            const response = await fetch(`${dataReport}`);

            if (response.ok) {

                const zipReport = await response.blob();

                const linkZip = document.createElement('a');

                linkZip.href = window.URL.createObjectURL(zipReport);

                linkZip.download = `report_patient.zip`;

                document.body.appendChild(linkZip);

                linkZip.click();

                document.body.removeChild(linkZip);

                button.innerHTML = originalContent;

                button.disabled = false;

            } else {

                console.log('Error');
            }
        } catch (error) {

            console.log('Error', error);

            button.innerHTML = originalContent;

            button.disabled = false;

        }
    }

    async loadUserData() {

        try {

            const response = await fetch('/api/admin/users');

            if (response.ok) {

                const data = await response.json();

                data.forEach(user => {

                    this.setTeamProvider(user.team_ids[0])

                })

            } else {

                console.log(error);
            }

        } catch (error) {

            console.error(error)

        }

    };

    async setTeamProvider(teamId) {

        try {

            const response = await fetch(`/teams/show_by_id/${teamId}`);

            if (response.ok) {

                const data = await response.json();

                this.teamNameTarget.textContent = `${data.name}`

                console.log(data)

            } else {

                console.log('error')
            }



        } catch (error) {

            console.error(error)

        }




    }


}
