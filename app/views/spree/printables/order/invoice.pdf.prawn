# app/views/spree/printables/order/invoice.pdf.prawn
pdf.text "Hello, PDF!"
pdf.text "Order ID: #{@bookkeeping_document.number}"
pdf.text "Document ID: #{@bookkeeping_document.id}"
pdf.text "Email: #{@bookkeeping_document.email}"
pdf.text "Name: #{@bookkeeping_document.firstname}"
