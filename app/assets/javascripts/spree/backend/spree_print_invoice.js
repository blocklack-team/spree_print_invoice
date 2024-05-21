$(document).ready(function() {
// Seleccionar/Deseleccionar todos
	$('body').on('change', '#select-all', function() {
		$('body .document-checkbox').prop('checked', this.checked);
	});

	// Imprimir documentos seleccionados
	$('body').on('click', '#print-selected-documents', function() {
		var selectedCheckboxes = $('body .document-checkbox:checked');
		var documentIds = [];

		selectedCheckboxes.each(function() {
			documentIds.push($(this).data('id'));
		});

		if (documentIds.length > 0) {
			var form = $('<form>', {
				method: 'POST',
				action: '/admin/bookkeeping_documents/combine_and_print',
				target: '_blank', // Abrir en una nueva pestaña
				style: 'display: none;'
			});

			var authenticityToken = $('meta[name="csrf-token"]').attr('content');
			var tokenInput = $('<input>', {
				type: 'hidden',
				name: 'authenticity_token',
				value: authenticityToken
			});
			form.append(tokenInput);

			documentIds.forEach(function(id) {
				var idInput = $('<input>', {
					type: 'hidden',
					name: 'document_ids[]',
					value: id
				});
				form.append(idInput);
			});

			$('body').append(form);
			form.submit();
		} else {
			alert('Please select at least one document.');
		}
	});

	$('body').on('click', '#download-selected-excel', function() {
		const selectedDocuments = $('.document-checkbox:checked').map(function() {
			return $(this).data('id');
		}).get();

		if (selectedDocuments.length === 0) {
			alert('Please select at least one document.');
			return;
		}

		const csrfToken = $('meta[name="csrf-token"]').attr('content');

		$.ajax({
			url: '/admin/bookkeeping_documents/export_to_excel',
			method: 'POST',
			contentType: 'application/json',
			headers: {
				'X-CSRF-Token': csrfToken
			},
			data: JSON.stringify({ document_ids: selectedDocuments }),
			success: function(blob) {
				const url = window.URL.createObjectURL(blob);
				const a = document.createElement('a');
				a.href = url;
				a.download = 'selected_documents.xlsx';
				document.body.appendChild(a);
				a.click();
				document.body.removeChild(a);
			},
			error: function(error) {
				console.error('Error:', error);
			},
			xhrFields: {
				responseType: 'blob'
			}
		});
	});
});

//= require spree/backend
//= require ./print_invoice_settings
