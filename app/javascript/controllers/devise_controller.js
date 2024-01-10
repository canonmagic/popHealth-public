import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="devise"
export default class extends Controller {

    connect() {



    }

    saveConfirm(event) {

        event.preventDefault();

        Swal.fire({
            title: "Do you want to save the changes?",
            showDenyButton: true,
            showCancelButton: true,
            icon: "warning",
            confirmButtonText: 'Save',
            denyButtonText: `Don't save`
        }).then((result) => {
            if (result.isConfirmed) {
                Swal.fire({
                    title: 'Saved',
                    icon: 'success',
                    timer: 1500,
                    timerProgressBar: true
                }   
                );

                this.element.querySelector('form').submit();

                setTimeout(() => {

                    window.location.reload();

                }, 1500);
                
            } else if(result.isDenied) {

                Swal.fire({
                    title: 'Changes are not saved',
                    icon: 'info',
                    timer: 1500,
                    timerProgressBar: true
                });
            }
        });
    };

    confirmCancel(event) {

        event.preventDefault();

        Swal.fire({
            title: 'Are you sure?',
            text: 'If you cancel, you will lose any unsaved changes.',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#3085d6',
            cancelButtonColor: '#d33',
            confirmButtonText: 'Yes, cancel',
            cancelButtonText: 'No, keep editing'
        }).then((result) => {
            if (result.isConfirmed) {
                this.goBack();
            }
        });
}

    goBack() {
    
        window.history.back();

    }

}
