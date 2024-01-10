import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="measures"
export default class extends Controller {

  //static targets = ["output"];
  /*
  connect() {
    fetch("/api/measures")
      .then(response => response.json())
      .then(data => {
        console.log(data);
        data.forEach(measure => {
          console.log(measure);
          const measureElement = document.createElement("div");
          measureElement.textContent = `Title: ${measure.title}`;
          this.outputTarget.appendChild(measureElement);
        });
      })
      .catch(error => {
        console.error(error.message);
      });
  }
  */

}
