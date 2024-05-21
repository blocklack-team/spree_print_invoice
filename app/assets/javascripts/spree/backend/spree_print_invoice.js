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
		alert('Por favor, seleccione al menos un documento para imprimir.');
	}
});

//= require spree/backend
//= require ./print_invoice_settings
