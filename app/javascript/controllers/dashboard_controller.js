import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dashboard"

export default class extends Controller {

    static targets = ['dataProviderNpi', 'dataProviderSpecialty', 'dataProviderTaxId', 'dataProviderPhone', 'dataProviderTeam', 'dataProviderFullName', 'start', 'end', 'checkBoxSelect', 'dataUserTeam', 'userRole'];

    effectiveStartDate = null;
    
    effectiveEndDate = null;

    cmsId = null;

    providerId = null;

    porcentageMeasureResult = null;

    dataListChecked = []

    async connect() {

        let providerList = await this.queryProviderList();

        if (providerList.length === 0) {

            Swal.fire({
                icon: 'error',
                title: 'Oops...',
                text: 'No providers were found in the PopHealth system.',
                showCancelButton: false,
                confirmButtonText: `<a style="color:white" href="/admin/patients">Load Providers</a>`,
                backdrop: `
                    rgba(0,0,123,0.4)
                    left top
                    no-repeat
                `,
                allowOutsideClick: false,
            });

        } else {

            let providerIds = providerList.map(element => element.id);

            const pathName = window.location.pathname;

            const segmentsName = pathName.split('/');

            if (segmentsName.length > 2 && providerIds.includes(segmentsName[2])) {

                try {

                    this.extractIdFromUrl();

                    this.loadTaxonomy();

                    this.loadUserData();

                    let listElements = document.querySelectorAll('.list-button-click');

                    listElements.forEach(listElement => {

                        listElement.addEventListener('click', () => {

                            listElement.classList.toggle('arrow');

                            let height = 0;

                            let menu = listElement.nextElementSibling;

                            if (menu.clientHeight == "0") {

                                height = menu.scrollHeight;

                            }

                            menu.style.height = `${height}px`

                        })

                    });

                    this.setupTabClickHandlers();

                } catch (error) {

                    console.error('Error during initialization:', error);

                }

            } else {

                let inputOptions = {};

                providerList.forEach(provider => {

                    inputOptions[provider.id] = provider.fullName;
                })

                const { value: providerId } = await Swal.fire({
                    title: "Select a provider",
                    text: "Please select a provider from those loaded in the PopHealth system",
                    input: "select",
                    icon: "info",
                    inputOptions: inputOptions,
                    inputPlaceholder: "Select",
                    showCancelButton: false,
                    backdrop: `
                    rgba(0,0,123,0.4)
                    left top
                    no-repeat
                    `,
                    allowOutsideClick: false,
                    footer: 'Want to add more providers? <a href="/admin/patients">Click here</a>',
                    inputValidator: (value) => {

                        return new Promise((resolve) => {

                            if (value) {

                                resolve();

                            } else {

                                resolve("Please select a provider");

                            }
                        });
                    }
                });

                if (providerId) {

                    let url = `/dashboard/${providerId}`;

                    let selectedProvider = providerList.find(provider => provider.id === providerId);

                    Swal.fire({
                        title: `You selected: ${selectedProvider.fullName}`,
                        icon: 'success',
                        timer: 1500,
                        timerProgressBar: true
                    });

                    setTimeout(() => {

                        window.location.href = url;

                    }, 1500);

                };

            }

        }

    };

    async queryProviderList() {

        let providerList = [];

        try {

            const response = await fetch('/api/providers');

            if (response.ok) {

                let data = await response.json();

                providerList = data.map(provider => {

                    return {
                        id: provider._id,
                        fullName: provider.givenNames ? provider.givenNames.join(' ') + ' ' + provider.familyName : 'N/A'
                    };
                });

            } else {

            }
        } catch (error) {

            console.error(error);

        }

        return providerList;
    };

    async verifyProvider() {

        let providerList = await this.queryProviderList();

        if(providerList.length === 0) {

            Swal.fire({
                icon: 'error',
                title: 'Oops...',
                text: 'No providers were found in the PopHealth system.',
                showCancelButton: false,
                confirmButtonText: `<a style="color:white" href="/admin/patients">Load Providers</a>`,
                backdrop: `
                    rgba(0,0,123,0.4)
                    left top
                    no-repeat
                `,
                allowOutsideClick: false,
            });

        }

        let providerIds = providerList.map(element => element.id);

        const pathName = window.location.pathname;

        const segmentsName = pathName.split('/');

        if (segmentsName.length > 2 && providerIds.includes(segmentsName[2])) {

    
        } else {

            let inputOptions = {};

            providerList.forEach(provider =>  {

                inputOptions[provider.id] = provider.fullName;
            })

            const { value: providerId } = await Swal.fire({
                title: "Select a provider",
                text: "Please select a provider from those loaded in the PopHealth system",
                input: "select",
                icon: "info",
                inputOptions: inputOptions,
                inputPlaceholder: "Select",
                showCancelButton: false,
                backdrop: `
                    rgba(0,0,123,0.4)
                    left top
                    no-repeat
                `,
                allowOutsideClick: false,
                inputValidator: (value) => {

                    return new Promise((resolve) => {

                        if (value) {

                            resolve();

                        } else {

                            resolve("Please select a provider");

                        }
                    });
                }
            });

            if (providerId) {

                let url = `/dashboard/${providerId}`;

                let selectedProvider = providerList.find(provider => provider.id === providerId);

                Swal.fire({
                    title: `You selected: ${selectedProvider.fullName}`,
                    icon: 'success',
                    timer: 1500,
                    timerProgressBar: true
                });

                setTimeout(() => {

                    window.location.href = url;
                    
                }, 1500);

            };

        }

    };

    selectMeasureToExport(event) {

        event.preventDefault();

        let row = event.target.closest('tr');

        let cmsId = row.cells[2].innerText;

        let measureLink = new URL(row.cells[3].querySelector('a').href);

        let measureId = measureLink.pathname.split('/')[3];

        let params = new URLSearchParams(measureLink.search);

        let providerId = params.get('providerId');

        let startDate = params.get('startDate');

        let endDate = params.get('endDate');

        if (event.target.checked) {

            this.dataListChecked.push({

                measureId: measureId,

                providerId: providerId,

                startDate: startDate,

                endDate: endDate,

                cmsId: cmsId,

            });

            
        } else {
            
            this.dataListChecked = this.dataListChecked.filter(item => item.measureId !== measureId);
            
        }
        
        this.verifyButtonExport();

    };

    /*

    v1

    selectAllMeasureToExport(event) {

        event.preventDefault();

        if(event.target.checked) {

            let rows = document.querySelectorAll('tr');

            rows.forEach(row => {

                let checkbox = row.querySelector('input[type="checkbox"]');

                if(checkbox && !checkbox.checked) { 

                    checkbox.checked = true;

                    let cmsId = row.cells[2].innerText;

                    let measureLink = new URL(row.cells[3].querySelector('a').href);

                    let measureId = measureLink.pathname.split('/')[3];

                    let params = new URLSearchParams(measureLink.search);

                    let providerId = params.get('providerId');

                    let startDate = params.get('startDate');

                    let endDate = params.get('endDate');

                    let measureExists = this.dataListChecked.some(item => item.measureId === measureId);

                    if(!measureExists) {

                        this.dataListChecked.push({

                            measureId:measureId,
                            providerId: providerId,
                            startDate: startDate,
                            endDate: endDate,
                            cmsId: cmsId
                        });

                    } 

                    //console.log(this.dataListChecked);

                }
            })


        } else {

            this.dataListChecked = [];

            let checkboxes = document.querySelectorAll('input[type="checkbox"]');

            checkboxes.forEach(checkbox => {

                checkbox.checked = false;

            });
        }



    };

    */

    selectAllMeasureToExport(event) {

        event.preventDefault();

        const selectCheckbox = document.getElementById('selectMeasure');

        if (selectCheckbox.checked) {

            let rows = document.querySelectorAll('tr');

            rows.forEach(row => {

                let checkbox = row.querySelector('input[type="checkbox"]');

                if (checkbox && !checkbox.checked) {

                    checkbox.checked = true;

                    let cmsId = row.cells[2].innerText;

                    let measureLink = new URL(row.cells[3].querySelector('a').href);

                    let measureId = measureLink.pathname.split('/')[3];

                    let params = new URLSearchParams(measureLink.search);

                    let providerId = params.get('providerId');

                    let startDate = params.get('startDate');

                    let endDate = params.get('endDate');

                    let measureExists = this.dataListChecked.some(item => item.measureId === measureId);

                    if (!measureExists) {

                        this.dataListChecked.push({

                            measureId: measureId,
                            providerId: providerId,
                            startDate: startDate,
                            endDate: endDate,
                            cmsId: cmsId
                        });

                    }
                    
                }
            })

        } else {

            this.dataListChecked = [];

            let checkboxes = document.querySelectorAll('input[type="checkbox"]');

            checkboxes.forEach(checkbox => {

                checkbox.checked = false;

            });
        };

        this.verifyButtonExport();

    };

    async setReportinRecord(event) {
        console.log("Set Reporting Record...")

        event.preventDefault();

        const result = await Swal.fire({

            title: "Caution!",
            text: "Changing the reporting period may initially cause a significant delay. Do you wish to continue?",
            icon: "warning",
            showCancelButton: true,
            confirmButtonColor: "#3085d6",
            cancelButtonColor: "#d33",
            confirmButtonText: "Yes, change reporting period"

        });

        if(result.isConfirmed) {

            const startDate = this.element.querySelector('#startDate').value;

            const endDate = this.element.querySelector('#endDate').value;

            const startDateFormat = this.changeDateFormat(startDate);

            const endDateFormat = this.changeDateFormat(endDate);
      
            let listOfMeasure = JSON.parse(localStorage.getItem('tableData'));
            
            for (let x = 0; x < listOfMeasure.length; x++) {
                
                listOfMeasure[x].startDate = this.formatDate(startDateFormat);
                
                listOfMeasure[x].endDate = this.formatDate(endDateFormat);
                
            }
            
            localStorage.setItem('tableData', JSON.stringify(listOfMeasure));
            
            this.queryReportinRecord(startDateFormat, endDateFormat);

        }


    };

    changeDateFormat(date) {

        const dateFormat = date.split('/');

        return `${dateFormat[1]}/${dateFormat[0]}/${dateFormat[2]}`

    };

    async queryReportinRecord(startDate, endDate) {

        try {

            const url = '/dashboard/set_reporting_period';

            const formatData = new URLSearchParams();

            formatData.append('effective_start_date', startDate);

            formatData.append('effective_date', endDate);

            formatData.append('username', 'pophealth');

            const options = {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                    'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
                },
                body: formatData.toString()
            };

            const response = await fetch(url, options);

            if (response.ok) {

                window.location.reload();

            } else {

                console.error(response.statusText)
            }

        } catch (error) {

            console.error(error);

        }


    };

    disabledButtonDateReport() {

        const startDate = this.element.querySelector('#startDate').value;

        const endDate = this.element.querySelector('#endDate').value;

        if(startDate == '' & endDate == '') {

            const resetButton = document.getElementById('resetButton');

            resetButton.disabled = true;

        } else {

            const resetButton = document.getElementById('resetButton');

            resetButton.disabled = false;

        }

    };

    /*

    activateButtonExportReport() {

        const exportButton = document.getElementById('exportButton');

        exportButton.disabled = false;

    };

    */

    deactivateMeasure(measureCmsId){

        const btnMeasure = document.getElementById(`btn-measure-${measureCmsId}`);

        if(btnMeasure) {

            btnMeasure.disabled = true;

        }
        
    };

    activateMeasure(measureCmsId) {

        const btnMeasure = document.getElementById(`btn-measure-${measureCmsId}`);

        if (btnMeasure) {

            btnMeasure.disabled = false;

        }

    };

    verifyButtonExport() {

        const exportButton = document.getElementById('exportButton');

        if (this.dataListChecked.length < 1) {

            exportButton.disabled = true;

        } else {

            exportButton.disabled = false;

        }

    }

    /*

    deactivateButtonExportReport() {

        const exportButton = document.getElementById('exportButton');

        exportButton.disabled = true;

    };

    */

    /*
    V1
    setReportingPeriod(endDateUser, startDateUser) {

        //console.log(endDateUser, startDateUser)

        const startDate = this.element.querySelector('#startDate');

        const endDate = this.element.querySelector('#endDate');

        //Definiendo Reporting Period

        this.effectiveStartDate = startDateUser;

        this.effectiveEndDate = endDateUser;

        //Tranformar a fecha legible

        const startDateDefault = new Date(startDateUser * 1000).toLocaleDateString();

        startDate.value = `${startDateDefault}`;

        const endDateDefault = new Date(endDateUser * 1000 ).toLocaleDateString();

        endDate.value = `${endDateDefault}`;

        //console.log(startDateDefault, endDateDefault);

    };
    */

    setReportingPeriod(endDateUser, startDateUser) {

        const startDate = this.element.querySelector('#startDate');

        const endDate = this.element.querySelector('#endDate');

        //Definiendo Reporting Period

        this.effectiveStartDate = startDateUser;

        this.effectiveEndDate = endDateUser;

        //Tranformar a fecha legible

        const startDateDefault = new Date(startDateUser * 1000).toISOString().slice(0,10).split('-').reverse().join('/');

        startDate.value = `${startDateDefault}`;

        const endDateDefault = new Date(endDateUser * 1000).toISOString().slice(0, 10).split('-').reverse().join('/');

        endDate.value = `${endDateDefault}`;

        this.loadTableData();

    };

    resetReportingPeriod() {

        const userConfirmed = window.confirm('Caution! Changing the reporting period may initially cause a significant delay. Do you wish to continue?');

        if(userConfirmed) {

            this.effectiveEndDate = null;

            this.effectiveStartDate = null;

            const startDate = this.element.querySelector('#startDate');

            const endDate = this.element.querySelector('#endDate');

            startDate.value = '';

            endDate.value = '';

            this.disabledButtonDateReport();

        }

    };

    handleBlur(event) {

        if(event.target === this.startTarget) {

            this.extractStartDate();

        } else if(event.target === this.endTarget) {

            this.extractEndDate();

        }
    };

    extractIdFromUrl() {

        const currentPath = window.location.pathname;

        const segments = currentPath.split('/');

        if(segments.length > 2) {

            this.providerId = segments[2];

            this.loadProviderData(this.providerId);

        } else {


        }
    };

    async loadMeasureDetail(hqmfId) {

        try {
            
            const response = await fetch(`/api/measures/${hqmfId}`);

            if(response.ok) {

                const data = await response.json();

                return data.description;

            } else {

                console.error('error')

            }

        } catch (error) {

            console.error(error)
            
        }

    };

    async loadProviderData(id) {

        try {
            
            const response = await fetch(`/api/providers/${id}`);

            if (response.ok) {

                const data = await response.json();

                this.providerId = data._id;

                this.addDataProvider(data);

            } else {

                console.error('error');

            }

        } catch (error) {

            console.error(error);
            
        }


    };

    addDataProvider(providerData) {

        this.dataProviderNpiTarget.textContent = `${providerData.npi}`;

        this.dataProviderSpecialtyTarget.textContent = `: ${providerData.specialty}`;

        this.dataProviderFullNameTarget.textContent = `${providerData.familyName}, ${providerData.givenNames[0]}`;

    };

    async loadUserData() {

        try {
            
            const response = await fetch('/api/admin/users');

            if (response.ok) {

                const data = await response.json();

                data.forEach(user => {

                    const effectiveEndDate = user.effective_date;

                    const effectiveStartDate = user.effective_start_date;

                    if(user.admin === true) {

                        this.userRoleTarget.textContent = `Provider - Admin`

                    } else if(user.admin === false) {

                        this.userRoleTarget.textContent = `Provider`

                    }

                    this.setTeamProvider(user.team_ids[0])

                    this.setReportingPeriod(effectiveEndDate, effectiveStartDate);

                })

            } else {

            }

        } catch (error) {

            console.error(error)
            
        }

    };

    async setTeamProvider(teamId) {

        try {
            
            const response = await fetch(`/teams/show_by_id/${teamId}`);

            if(response.ok) {

                const data = await response.json();

                this.dataUserTeamTarget.textContent = `${data.name}`

            } else {

            }

            

        } catch (error) {

            console.error(error)
            
        }




    }

    async loadTaxonomy() {

        try {

            const response = await fetch(`/api/providers/search?taxonomy=207Q00000X`);

            if (response.ok) {

                const data = await response.json();


            } else {

            }

        } catch (error) {

            console.error(error)

        }

    };

    addMeasureToTable(cmsId, measureTitle, measureId) {
        const tableBody = document.getElementById('measureResultTable');

        const newRow = tableBody.insertRow(0);

        newRow.id = `data-${measureId}`;

        // REMOVE BUTTON (primera columna):

        const cell1 = newRow.insertCell(0);
        
        cell1.id = "button-options";

        const removeButton = document.createElement("button");

        const icon = document.createElement("span");

        icon.classList.add("glyphicon", "glyphicon-trash");

        removeButton.appendChild(icon);

        removeButton.classList.add("btn", "btn-danger", "btn-xs");

        removeButton.addEventListener("click", () => this.removeRow(newRow));

        cell1.appendChild(removeButton);

        //CHECKBOX:

        const cell0 = newRow.insertCell(1);

        const checkBox = document.createElement("input");

        checkBox.setAttribute("type", "checkbox");

        checkBox.setAttribute("data-action", "change->dashboard#selectMeasureToExport");

        checkBox.setAttribute("data-dashboard-target", "checkBoxSelect")

        cell0.appendChild(checkBox);

        // CMS ID (segunda columna)

        const cell2 = newRow.insertCell(2);

        cell2.style.fontWeight = 'bold';

        cell2.textContent = cmsId;

        // TITLE (tercera columna)

        const cell3 = newRow.insertCell(3);

        const titleLink = document.createElement("a");

        titleLink.href = `/dashboard/measure-result/${measureId}?&providerId=${this.providerId}&startDate=${this.effectiveStartDate}&endDate=${this.effectiveEndDate}`;

        titleLink.id = 'link-to-measure-details'

        titleLink.style.fontWeight = 'bold';

        const measureTitleText = document.createTextNode(measureTitle);

        titleLink.appendChild(measureTitleText);

        cell3.appendChild(titleLink);

        // ICONO CON TOOLTIP ()

        const infoIcon = document.createElement("icon");

        infoIcon.id = `icon-${measureId}`;

        infoIcon.setAttribute("role", "tooltip");

        infoIcon.classList.add("glyphicon", "glyphicon-info-sign", "icon-measure-result");

        infoIcon.setAttribute("data-toggle", "tooltip");

        infoIcon.setAttribute("title", "");

        cell3.appendChild(infoIcon);

        // PORCENTAJE (cuarta columna)
        const cell4 = newRow.insertCell(4);

        //cell4.id = `porcentage-${measureId}`;

        const spinner = this.createSpinnerLoading();

        cell4.appendChild(spinner);

        // NUMERADOR/DENOMINADOR (quinta columna)
        const cell5 = newRow.insertCell(5);

        cell5.id = `numerator-denominator-${measureId}`;

        const spinner2 = this.createSpinnerLoading();

        cell5.appendChild(spinner2);

        //Populations

        const cell6 = newRow.insertCell(6);

        cell6.id = "population-set"

    };

    // addMeasureToTable(cmsId, measureTitle, measureId) {

    //     const tableBody = document.querySelector('tbody');

    //     const newRow = tableBody.insertRow();

    //     //REMOVE

    //     const cell5 = document.createElement("td");

    //     const removeButton = document.createElement("button");

    //     const icon = document.createElement("span");

    //     icon.classList.add("glyphicon", "glyphicon-trash");

    //     removeButton.appendChild(icon);

    //     removeButton.classList.add("btn", "btn-danger");

    //     removeButton.addEventListener("click", () => 
    
    //         this.removeRow(newRow));

    //     cell5.appendChild(removeButton);

    //     //CMS ID

    //     const cell1 = newRow.insertCell(0);

    //     cell1.textContent = cmsId;

    //     //TITLE

    //     const cell2 = newRow.insertCell(1);

    //     const titleLink = document.createElement("a");

    //     //const description = await this.loadMeasureDetail(measureId);

    //     //Option 1:

    //     titleLink.href = `/dashboard/measure-result/${measureId}?&providerId=${this.providerId}&startDate=${this.effectiveStartDate}&endDate=${this.effectiveEndDate}`;
       
    //     const measureTitleText = document.createTextNode(measureTitle);
        
    //     //titleLink.title = description;

    //     titleLink.appendChild(measureTitleText);

    //     cell2.appendChild(titleLink);
        
    //     //Option 2:
        
    //     //titleLink.href = `/dashboard/measure_result/${measureId}/${this.providerId}/${this.effectiveStartDate}/${this.effectiveEndDate}`;
        
    //     //titleLink.innerHTML = `${measureTitle}`;


    //     //PORCENT

    //     const cell3 = newRow.insertCell(2);

    //     const spinner = this.createSpinnerLoading();

    //     cell3.appendChild(spinner);

    //     //NUMERATOR/DENOMINATOR

    //     const cell4 = newRow.insertCell(3);

    //     const spinner2 = this.createSpinnerLoading();

    //     cell4.appendChild(spinner2);


        
    //     //PATIENTS

    //     /*
        
    //     const patientButton = document.createElement("button");
        
    //     patientButton.textContent = "View Patients";

    //     patientButton.classList.add("btn", "btn-primary", "btn-block");
        
    //     patientButton.addEventListener("click", () => this.patientButton());
        
    //     cell5.appendChild(patientButton);
        
        
    //     */
    //     newRow.appendChild(cell5);

    //     //Option 1: add to localStorage

    //     const tableData = JSON.parse(localStorage.getItem('tableData')) || [];

    //     const newRowData = {

    //         cmsId:cmsId,
    //         measureTitle:measureTitle,
    //         measureId: measureId
    //     };

    //     const exists = tableData.some(element => element.measureId === measureId);

    //     if(!exists) {

    //         tableData.push(newRowData);

    //         localStorage.setItem('tableData', JSON.stringify(tableData));

    //     }

    // };

    patientButton() {

        window.location.href = "#"

    };

    removeRow(row) {

        const table = document.querySelector(".table");

        this.activateMeasure(row.cells[2].innerText);

        table.deleteRow(row.rowIndex);

        //this.deactivateButtonExportReport();

        this.removeMeasureFromLocal(row.cells[2].innerText);

    };

    setupTabClickHandlers() {

        const tabs = this.element.querySelectorAll('#tabs-data li a');

        tabs.forEach(tab => {

            tab.addEventListener('click', (event) => {

                event.preventDefault();

                this.showTab(tab);
            })
        })
    };

    showTab(tab) {

        const tabs = this.element.querySelectorAll('#tabs-data li');

        tabs.forEach(t => t.classList.remove('active'));

        tab.classList.add('active');
    };

    extractHqmf(event) {

        this.measureHqmfId = event.target.getAttribute("data-measure-hqmf-id");

        this.cmsId = event.target.getAttribute("data-cms-id");

        const measureTitle = event.target.getAttribute("data-measure-title");
        
        this.addMeasureToLocalStorage(this.cmsId, measureTitle, this.measureHqmfId);

        this.checkAutho(this.providerId);

        this.addMeasureToTable(this.cmsId, measureTitle, this.measureHqmfId);

        this.deactivateMeasure(this.cmsId);

    };

    addMeasureToLocalStorage(cmsId, measureTitle, measureId) {
        console.log("addMeasureToLocalStorage...")

        const tableData = JSON.parse(localStorage.getItem('tableData')) || [];

        const newRowData = {

            cmsId: cmsId,
            measureTitle: measureTitle,
            measureId: measureId,
            startDate: this.effectiveStartDate,
            endDate: this.effectiveEndDate,
            status: 'pending',
            providers: this.providerId,
            onTable: true,

        };

        const exists = tableData.some(element => element.measureId === measureId);

        if (!exists) {

            tableData.push(newRowData);

            localStorage.setItem('tableData', JSON.stringify(tableData));

        };
    }

    extractStartDate() {

        const startDateField = this.startTarget;

        const startDateValue = startDateField.value;

        const startValue = new Date(startDateValue).getTime();

        this.effectiveStartDate = startValue/1000;

        this.disabledButtonDateReport();

    };

    extractEndDate() {

        const endDateField = this.endTarget;

        const endDateValue = endDateField.value;

        const endValue = new Date(endDateValue).getTime();

        this.effectiveEndDate = endValue/1000;

        this.disabledButtonDateReport();

    };

    formatDate(date) {

        const format = (new Date(date).getTime())/1000;

        return format;

    };

    addResultToTable(dataResult, measureIdResult) {

        //Update tooltip-message:

        let icon = document.getElementById(`icon-${measureIdResult}`);

        this.loadMeasureDetail(`${measureIdResult}`)

            .then(iconMsg => {

                icon.setAttribute('title', iconMsg);

            })

            .catch(error => console.error(error));

        //const tableBody = document.getElementById('measureResultTable');

        let targetRowId = `data-${measureIdResult}`;

        const targetRow = document.getElementById(targetRowId);

        if(!targetRow) {

            return;
        }

        //const newRow = tableBody.rows[tableBody.rows.length - 1];

        // NUMERATOR/DENOMINATOR

        let numerator;

        let denominator;

        const populationSetKeys = Object.keys(dataResult).filter(key => key.startsWith('PopulationSet'))

        if (dataResult[`${measureIdResult}`] && dataResult[`${measureIdResult}`]["PopulationSet_1"]) {
            // <!-- Yockler Code 06/12/2024 -->
            denominator = parseInt(dataResult.DENOM)
            denominator = dataResult.DENEX ? (denominator - parseInt(dataResult.DENEX)) : ( denominator ? denominator : 0 );
            denominator = dataResult.DENEXCEP ? (denominator - parseInt(dataResult.DENEXCEP)) : denominator;
            numerator = parseInt(dataResult.NUMER);
            numerator = numerator ? numerator : 0;
        } else if (dataResult["PopulationSet_1"]){

            //añadir && populationSetKeys.length === 1`

            const buttonGroup = document.createElement("div");
            buttonGroup.classList.add("btn-group");

            const mainButton = document.createElement("button");
            mainButton.setAttribute("type", "button");
            mainButton.classList.add("btn", "btn-warning", "dropdown-toggle");
            mainButton.setAttribute("data-toggle", "dropdown");
            mainButton.setAttribute("aria-haspopup", "true");
            mainButton.setAttribute("aria-expanded", "false");
            mainButton.textContent = "Population Set 1 "

            const caretSpan = document.createElement("span");
            caretSpan.classList.add("caret");

            mainButton.appendChild(caretSpan);

            const dropdownMenu = document.createElement("ul");
            dropdownMenu.classList.add("dropdown-menu");
            dropdownMenu.style.left = "50%";
            dropdownMenu.style.transform = "translateX(-50%)";

            populationSetKeys.forEach(name => {

                const dropdownItem = document.createElement("li");

                const dropdownLink = document.createElement("a");

                dropdownLink.setAttribute("href", "#");

                dropdownLink.setAttribute("data-action", "change->dashboard#changePopulation")

                dropdownLink.textContent = name;

                dropdownItem.appendChild(dropdownLink);

                dropdownMenu.appendChild(dropdownItem);

            });

            buttonGroup.appendChild(mainButton);

            buttonGroup.appendChild(dropdownMenu);

            // Establecer margen izquierdo al botón
            buttonGroup.style.marginLeft = "10px";

            // Obtener el elemento td donde deseas agregar el botón
            const td = document.getElementById("population-set");

            // Agregar el botón desplegable al td
            td.appendChild(buttonGroup);
        

            const populationSet = dataResult["PopulationSet_1"];

            // <!-- Yockler Code 06/12/2024 -->
            denominator = parseInt(populationSet.DENOM)
            denominator = populationSet.DENEX ? (denominator - parseInt(populationSet.DENEX)) : ( denominator ? denominator : 0 );
            denominator = populationSet.DENEXCEP ? (denominator - parseInt(populationSet.DENEXCEP)) : denominator;
            numerator = parseInt(populationSet.NUMER);
            numerator = numerator ? numerator : 0;
            
        } else if (populationSetKeys.length > 1) {

            const populationSet = dataResult["PopulationSet_1"];

            // <!-- Yockler Code 06/12/2024 -->
            denominator = parseInt(populationSet.DENOM)
            denominator = populationSet.DENEX ? (denominator - parseInt(populationSet.DENEX)) : ( denominator ? denominator : 0 );
            denominator = populationSet.DENEXCEP ? (denominator - parseInt(populationSet.DENEXCEP)) : denominator;
            numerator = parseInt(populationSet.NUMER);
            numerator = numerator ? numerator : 0;

        }

        
        const cell3 = targetRow.cells[5];

        const numeratorDenominator = document.createElement("div");
        numeratorDenominator.classList.add("fraction");

        const numeratorElement = document.createElement("span");
        numeratorElement.classList.add("numerator");
        numeratorElement.innerHTML = numerator;

        const fractionLine = document.createElement("span");
        fractionLine.classList.add("fraction-line");

        const denominatorElement = document.createElement("span");
        denominatorElement.classList.add("denominator");
        denominatorElement.innerHTML = denominator;

        numeratorDenominator.appendChild(numeratorElement);
        numeratorDenominator.appendChild(fractionLine);
        numeratorDenominator.appendChild(denominatorElement);

        cell3.innerHTML = "";
        cell3.appendChild(numeratorDenominator);

        const porcentage = denominator === 0 ? 0 : (numerator / denominator) * 100;

        this.porcentageMeasureResult = porcentage;

        const cell4 = targetRow.cells[4];

        const porcentCanvas = document.createElement("canvas");

        let porcentageMeasureId = Object.keys(dataResult)[0];

        porcentCanvas.id = `porcentage-${porcentageMeasureId}`;

        porcentCanvas.width = 80;

        porcentCanvas.height = 80;

        cell4.innerHTML = "";

        cell4.appendChild(porcentCanvas);

        this.drawPercentageCircle(porcentCanvas.id, porcentage.toFixed(2));


    };

    changePopulation(event) {

        event.preventDefault();

        let measureIdResult = event.currentTarget.dataset.resultid;

        let populationName = event.currentTarget.dataset.population;

        this.addResultFromLocalStorage(measureIdResult, populationName)

    }

    async submitQueryCalculate(measureId, endDate, startDate, providers) {
        console.log("submitQueryCalculate...")

        try {

            const url = '/api/queries';

            const requestData = {

                measure_id: measureId,
                effective_date: endDate	,
                effective_start_date: startDate,
                patient_results: [],
                providers: [providers]
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

            let reloadPage = true;

            if (response.ok && response.headers.get('Content-Type')?.includes('application/json')) {

                const responseData = await response.json();

                let listOfMeasure = JSON.parse(localStorage.getItem('tableData'))

                for(let x = 0; x < listOfMeasure.length; x++) {

                    if(listOfMeasure[x].providers && listOfMeasure[x].providers === this.providerId) {

                        let measureId = listOfMeasure[x].measureId;

                        let data = responseData[measureId];

                        localStorage.setItem(`${measureId}-responseData`, JSON.stringify(data));

                        listOfMeasure[x].status = 'completed';
                        localStorage.setItem('tableData', JSON.stringify(listOfMeasure));
                        this.addResultFromLocalStorage(measureId);

                    }
                    
                    
                }
                

                //this.activateButtonExportReport();


            } else if(response.status === 200) {

                reloadPage = false;

            } else {

                if(reloadPage) {

                    reloadPage = false;

                    Swal.fire({
                        icon: 'error',
                        title: 'Error',
                        text: 'An error occurred. Do you want to reload the page?',
                        showCancelButton: true,
                        confirmButtonColor: '#3085d6',
                        cancelButtonColor: '#d33',
                        confirmButtonText: 'Reload'
                    }).then((result) => {
                        if (result.isConfirmed) {
                            window.location.reload();
                        }
                    });
                }
            }
            
        } catch (error) {

            console.error(`Console error: ${error}`);

        }
    };

    checkAutho(provider) {
        console.log("Checking Autho")
        fetch(`../home/check_authorization/?id=${this.providerId}`)
            .then(response => {
                if(response.ok)
                    return response.json();
            }).catch(error => {
                console.error(error)
            });

            let listOfMeasure = JSON.parse(localStorage.getItem('tableData'))

            for( let i=0; i < listOfMeasure.length ; i++ ) {
                let element = listOfMeasure[i];

                if( element.providers === provider )
                    this.submitQueryCalculate(element.measureId, element.endDate, element.startDate, this.providerId);
            }
            
    };

    /*

    OLD VERSION
    
    generateReport(event){

        let fName = '/api/reports/'

        const reportId = event.target.getAttribute("data-report-id");

        if (reportId == '1') {

            fName = this.cmsId ? (fName += `${this.cmsId}_qrda_cat3.xml?`) : (fName += 'qrda_cat3.xml?');

            fName = this.effectiveEndDate ? (fName += `effective_date=${this.effectiveEndDate}`) : fName;

            fName = this.providerId ? (fName += `&provider_id=${this.providerId}`) : fName;

            this.downloadReportXML(fName);


        } else if (reportId == '2') {

            fName = this.cmsId ? (fName += `${this.cmsId}_cat1.zip?cmsid=${this.cmsId}`) : (fName += 'cat1.zip');

            fName = this.providerId ? (fName += `&provider_id=${this.providerId}`) : fName;

            this.downloadReportZIP(fName);

            
        }

        
    };

    */
   
    generateReport(event) {

        const reportId = event.target.getAttribute("data-report-id");
        
        if (reportId == '1') {

            for(let n = 0; n < this.dataListChecked.length; n++) {
                
                let fName = '/api/reports/';

                let data = this.dataListChecked[n];

                fName = data.providerId ? (fName += `qrda_cat3.xml?provider_id=${data.providerId}`) : fName;

                fName = data.measureId ? (fName += `&measure_ids[]=${data.measureId}`) : (fName += '&');

                fName = data.endDate ? (fName += `&effective_date=${data.endDate}`) : fName;

                //fName += `&filter_preferences=null` 

                ////console.log(fName)

                this.downloadReportXML(fName, data.cmsId);


            }



        } else if (reportId == '2') {

            for(let n = 0; n < this.dataListChecked.length; n++) {

                let fName = '/api/reports/';

                let data = this.dataListChecked[n];

                fName = data.cmsId ? (fName += `${data.cmsId}_cat1.zip?cmsid=${data.cmsId}`) : (fName += 'cat1.zip');

                fName = data.providerId ? (fName += `&provider_id=${data.providerId}`) : fName;

                this.downloadReportZIP(fName, data.cmsId);
            }

        }


    };

    async downloadReportXML(dataReport, cmsId) {

        try {

            const response = await fetch(`${dataReport}`);

            if(response.ok) {

                const xmlReport = await response.text();

                const xmlBlob = new Blob(
                    [xmlReport],
                    { type : 'application/xml' }
                );

                const linkXml = document.createElement('a');

                linkXml.href = window.URL.createObjectURL(xmlBlob);

                linkXml.download = `${cmsId}_qrda_cat3.xml`;

                document.body.appendChild(linkXml);

                linkXml.click();

                document.body.removeChild(linkXml);

            } else {

                //console.log('Error')
            }

        } catch (error) {

            console.error(error);
            
        }




    };

    async downloadReportZIP(dataReport, measureName) {

        try {
            
            const response = await fetch(`${dataReport}`);

            if(response.ok) {

                const zipReport = await response.blob();

                const linkZip = document.createElement('a');

                linkZip.href = window.URL.createObjectURL(zipReport);

                linkZip.download = `${measureName}_cat1.zip`;

                document.body.appendChild(linkZip);

                linkZip.click();

                document.body.removeChild(linkZip);

            } else {

            }

        } catch (error) {
            
        }

    };

    /*
    drawPercentageCircle(canvasId, percentage) {
        const canvas = document.getElementById(canvasId);
        const ctx = canvas.getContext("2d");

        const centerX = canvas.width / 2;
        const centerY = canvas.height / 2;
        const radius = canvas.width / 2 - 5;
        const lineWidth = 10;

        // Calcula el ángulo para el porcentaje proporcionado (en radianes)
        const angle = (percentage / 100) * 2 * Math.PI;

        // Configura el color del borde del círculo
        ctx.strokeStyle = "#3498db"; // Puedes cambiar el color según tus preferencias

        // Configura el ancho del borde
        ctx.lineWidth = lineWidth; // Puedes ajustar el ancho del borde según tus preferencias

        // Dibuja el borde del círculo
        ctx.beginPath();
        ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
        ctx.stroke();

        // Cambia el color para el sector coloreado según el porcentaje
        ctx.strokeStyle = "#2ecc71"; // Puedes cambiar el color según tus preferencias

        // Dibuja el sector coloreado según el porcentaje
        ctx.beginPath();
        ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + angle);
        ctx.stroke();

        // Configura el estilo del texto en el centro
        ctx.fillStyle = "#000"; // Puedes cambiar el color del texto según tus preferencias
        ctx.font = "bold 20px Arial"; // Puedes ajustar la fuente y el tamaño según tus preferencias
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";

        // Muestra el número en el centro del círculo
        ctx.fillText(percentage + "%", centerX, centerY);
    };
    */

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

            ctx.font = "bold 15px Arial";

            ctx.textAlign = "center";

            ctx.textBaseline = "middle";

            ctx.fillText(percentage + "%", centerX, centerY);

            if (elapsedTime < animationDuration) {
                requestAnimationFrame(animate);
            }
        };

        requestAnimationFrame(animate);
    };

    createSpinnerLoading() {

        const spinner = document.createElement('div');

        spinner.classList.add('spinner');

        return spinner;
    };

    loadTableData() {

        const tableData = JSON.parse(localStorage.getItem('tableData')) || [];

        tableData.forEach(({ cmsId, measureTitle, measureId, providers }) => {

            if(providers && providers === this.providerId) {

                this.addMeasureToTable(cmsId, measureTitle, measureId);

                this.checkAutho(providers);

                this.deactivateMeasure(cmsId);

            }
        });
    };

    removeMeasureFromLocal(measureId) {
        console.log("removeMeasureFromLocal");
        let listOfMeasures = JSON.parse(localStorage.getItem('tableData'));

        let measureToRemove = measureId;

        listOfMeasures = listOfMeasures.filter(function (id) {

            return id.cmsId !== measureToRemove
            
        });

        localStorage.setItem('tableData', JSON.stringify(listOfMeasures));

        /*
        let listOfMeasures = JSON.parse(localStorage.getItem('tableData'));

        let listOfMeasuresFiltered = listOfMeasures.filter(obj => {

            obj.measureId !== measureId
        });

        localStorage.setItem('tableData', JSON.stringify(listOfMeasuresFiltered));

        */

        

    };

    addResultFromLocalStorage(measureId, population = null) {

        //Load data from localStorage:
        let data = JSON.parse(localStorage.getItem(`${measureId}-responseData`));
        let populationSetKeys = Object.keys(data);

        //Update tooltip-message:
        let icon = document.getElementById(`icon-${measureId}`);

        this.loadMeasureDetail(`${measureId}`)
            .then(iconMsg => icon.setAttribute('title', iconMsg))
            .catch(error => console.error(error));

        let targetRowId = `data-${measureId}`;

        const targetRow = document.getElementById(targetRowId);

        if (!targetRow)
            return;

        let numerator, denominator;

        // Take set 1 or first population as default
        let default_population = population ?? (populationSetKeys.includes('PopulationSet_1') ? 'PopulationSet_1' : populationSetKeys[0]);
        let default_data = data[default_population];
        // <!-- Yockler Code 06/12/2024 -->
        denominator = parseInt(default_data.DENOM)
        denominator = default_data.DENEX ? (denominator - parseInt(default_data.DENEX)) : ( denominator ? denominator : 0 );
        denominator = default_data.DENEXCEP ? (denominator - parseInt(default_data.DENEXCEP)) : denominator;
        numerator = parseInt(default_data.NUMER);
        numerator = numerator ? numerator : 0;

        //Add Population Button
        const buttonGroup = document.createElement("div");
        buttonGroup.id = `btn-group-${measureId}`;
        buttonGroup.classList.add("btn-group");

        const mainButton = document.createElement("button");
        mainButton.setAttribute("type", "button");
        mainButton.classList.add("btn", "btn-warning");
        mainButton.id = 'btn-population'

        mainButton.textContent = default_population;
        
        const dropdownMenu = document.createElement("ul");

        if(!populationSetKeys.length > 1)
        {
            mainButton.disabled = true;
            mainButton.classList.remove('active')
        }else
        {
            mainButton.classList.add("dropdown-toggle");
            mainButton.setAttribute("data-toggle", "dropdown");
            mainButton.setAttribute("aria-haspopup", "true");
            mainButton.setAttribute("aria-expanded", "false");

            const caretSpan = document.createElement("span");
            caretSpan.classList.add("caret");

            mainButton.appendChild(caretSpan);

            dropdownMenu.classList.add("dropdown-menu");
            dropdownMenu.style.left = "50%";
            dropdownMenu.style.transform = "translateX(-50%)";

            populationSetKeys.forEach(population => {

                const dropdownItem = document.createElement("li");

                const dropdownLink = document.createElement("a");

                dropdownLink.setAttribute("href", "#");

                dropdownLink.setAttribute("data-action", "click->dashboard#changePopulation")

                dropdownLink.setAttribute("data-population", `${population}`)

                dropdownLink.setAttribute("data-resultid", `${measureId}`)

                dropdownLink.textContent = population;

                dropdownItem.appendChild(dropdownLink);

                dropdownMenu.appendChild(dropdownItem);

            });
        }

        buttonGroup.appendChild(mainButton);

        if(populationSetKeys.length > 1)
        {
            $(`#btn-group-${measureId}`).remove();
            buttonGroup.appendChild(dropdownMenu);
            buttonGroup.style.marginLeft = "10px";
        }

        const td = document.getElementById("population-set");

        td.appendChild(buttonGroup);

        const cell3 = targetRow.cells[5];

        const numeratorDenominator = document.createElement("div");
        numeratorDenominator.classList.add("fraction");

        const numeratorElement = document.createElement("span");
        numeratorElement.classList.add("numerator");
        numeratorElement.innerHTML = numerator;

        const fractionLine = document.createElement("span");
        fractionLine.classList.add("fraction-line");

        const denominatorElement = document.createElement("span");
        denominatorElement.classList.add("denominator");
        denominatorElement.innerHTML = denominator;

        numeratorDenominator.appendChild(numeratorElement);
        numeratorDenominator.appendChild(fractionLine);
        numeratorDenominator.appendChild(denominatorElement);

        cell3.innerHTML = "";
        cell3.appendChild(numeratorDenominator);

        const porcentage = denominator === 0 ? 0 : (numerator / denominator) * 100;

        this.porcentageMeasureResult = porcentage;

        const cell4 = targetRow.cells[4];

        const porcentCanvas = document.createElement("canvas");

        let porcentageMeasureId = default_population;

        porcentCanvas.id = `porcentage-${porcentageMeasureId}`;

        porcentCanvas.width = 80;

        porcentCanvas.height = 80;

        cell4.innerHTML = "";

        cell4.appendChild(porcentCanvas);

        this.drawPercentageCircle(porcentCanvas.id, porcentage.toFixed(2));

        let linkToMeasureDetails = document.getElementById('link-to-measure-details');

        let currentHref = linkToMeasureDetails.getAttribute('href');

        let newHref = `${currentHref}&population_set=${default_population}`;

        linkToMeasureDetails.setAttribute('href', newHref);
    };
 
}