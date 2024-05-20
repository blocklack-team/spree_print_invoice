$(function() {
  var storage_path_field;
  storage_path_field = $('#storage_path');
  return $('#store_pdf').click(function() {
    return storage_path_field.prop('disabled', !$(this).prop('checked'));
  });
});

document.addEventListener('DOMContentLoaded', function() {
  // Seleccionar/Deseleccionar todos
  document.getElementById('select-all').addEventListener('change', function() {
    var checkboxes = document.querySelectorAll('.document-checkbox');
    checkboxes.forEach(function(checkbox) {
      checkbox.checked = this.checked;
    }, this);
  });

  // Imprimir documentos seleccionados
  document.getElementById('print-selected-documents').addEventListener('click', function() {
    var selectedCheckboxes = document.querySelectorAll('.document-checkbox:checked');
    selectedCheckboxes.forEach(function(checkbox) {
      var url = checkbox.getAttribute('data-url');
      window.open(url, '_blank');
    });
  });
});
