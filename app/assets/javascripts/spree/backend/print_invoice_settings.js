$(function() {
  var storage_path_field;
  storage_path_field = $('#storage_path');
  return $('#store_pdf').click(function() {
    return storage_path_field.prop('disabled', !$(this).prop('checked'));
  });
});

document.addEventListener('DOMContentLoaded', function() {
  document.getElementById('select-all').addEventListener('change', function() {
    var checkboxes = document.querySelectorAll('.document-checkbox');
    checkboxes.forEach(function(checkbox) {
      checkbox.checked = this.checked;
    }, this);
  });

  document.getElementById('print-selected-documents').addEventListener('click', function() {
    var selectedCheckboxes = document.querySelectorAll('.document-checkbox:checked');
    var documentIds = [];
    selectedCheckboxes.forEach(function(checkbox) {
      documentIds.push(checkbox.getAttribute('data-id'));
    });

    if (documentIds.length > 0) {
      var form = document.createElement('form');
      form.method = 'POST';
      form.action = '/admin/bookkeeping_documents/combine_and_print';
      form.style.display = 'none';

      var authenticityToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
      var tokenInput = document.createElement('input');
      tokenInput.type = 'hidden';
      tokenInput.name = 'authenticity_token';
      tokenInput.value = authenticityToken;
      form.appendChild(tokenInput);

      documentIds.forEach(function(id) {
        var idInput = document.createElement('input');
        idInput.type = 'hidden';
        idInput.name = 'document_ids[]';
        idInput.value = id;
        form.appendChild(idInput);
      });

      document.body.appendChild(form);
      form.submit();
    } else {
      alert('Por favor, seleccione al menos un documento para imprimir.');
    }
  });
});