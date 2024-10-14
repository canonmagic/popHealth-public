import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="patients"

export default class extends Controller {

    static targets = ['patientCount'];


    connect() {

        this.loadPatientCount();

        this.setupAutoRefresh();

    }

    disconnect() {

        clearInterval(this.refreshInterval);
    }

    async deleteCaches(event) {

        event.preventDefault();

        const confirmed = await Swal.fire({

            title: "Caution!",
            text: "Are you sure you want to delete all caches?",
            icon: "warning",
            showCancelButton: true,
            confirmButtonColor: "#3085d6",
            cancelButtonColor: "#d33",
            confirmButtonText: "Yes, delete caches"

        });

        if (confirmed.isConfirmed) {

            try {

                const url = 'remove_caches';

                const formData = new URLSearchParams();

                formData.append('_method', 'delete');

                const options = {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
                    },
                    body: formData.toString()
                };

                const response = await fetch(url, options);

                if (response.ok) {

                    Swal.fire({
                        icon: 'success',
                        title: 'Success',
                        text: 'Caches deleted!',
                        timer: 1500,
                        timerProgressBar: true
                    });

                    setTimeout(() => {

                        window.location.reload();

                    }, 1500);


                } else {

                    console.error(response.statusText);

                    Swal.fire({
                        icon: 'error',
                        title: 'Error',
                        text: 'Failed to delete caches. Please try again.',
                        timer: 1500,
                        timerProgressBar: true
                    });

                }

            } catch (error) {

                //console.log(error);

                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: 'Failed to delete caches. Please try again.',
                    timer: 1500,
                    timerProgressBar: true
                });
            }
        }
    }

    async deleteProviders(event) {

        event.preventDefault();

        const confirmed = await Swal.fire({
            title: "Caution!",
            text: "Are you sure you want to delete all providers?",
            icon: "warning",
            showCancelButton: true,
            confirmButtonColor: "#3085d6",
            cancelButtonColor: "#d33",
            confirmButtonText: "Yes, delete providers"
        });

        if (confirmed.isConfirmed) {

            try {

                const url = 'remove_providers';

                const formData = new URLSearchParams();

                formData.append('_method', 'delete');

                const options = {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
                    },
                    body: formData.toString()
                };

                const response = await fetch(url, options);

                if (response.ok) {

                    Swal.fire({
                        icon: 'success',
                        title: 'Success',
                        text: 'Providers deleted!',
                        timer: 1500,
                        timerProgressBar: true
                    });

                    setTimeout(() => {

                        window.location.reload();

                    }, 1500);


                } else {

                    console.error(response.statusText);

                    Swal.fire({
                        icon: 'error',
                        title: 'Error',
                        text: 'Failed to delete providers. Please try again.'
                    });

                }

            } catch (error) {

                //console.log(error);

                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: 'Failed to delete providers. Please try again.'
                });

            }
        }
    };

    async deletePatients(event) {

        event.preventDefault();

        const confirmed = await Swal.fire({
            title: "Caution!",
            text: "Are you sure you want to delete all patients?",
            icon: "warning",
            showCancelButton: true,
            confirmButtonColor: "#3085d6",
            cancelButtonColor: "#d33",
            confirmButtonText: "Yes, delete patients"
        });

        if (confirmed.isConfirmed) {

            try {

                const url = 'remove_patients';

                const formData = new URLSearchParams();

                formData.append('_method', 'delete');

                const options = {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
                    },
                    body: formData.toString()
                };

                const response = await fetch(url, options);

                if (response.ok) {

                    Swal.fire({
                        icon: 'success',
                        title: 'Success',
                        text: 'Patients deleted!',
                        timer: 1500,
                        timerProgressBar: true
                    });

                    setTimeout(() => {

                        window.location.reload();

                    }, 1500);


                } else {

                    console.error(response.statusText);

                    Swal.fire({
                        icon: 'error',
                        title: 'Error',
                        text: 'Failed to delete patients. Please try again.'
                    });

                }

            } catch (error) {

                //console.log(error);

                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: 'Failed to delete patients. Please try again.'
                });

            }
        }
    };

    async deleteAll(event) {
        event.preventDefault();

        const confirmed = await Swal.fire({
            title: "Caution!",
            text: "Are you sure you want to delete everything? (Patients, Providers, Cache)",
            icon: "warning",
            showCancelButton: true,
            confirmButtonColor: "#3085d6",
            cancelButtonColor: "#d33",
            confirmButtonText: "Yes, delete everything"
        });

        if (confirmed.isConfirmed) {
            try {
                const url = 'remove_all';
                const formData = new URLSearchParams();
                formData.append('_method', 'delete');

                const options = {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
                    },
                    body: formData.toString()
                };

                const response = await fetch(url, options);

                if (response.ok) {
                    Swal.fire({
                        icon: 'success',
                        title: 'Success',
                        text: 'All records deleted!',
                        timer: 1500,
                        timerProgressBar: true
                    });

                    setTimeout(() => {
                        window.location.reload();
                    }, 1500);
                } else {
                    console.error(response.statusText);
                    Swal.fire({
                        icon: 'error',
                        title: 'Error',
                        text: 'Failed to delete records. Please try again.'
                    });
                }
            } catch (error) {
                console.error(error);
                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: 'Failed to delete records. Please try again.'
                });
            }
        }
    }

    async loadPatientCount() {

        try {

            const response = await fetch('/api/admin/patients/count');

            const data = await response.json();

            const patientCount = data.patient_count;

            const patientCountElement = document.getElementById("patient_count");

            patientCountElement.textContent = patientCount;

        } catch (error) {

            console.error(error);

        }

    }

    setupAutoRefresh() {

        this.refreshInterval = setInterval(() => {

            this.loadPatientCount()

        }, 5000);
    }

    uploadFilePatient(event) {

        event.preventDefault();

        const input = document.getElementById('filePatient');

        const file = input.files[0];

        if (file) {

            Swal.fire({
                title: 'Upload Confirmation',
                text: 'Are you sure you want to upload the file?',
                icon: 'question',
                showCancelButton: true,
                confirmButtonText: 'Yes',
                cancelButtonText: 'No'
            }).then((result) => {
                if (result.isConfirmed) {
                    Swal.fire('Success', 'File uploaded successfully', 'success');
                    setTimeout(() => {
                        location.reload();
                    }, 2000);
                }
            });

        } else {

            event.preventDefault();

            Swal.fire('Error', 'You must select a file before uploading.', 'error');

        };

    };


    uploadFileProvider(event) {

        const input = document.getElementById('fileProvider');
        const file = input.files[0];

        if (file) {
            event.preventDefault();

            Swal.fire({
                title: 'Upload Confirmation',
                text: 'Are you sure you want to upload the file?',
                icon: 'question',
                showCancelButton: true,
                confirmButtonText: 'Yes',
                cancelButtonText: 'No'
            }).then((result) => {
                if (result.isConfirmed) {
                    Swal.fire('Success', 'File uploaded successfully', 'success');
                }
            });
        } else {
            event.preventDefault();
            Swal.fire('Error', 'You must select a file before uploading.', 'error');
        }

    };


}

