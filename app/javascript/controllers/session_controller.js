import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="session"
export default class extends Controller {

    connect() {

    }

    togglePassword() {
        
        this.showPasswordCheckbox = this.element.querySelector("#showPassword");
        this.passwordField = this.element.querySelector("#passwordLogin");

        const passwordFieldType = this.passwordField.type;
        this.passwordField.type = passwordFieldType === "password" ? "text" : "password";
    }

    
}
