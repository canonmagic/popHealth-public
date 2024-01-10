import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="teams"
export default class extends Controller {


	connect() {


	};

	confirmSubmit(event) {

		const teamName = document.getElementById("teamName");

		const teamValue = teamName.value.trim();

		if(teamValue) {

			if (confirm("Are you sure you want to proceed?")) {

	
			}


			


		} else {

			event.preventDefault();



			alert("You must enter some text before proceeding.");



		}





	};




}
