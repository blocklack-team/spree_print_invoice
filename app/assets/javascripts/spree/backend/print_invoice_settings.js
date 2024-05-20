$(function() {
  // Seleccionar/Deseleccionar todos
  $('#select-all').change(function() {
    $('.document-checkbox').prop('checked', this.checked);
  });

  // Imprimir documentos seleccionados
  $('#print-selected-documents').click(function() {
    var selectedCheckboxes = $('.document-checkbox:checked');
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

  var storage_path_field;
  storage_path_field = $('#storage_path');
  return $('#store_pdf').click(function() {
    return storage_path_field.prop('disabled', !$(this).prop('checked'));
  });
});
