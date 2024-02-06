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

            //console.log(pathName, segmentsName);

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

                console.log('Error');
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

        //console.log(pathName, segmentsName)

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
        
        //console.log(this.dataListChecked);

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

                    console.log(this.dataListChecked);

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

        //console.log(this.dataListChecked);

        this.verifyButtonExport();

    };

    async setReportinRecord(event) {

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

            //console.log(startDate, endDate);
      
            let listOfMeasure = JSON.parse(localStorage.getItem('tableData'));
            
            for (let x = 0; x < listOfMeasure.length; x++) {
                
                listOfMeasure[x].startDate = this.formatDate(startDateFormat);
                
                listOfMeasure[x].endDate = this.formatDate(endDateFormat);

                //console.log('end', listOfMeasure[x].endDate)
                
            }
            
            localStorage.setItem('tableData', JSON.stringify(listOfMeasure));
            
            //console.log(listOfMeasure);

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

            //console.log(response)

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

        console.log(endDateUser, startDateUser)

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

        console.log(startDateDefault, endDateDefault);

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

                //console.log(data)

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

                console.log(error);
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

                //console.log(data)

            } else {

                console.log('error')
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

                //console.log(data);


            } else {

                console.log(error);
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

        //console.log(cell4.id)

        const spinner = this.createSpinnerLoading();

        cell4.appendChild(spinner);

        // NUMERADOR/DENOMINADOR (quinta columna)
        const cell5 = newRow.insertCell(5);

        cell5.id = `numerator-denominator-${measureId}`;

        const spinner2 = this.createSpinnerLoading();

        cell5.appendChild(spinner2);


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

        //console.log(table.row)

        this.activateMeasure(row.cells[2].innerText);

        table.deleteRow(row.rowIndex);

        //this.deactivateButtonExportReport();

        this.removeMeasureFromLocal(row.cells[2].innerText);

        //console.log('hey', this.cmsId)

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

        this.checkAutho();

        this.addMeasureToTable(this.cmsId, measureTitle, this.measureHqmfId);

        //console.log(this.cmsId, measureTitle, this.measureHqmfId)

        this.deactivateMeasure(this.cmsId);

    };

    addMeasureToLocalStorage(cmsId, measureTitle, measureId) {

        const tableData = JSON.parse(localStorage.getItem('tableData')) || [];

        const newRowData = {

            cmsId: cmsId,
            measureTitle: measureTitle,
            measureId: measureId,
            startDate: this.effectiveStartDate,
            endDate: this.effectiveEndDate,
            status: 'pending',
            providers: this.providerId,
            onTable: true

        };

        //console.log('NewRow', newRowData)

        const exists = tableData.some(element => element.measureId === measureId);

        if (!exists) {

            tableData.push(newRowData);

            localStorage.setItem('tableData', JSON.stringify(tableData));

        };

        //console.log(tableData)

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

    addResultToTable(dataResult) {

        //Update tooltip-message:

        let icon = document.getElementById(`icon-${Object.keys(dataResult)[0]}`);

        this.loadMeasureDetail(`${Object.keys(dataResult)[0]}`)

            .then(iconMsg => {

                //console.log(iconMsg);

                icon.setAttribute('title', iconMsg);

            })

            .catch(error => console.error(error));

        //const tableBody = document.getElementById('measureResultTable');

        let targetRowId = `data-${Object.keys(dataResult)[0]}`;

        const targetRow = document.getElementById(targetRowId);

        if(!targetRow) {

            return;
        }

        //const newRow = tableBody.rows[tableBody.rows.length - 1];

        // NUMERATOR/DENOMINATOR

        let denominator = dataResult.DENEX !== null ? (parseInt(dataResult.DENOM) - parseInt(dataResult.DENEX)) : parseInt(dataResult.DENOM);

        denominator = dataResult.DENEXCEP !== null ? (denominator - parseInt(dataResult.DENEXCEP)) : denominator;

        const numerator = dataResult.NUMER;

        const cell3 = targetRow.cells[5];

        /*

        const numeratorDenominator = document.createElement("span");

        numeratorDenominator.innerHTML = `${numerator}/${denominator}`;

        cell3.innerHTML = "";

        cell3.appendChild(numeratorDenominator);

        */

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


        //PORCENTAGE

        /*

        const porcentage = (numerator / denominator)*100;

        const cell4 = targetRow.cells[2];

        const porcent = document.createElement("td");

        porcent.innerHTML = `<h2>${porcentage}%</h2>`;

        cell4.innerHTML = "";

        cell4.appendChild(porcent);

        */

        const porcentage = denominator === 0 ? 0 : (numerator / denominator) * 100;

        //console.log(numerator,denominator, porcentage)

        this.porcentageMeasureResult = porcentage;

        const cell4 = targetRow.cells[4];

        const porcentCanvas = document.createElement("canvas");

        let porcentageMeasureId = Object.keys(dataResult)[0];

        porcentCanvas.id = `porcentage-${porcentageMeasureId}`;

        //console.log(porcentCanvas.id)

        porcentCanvas.width = 80;

        porcentCanvas.height = 80;

        cell4.innerHTML = "";

        //console.log(cell4)

        cell4.appendChild(porcentCanvas);

        this.drawPercentageCircle(porcentCanvas.id, porcentage.toFixed(2));


    };

    async submitQueryCalculate(measureId, endDate, startDate, providers) {

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

            if (response.ok && response.headers.get('Content-Type')?.includes('application/json')) {

                const responseData = await response.json();

                //console.log(responseData);

                let listOfMeasure = JSON.parse(localStorage.getItem('tableData'))

                for(let x = 0; x < listOfMeasure.length; x++) {

                    if(listOfMeasure[x].measureId === Object.keys(responseData)[0]) {

                        listOfMeasure[x].status = 'completed';

                        localStorage.setItem('tableData', JSON.stringify(listOfMeasure));

                        //console.log(listOfMeasure);

                        this.addResultToTable(responseData);
                        
                    }
                }

                //this.activateButtonExportReport();



            } else if(response.status === 200) {

                //console.log(`Respuesta distinta de JSON: ${response}`)


            }else {

                //console.log(`Respuesta else: ${response.statusText}`);


            }

        } catch (error) {

            console.error(`Console error: ${error}`);

        }
    };

    checkAutho() {

        fetch(`../home/check_authorization/?id=${this.providerId}`)

            .then(response => {

                if(response.ok) {

                    return response.json();

                } else {

                    //console.log('false')
                    
                }
            })
            .then(data => {

            })

            .catch(error => {

                console.error(error)

            });

            let listOfMeasure = JSON.parse(localStorage.getItem('tableData'))

            for(let i=0; i < listOfMeasure.length ; i++) {

                let element = listOfMeasure[i];

                this.submitQueryCalculate(element.measureId, element.endDate, element.startDate, this.providerId);

                //if(element.status === 'pending') {}

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

                //console.log(fName)

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

                console.log('Error')
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

                console.log('error')
            }

        } catch (error) {

            console.log(error)
            
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

        const tableData2 = localStorage.getItem('tableData');

        tableData.forEach(({ cmsId, measureTitle, measureId }) => {

            this.addMeasureToTable(cmsId, measureTitle, measureId);

            this.checkAutho();

            //console.log('button',cmsId)

            this.deactivateMeasure(cmsId);

        });

        //console.log(`Table Data: ${tableData2}`)

    };

    removeMeasureFromLocal(measureId) {

        let listOfMeasures = JSON.parse(localStorage.getItem('tableData'));

        //console.log('Result1', listOfMeasures)

        let measureToRemove = measureId;

        listOfMeasures = listOfMeasures.filter(function (id) {

            return id.cmsId !== measureToRemove
            
        });

        localStorage.setItem('tableData', JSON.stringify(listOfMeasures));

        //console.log('Result', listOfMeasures)

        /*
        let listOfMeasures = JSON.parse(localStorage.getItem('tableData'));

        let listOfMeasuresFiltered = listOfMeasures.filter(obj => {

            obj.measureId !== measureId
        });

        localStorage.setItem('tableData', JSON.stringify(listOfMeasuresFiltered));

        */

        

    };
    
}