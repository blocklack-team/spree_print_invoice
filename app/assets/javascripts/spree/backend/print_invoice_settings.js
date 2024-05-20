$(function() {
  var storage_path_field;
  storage_path_field = $('#storage_path');
  return $('#store_pdf').click(function() {
    return storage_path_field.prop('disabled', !$(this).prop('checked'));
  });
});

document.getElementById('select-all').addEventListener('change', function() {
  var checkboxes = document.querySelectorAll('.document-checkbox');
  checkboxes.forEach(function(checkbox) {
    checkbox.checked = this.checked;
  }, this);
});


document.getElementById('print-selected-documents').addEventListener('click', function() {
  var selectedCheckboxes = document.querySelectorAll('.document-checkbox:checked');
  var documentUrls = [];
  selectedCheckboxes.forEach(function(checkbox) {
    documentUrls.push(checkbox.getAttribute('data-url'));
  });

  if (documentUrls.length > 0) {
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

    documentUrls.forEach(function(url) {
      var urlInput = document.createElement('input');
      urlInput.type = 'hidden';
      urlInput.name = 'document_urls[]';
      urlInput.value = url;
      form.appendChild(urlInput);
    });

    document.body.appendChild(form);
    form.submit();
  } else {
    alert('Please, select one or more documents for print.');
  }
});
