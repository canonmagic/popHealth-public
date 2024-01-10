import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="users"
export default class extends Controller {

	static targets = ['username', 'role', 'user']
	
	connect() {
	
	}

	async changeNpi(event) {

		event.preventDefault();

		const name = event.target.getAttribute('data-name');

		const username = event.target.getAttribute('data-username');

		

		try {

			const confirmed = await Swal.fire({
				icon: 'warning',
				title: 'Are you sure?',
				text: 'This action will change the NPI. Do you want to proceed?',
				showCancelButton: true,
				confirmButtonColor: '#3085d6',
				cancelButtonColor: '#d33',
				confirmButtonText: 'Yes, change NPI!',
				cancelButtonText: 'Cancel'
			});

			if (confirmed.isConfirmed) {

				const url = event.target.getAttribute('data-npi-url');

				const formData = new URLSearchParams();

				formData.append('user', username);

				formData.append('value2', 'value2');

				const options = {
					method: 'POST',
					headers: {
						'Content-Type': 'application/x-www-form-urlencoded',
						'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
					},
					body: formData.toString()
				};

				const response = await fetch(url, options);

				if (response.ok) {
					const responseData = await response.json();

					Swal.fire({
						icon: 'success',
						title: 'NPI Changed Successfully',
						text: responseData.message
					});
				} else {
					console.error(response.statusText);

					Swal.fire({
						icon: 'error',
						title: 'Error',
						text: 'Failed to change NPI. Please try again.'
					});
				}
			}
		} catch (error) {
			console.error(error);

			Swal.fire({
				icon: 'error',
				title: 'Error',
				text: 'An unexpected error occurred. Please try again.'
			});
		}
	}

	async changePractice(event) {

		event.preventDefault();

		const userId = event.target.getAttribute('data-user');

		const practiceId = event.target.value;

		try {

			const confirmed = await Swal.fire({
				icon: 'info',
				title: 'Change Practice?',
				text: 'This action will change the practice. Do you want to proceed?',
				showCancelButton: true,
				confirmButtonColor: '#28a745',
				cancelButtonColor: '#d33',
				confirmButtonText: 'Yes, change practice!',
				cancelButtonText: 'Cancel'
			});

			if (confirmed.isConfirmed) {

				const url = event.target.getAttribute("data-url");

				const formData = new URLSearchParams();

				formData.append('user', userId);

				formData.append('practice', practiceId);

				const options = {
					method: 'POST',
					headers: {
						'Content-Type': 'application/x-www-form-urlencoded',
						'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
					},
					body: formData.toString()
				};

				const response = await fetch(url, options);

				if (response.ok) {

					const responseData = await response.json();

					Swal.fire({
						icon: 'success',
						title: 'Practice Changed Successfully',
						text: responseData.message
					});

					window.location.reload();

				} else {
					
					console.error(response.statusText);

					Swal.fire({
						icon: 'error',
						title: 'Error',
						text: 'Failed to change practice. Please try again.'
					});
				}
			}
		} catch (error) {
			console.error(error);

			Swal.fire({
				icon: 'error',
				title: 'Error',
				text: 'An unexpected error occurred. Please try again.'
			});
		}
	}

	async changePracticeProvider(event) {

		event.preventDefault();

		const userId = event.target.getAttribute('data-user');

		const providerId = event.target.getAttribute('data-providerId');

		try {
			const confirmed = await Swal.fire({
				icon: 'info',
				title: 'Change Practice Provider?',
				text: 'This action will change the practice provider. Do you want to proceed?',
				showCancelButton: true,
				confirmButtonColor: '#28a745',
				cancelButtonColor: '#d33',
				confirmButtonText: 'Yes, change practice provider!',
				cancelButtonText: 'Cancel'
			});

			if (confirmed.isConfirmed) {
				const url = event.target.getAttribute('data-url');
				const formData = new URLSearchParams();

				formData.append('userId', userId);
				formData.append('providerId', providerId);

				const options = {
					method: 'POST',
					headers: {
						'Content-Type': 'application/x-www-form-urlencoded',
						'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
					},
					body: formData.toString()
				};

				const response = await fetch(url, options);

				if (response.ok) {
					const responseData = await response.json();

					Swal.fire({
						icon: 'success',
						title: 'Practice Provider Changed Successfully',
						text: responseData.message
					});

					window.location.reload();

				} else {
					console.error(response.statusText);

					Swal.fire({
						icon: 'error',
						title: 'Error',
						text: 'Failed to change practice provider. Please try again.'
					});
				}
			}
		} catch (error) {
			console.error(error);

			Swal.fire({
				icon: 'error',
				title: 'Error',
				text: 'An unexpected error occurred. Please try again.'
			});
		}
		}

	async promoteUser(event) {

		event.preventDefault();

		const username = event.target.getAttribute('data-username');

		const role = event.target.getAttribute('data-role');

		try {

			const confirmed = await Swal.fire({
				icon: 'warning',
				title: 'Are you sure?',
				text: 'This action will promote the user. Do you want to proceed?',
				showCancelButton: true,
				confirmButtonColor: '#3085d6',
				cancelButtonColor: '#d33',
				confirmButtonText: 'Yes, promote!',
				cancelButtonText: 'Cancel'
			});

			if (confirmed.isConfirmed) {

				const url = event.target.getAttribute('data-promote-url');

				const requestData = {

					username: username,
					role: role

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

					const responseData = await response.json();

					Swal.fire({
						icon: 'success',
						title: 'User Promoted Successfully',
						text: responseData.message
					});

					window.location.reload();

				} else {

					console.error(response.statusText);

					Swal.fire({
						icon: 'error',
						title: 'Error',
						text: 'Failed to promote user. Please try again.'
					});
				}
			}
		} catch (error) {

			console.error(error);

			Swal.fire({
				icon: 'error',
				title: 'Error',
				text: 'An unexpected error occurred. Please try again.'
			});
		}
	}

	async demoteUser(event) {

		event.preventDefault();

		const username = event.target.getAttribute('data-username');

		const role = event.target.getAttribute('data-role');

		try {

			const confirmed = await Swal.fire({
				icon: 'warning',
				title: 'Are you sure?',
				text: 'This action will demote the user. Do you want to proceed?',
				showCancelButton: true,
				confirmButtonColor: '#3085d6',
				cancelButtonColor: '#d33',
				confirmButtonText: 'Yes, demote!',
				cancelButtonText: 'Cancel'
			});

			if (confirmed.isConfirmed) {

				const url = event.target.getAttribute('data-demote-url');

				const formData = new URLSearchParams();

				formData.append('username', username);

				formData.append('role', role);

				const options = {

					method: 'POST',
					headers: {
						'Content-Type': 'application/x-www-form-urlencoded',
						'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
					},
					body: formData.toString()
				};

				const response = await fetch(url, options);

				if (response.ok) {

					const responseData = await response.json();

					Swal.fire({
						icon: 'success',
						title: 'User Demoted Successfully',
						text: responseData.message
					});

					window.location.reload();

				} else {

					console.error(response.statusText);

					Swal.fire({
						icon: 'error',
						title: 'Error',
						text: 'Failed to demote user. Please try again.'
					});
				}
			}
		} catch (error) {
			console.error(error);
			Swal.fire({
				icon: 'error',
				title: 'Error',
				text: 'An unexpected error occurred. Please try again.'
			});
		}
	}

	async approveUser(event) {

		event.preventDefault();

		const username = event.target.getAttribute('data-username');

		try {
			const confirmed = await Swal.fire({
				icon: 'info',
				title: 'Approve User?',
				text: 'This action will approve the user. Do you want to proceed?',
				showCancelButton: true,
				confirmButtonColor: '#28a745',
				cancelButtonColor: '#d33',
				confirmButtonText: 'Yes, approve!',
				cancelButtonText: 'Cancel'
			});

			if (confirmed.isConfirmed) {

				const url = event.target.getAttribute('data-approve-url');

				const requestData = { username: username };

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
					const responseData = await response.json();

					Swal.fire({
						icon: 'success',
						title: 'User Approved Successfully',
						text: responseData.message
					});

					window.location.reload();

				} else {

					console.error(response.statusText);

					Swal.fire({
						icon: 'error',
						title: 'Error',
						text: 'Failed to approve user. Please try again.'
					});
				}
			}
		} catch (error) {
			console.error(error);

			Swal.fire({
				icon: 'error',
				title: 'Error',
				text: 'An unexpected error occurred. Please try again.'
			});
		}
	};

	async disableOrEnableUser(event) {

		event.preventDefault();

		const username = event.target.getAttribute('data-username');

		const option = event.target.getAttribute('data-option');

		const action = event.target.getAttribute('data-action-option');

		try {

			const confirmed = await Swal.fire({
				icon: 'info',
				title: `${action} User?`,
				text: `This action will ${action.toLowerCase()} the user. Do you want to proceed?`,
				showCancelButton: true,
				confirmButtonColor: '#28a745',
				cancelButtonColor: '#d33',
				confirmButtonText: `Yes, ${action.toLowerCase()}!`,
				cancelButtonText: 'Cancel'
			});

			if (confirmed.isConfirmed) {
				const url = event.target.getAttribute('data-disable-enable-url');

				const formData = new URLSearchParams();
				formData.append('username', username);
				formData.append('disabled', option);

				const options = {
					method: 'POST',
					headers: {
						'Content-Type': 'application/x-www-form-urlencoded',
						'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
					},
					body: formData.toString()
				};

				const response = await fetch(url, options);

				if (response.ok) {
					const responseData = await response.json();

					Swal.fire({
						icon: 'success',
						title: `User ${action} Successfully`,
						text: responseData.message
					});

					window.location.reload();
					
				} else {
					console.error(response.statusText);

					Swal.fire({
						icon: 'error',
						title: 'Error',
						text: `Failed to ${action.toLowerCase()} user. Please try again.`
					});
				}
			}
		} catch (error) {
			console.error(error);

			Swal.fire({
				icon: 'error',
				title: 'Error',
				text: 'An unexpected error occurred. Please try again.'
			});
		}
	}





}
