module Spree
  class BookkeepingDocument < ActiveRecord::Base
    PERSISTED_ATTRS = [
      :firstname,
      :lastname,
      :email,
      :total,
      :number
    ]

    # Spree::BookkeepingDocument cares about creating PDFs. Whenever it needs to know
    # anything about the document to send to the view, it asks a view object.
    #
    # +printable+ should be an Object, such as Spree::Order or Spree::Shipment.
    # template should be a string, such as "invoice" or "packaging_slip"
    #
    belongs_to :printable, polymorphic: true
    validates :printable, :template, presence: true
    validates *PERSISTED_ATTRS, presence: true, if: -> { self.persisted? }
    scope :invoices, -> { where(template: 'invoice') }

    before_create :copy_view_attributes
    after_save :after_save_actions

    def self.ransackable_attributes(auth_object = nil)
      ["created_at", "email", "firstname", "id", "id_value", "lastname", "number", "printable_id", "printable_type", "template", "total", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      ["printable"]
    end

    # An instance of Spree::Printable::#{YourModel}::#{YourTemplate}Presenter
    #
    def view
      @_view ||= view_class.new(printable)
    end

    def date
      created_at.to_date
    end

    def template_name
      "spree/printables/#{single_lower_case_name(printable.class.name)}/#{template}"
    end

    # If the document is called from the view with some method it doesn't know,
    # just call the view object. It should know.
    def method_missing(method_name, *args, &block)
      if view.respond_to? method_name
        view.send(method_name, *args, &block)
      else
        super
      end
    end

    def document_type
      "#{printable_type.demodulize.tableize.singularize}_#{template}"
    end

    # Returns the given template as pdf binary suitable for Rails send_data
    #
    # If the file is already present it returns this
    # else it generates a new file, stores and returns this.
    #
    # You can disable the pdf file generation with setting
    #
    #   Spree::PrintInvoice::Config.store_pdf to false
    #
    def pdf
      if Spree::PrintInvoice::Config.store_pdf
        send_or_create_pdf
      else
        render_pdf
      end
    end

    # = The PDF file_name
    #
    def file_name
      @_file_name ||= "#{template}-D#{id}-N#{number}.pdf"
    end

    # = PDF file path
    #
    def file_path
      @_file_path ||= Rails.root.join(storage_path, "#{file_name}")
    end

    # = PDF storage folder path for given template name
    #
    # Configure the storage path with +Spree::PrintInvoice::Config.storage_path+
    #
    # Each template type gets it own pluralized folder inside
    # of +Spree::PrintInvoice::Config.storage_path+
    #
    # == Example:
    #
    #   storage_path('invoice') => "tmp/pdf_prints/invoices"
    #
    # Creates the folder if it's not present yet.
    #
    def storage_path
      storage_path = Rails.root.join(Spree::PrintInvoice::Config.storage_path, template.pluralize)
      FileUtils.mkdir_p(storage_path)
      storage_path
    end

    # Renders the prawn template for give template name in context of ActionView.
    #
    # Prawn templates need to be placed in the correct folder. For example, for a PDF from
    # a Spree::Order with the invoice template, it would be
    # the +app/views/spree/printables/order/invoices+ folder.
    #
    # Assigns +@doc+ instance variable
    #
    def render_pdf
      if template == 'invoice'
        self.invoice_template
      elsif template == 'packaging_slip'
        self.packaging_slip_template
      end
      #ActionController::Base.new.render_to_string(template: "#{template_name}.pdf.prawn", layout: false, assigns: { doc: self })
    end

    private

    def invoice_template
      doc = self
      printable = doc
      invoice = doc

      font_style = {
        face: Spree::PrintInvoice::Config[:font_face],
        size: Spree::PrintInvoice::Config[:font_size]
      }
      
      pdf = Prawn::Document.new
      pdf.font_families.update(Spree::PrintInvoiceSetting.additional_fonts)
      pdf.define_grid(columns: 5, rows: 8, gutter: 10)
      pdf.font font_style[:face], size: font_style[:size]
      
      pdf.repeat(:all) do
        #im = (Rails.application.assets || ::Sprockets::Railtie.build_environment(Rails.application)).find_asset(Spree::PrintInvoice::Config[:logo_path])
        logo_path = Rails.root.join('app', 'assets', 'images', Spree::PrintInvoice::Config[:logo_path])

        if File.exist?(logo_path)
          pdf.image logo_path, vposition: :top, height: 40, scale: Spree::PrintInvoice::Config[:logo_scale]
        end
        
        pdf.grid([0,3], [1,4]).bounding_box do
          pdf.text Spree.t(printable.document_type, scope: :print_invoice), align: :right, style: :bold, size: 18
          pdf.move_down 4
        
          pdf.text Spree.t(:invoice_number, scope: :print_invoice, number: printable.number), align: :right
          pdf.move_down 2
          pdf.text Spree.t(:invoice_date, scope: :print_invoice, date: I18n.l(printable.date)), align: :right
        end
      end
      
      # CONTENT
      pdf.grid([1,0], [6,4]).bounding_box do

        #email cell
        if pdf.page_number == 1
          pdf.move_down 2
          email_cell = pdf.make_cell(content: Spree.t(:email), font_style: :bold)
          email = printable.email
        
          # Creamos dos filas de celdas, cada una con una celda para el encabezado y una celda para el correo electrónico
          data = [[email_cell, pdf.make_cell(content: email)]]
          
          pdf.table(data, position: :center, column_widths: [0.5])
        end
      
        # address block on first page only
        if pdf.page_number == 1
          bill_address = printable.bill_address
          ship_address = printable.ship_address
          
          pdf.move_down 2
          address_cell_billing  = pdf.make_cell(content: Spree.t(:billing_address), font_style: :bold)
          address_cell_shipping = pdf.make_cell(content: Spree.t(:shipping_address), font_style: :bold)
          
          billing =  "#{bill_address.firstname} #{bill_address.lastname}"
          billing << "\n#{bill_address.address1}"
          billing << "\n#{bill_address.address2}" unless bill_address.address2.blank?
          billing << "\n#{bill_address.city}, #{bill_address.state_text} #{bill_address.zipcode}"
          billing << "\n#{bill_address.country.name}"
          billing << "\n#{bill_address.phone}"
          
          shipping =  "#{ship_address.firstname} #{ship_address.lastname}"
          shipping << "\n#{ship_address.address1}"
          shipping << "\n#{ship_address.address2}" unless ship_address.address2.blank?
          shipping << "\n#{ship_address.city}, #{ship_address.state_text} #{ship_address.zipcode}"
          shipping << "\n#{ship_address.country.name}"
          shipping << "\n#{ship_address.phone}"
          shipping << "\n\n#{Spree.t(:via, scope: :print_invoice)} #{printable.shipping_methods.join(", ")}"
          
          data = [[address_cell_billing, address_cell_shipping], [billing, shipping]]
          
          pdf.table(data, position: :center, column_widths: [pdf.bounds.width / 2, pdf.bounds.width / 2])
        end
      
        pdf.move_down 10
      
        header = [
          pdf.make_cell(content: Spree.t(:qty)),
          pdf.make_cell(content: Spree.t(:item_description)),
          pdf.make_cell(content: Spree.t(:options)),
          pdf.make_cell(content: Spree.t(:price)),
          pdf.make_cell(content: Spree.t(:total))
        ]
        data = [header]

        invoice.items.each do |item|
          row = [
            item.quantity,
            item.name,
            item.options_text,
            item.display_price.to_s,
            item.display_total.to_s
          ]
    
          # Verificar si el item es parte de un bundle
          if item.parts.present?
            item.parts.each do |part|
              part_name = part.name
              bundle_info = Spree.t(:part_of_bundle, sku: item.sku)
              bundle_options = item.options_text.present? ? " (#{item.options_text})" : ""
              bundle_details = "#{bundle_info}"
    
              row[1] += "\n\n#{item.quantity}x #{part_name} #{bundle_details}"
            end
          end
    
          data << row
        end
        
        column_widths = [0.07, 0.43, 0.30, 0.1, 0.1].map { |w| w * pdf.bounds.width }
        
        pdf.table(data, header: true, position: :center, column_widths: column_widths) do
          row(0).style align: :center, font_style: :bold
          column(0..2).style align: :left
          column(3..6).style align: :right
        end
      
        pdf.move_down 10
      
        # TOTALS
        totals = []

        # Subtotal
        totals << [pdf.make_cell(content: Spree.t(:subtotal)), invoice.display_item_total.to_s]

        # Adjustments
        invoice.adjustments.each do |adjustment|
          totals << [pdf.make_cell(content: adjustment.label), adjustment.display_amount.to_s]
        end

        # Shipments
        invoice.shipments.each do |shipment|
          totals << [pdf.make_cell(content: shipment.shipping_method.name), shipment.display_cost.to_s]
        end

        # Totals
        #totals << [pdf.make_cell(content: Spree.t(:order_total)), invoice.display_total.to_s]
        totals << [pdf.make_cell(content: Spree.t(:order_total), size: 16, font_style: :bold), pdf.make_cell(content: invoice.display_total.to_s, size: 16, font_style: :bold)]


        # Payments
        #total_payments = 0.0
        #invoice.payments.completed.each do |payment|
        #  totals << [
        #    pdf.make_cell(
        #      content: Spree.t(:payment_via,
        #      gateway: (payment.source_type || Spree.t(:unprocessed, scope: :print_invoice)),
        #      number: payment.number,
        #      date: I18n.l(payment.updated_at.to_date, format: :long),
        #      scope: :print_invoice)
        #    ),
        #    payment.display_amount.to_s
        #  ]
        #  total_payments += payment.amount
        #end

        totals_table_width = [0.875, 0.125].map { |w| w * pdf.bounds.width }
        pdf.table(totals, column_widths: totals_table_width) do
          row(0..6).style align: :right
          column(0).style borders: [], font_style: :bold
        end
      
        pdf.move_down 30
      
        pdf.text Spree::PrintInvoice::Config[:return_message], align: :right, size: font_style[:size]
      end
      
      # Footer
      if Spree::PrintInvoice::Config[:use_footer]
        pdf.repeat(:all) do
          pdf.grid([7,0], [7,4]).bounding_box do
        
            data  = []
            data << [pdf.make_cell(content: Spree.t(:vat, scope: :print_invoice), colspan: 2, align: :center)]
            data << [pdf.make_cell(content: '', colspan: 2)]
            data << [pdf.make_cell(content: Spree::PrintInvoice::Config[:footer_left],  align: :left),
            pdf.make_cell(content: Spree::PrintInvoice::Config[:footer_right], align: :right)]
        
            pdf.table(data, position: :center, column_widths: [pdf.bounds.width / 2, pdf.bounds.width / 2]) do
              row(0..2).style borders: []
            end
          end
        end
      end
      
      # Page Number
      if Spree::PrintInvoice::Config[:use_page_numbers]
        string  = "#{Spree.t(:page, scope: :print_invoice)} <page> #{Spree.t(:of, scope: :print_invoice)} <total>"

        options = {
          at: [pdf.bounds.right - 155, 0],
          width: 150,
          align: :right,
          start_count_at: 1,
          color: '000000'
        }
        
        pdf.number_pages string, options
      end
      
      pdf.render
    end

    def packaging_slip_template
      doc = self
      printable = doc
      invoice = doc

      font_style = {
        face: Spree::PrintInvoice::Config[:font_face],
        size: Spree::PrintInvoice::Config[:font_size]
      }

      pdf = Prawn::Document.new
      pdf.font_families.update(Spree::PrintInvoiceSetting.additional_fonts)
      pdf.define_grid(columns: 5, rows: 8, gutter: 10)
      pdf.font font_style[:face], size: font_style[:size]
    
      pdf.repeat(:all) do
        #im = (Rails.application.assets || ::Sprockets::Railtie.build_environment(Rails.application)).find_asset(Spree::PrintInvoice::Config[:logo_path])
        logo_path = Rails.root.join('app', 'assets', 'images', Spree::PrintInvoice::Config[:logo_path])

        if File.exist?(logo_path)
          pdf.image logo_path, vposition: :top, height: 40, scale: Spree::PrintInvoice::Config[:logo_scale]
        end
        
        pdf.grid([0,3], [1,4]).bounding_box do
          pdf.text Spree.t(printable.document_type, scope: :print_invoice), align: :right, style: :bold, size: 18
          pdf.move_down 4
        
          pdf.text Spree.t(:invoice_number, scope: :print_invoice, number: printable.number), align: :right
          pdf.move_down 2
          pdf.text Spree.t(:invoice_date, scope: :print_invoice, date: I18n.l(printable.date)), align: :right
        end
        
      end
    
      # CONTENT
      pdf.grid([1,0], [6,4]).bounding_box do
    
        # address block on first page only
        if pdf.page_number == 1
          bill_address = printable.bill_address
          ship_address = printable.ship_address
          
          pdf.move_down 2
          address_cell_billing  = pdf.make_cell(content: Spree.t(:billing_address), font_style: :bold)
          address_cell_shipping = pdf.make_cell(content: Spree.t(:shipping_address), font_style: :bold)
          
          billing =  "#{bill_address.firstname} #{bill_address.lastname}"
          billing << "\n#{bill_address.address1}"
          billing << "\n#{bill_address.address2}" unless bill_address.address2.blank?
          billing << "\n#{bill_address.city}, #{bill_address.state_text} #{bill_address.zipcode}"
          billing << "\n#{bill_address.country.name}"
          billing << "\n#{bill_address.phone}"
          
          shipping =  "#{ship_address.firstname} #{ship_address.lastname}"
          shipping << "\n#{ship_address.address1}"
          shipping << "\n#{ship_address.address2}" unless ship_address.address2.blank?
          shipping << "\n#{ship_address.city}, #{ship_address.state_text} #{ship_address.zipcode}"
          shipping << "\n#{ship_address.country.name}"
          shipping << "\n#{ship_address.phone}"
          shipping << "\n\n#{Spree.t(:via, scope: :print_invoice)} #{printable.shipping_methods.join(", ")}"
          
          data = [[address_cell_billing, address_cell_shipping], [billing, shipping]]
          
          pdf.table(data, position: :center, column_widths: [pdf.bounds.width / 2, pdf.bounds.width / 2])
          
        end
    
        pdf.move_down 10
    
        header =  [
          pdf.make_cell(content: Spree.t(:sku)),
          pdf.make_cell(content: Spree.t(:qty)),
          pdf.make_cell(content: Spree.t(:item_description)),
          pdf.make_cell(content: Spree.t(:options))
        ]
        data = [header]

        printable.items.each do |item|
          row = [
            item.sku,
            item.quantity,
            item.name,
            item.options_text
          ]
    
          # Verificar si el item es parte de un bundle
          if item.parts.present?
            item.parts.each do |part|
              part_name = part.name
              bundle_info = Spree.t(:part_of_bundle, sku: item.sku)
              bundle_options = item.options_text.present? ? " (#{item.options_text})" : ""
              bundle_details = "#{bundle_info}"
    
              row[1] += "\n\n#{item.quantity}x #{part_name} #{bundle_details}"
            end
          end
    
          data << row
        end
        
        column_widths = [0.125, 0.075, 0.55, 0.25].map { |w| w * pdf.bounds.width }
        
        pdf.table(data, header: true, position: :center, column_widths: column_widths) do
          row(0).style align: :center, font_style: :bold
          column(0..2).style align: :left
          column(3).style align: :center
        end
        
    
        pdf.move_down 30
        pdf.text Spree::PrintInvoice::Config[:anomaly_message], align: :left, size: font_style[:size]
    
        pdf.move_down 20
        pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 250) do
          pdf.transparent(0.5) { pdf.stroke_bounds }
        end
      end
    
      # Footer
      if Spree::PrintInvoice::Config[:use_footer]
        pdf.repeat(:all) do
          pdf.grid([7,0], [7,4]).bounding_box do
        
            data  = []
            data << [pdf.make_cell(content: Spree.t(:vat, scope: :print_invoice), colspan: 2, align: :center)]
            data << [pdf.make_cell(content: '', colspan: 2)]
            data << [pdf.make_cell(content: Spree::PrintInvoice::Config[:footer_left],  align: :left),
            pdf.make_cell(content: Spree::PrintInvoice::Config[:footer_right], align: :right)]
        
            pdf.table(data, position: :center, column_widths: [pdf.bounds.width / 2, pdf.bounds.width / 2]) do
              row(0..2).style borders: []
            end
          end
        end
        
      end
    
      # Page Number
      if Spree::PrintInvoice::Config[:use_page_numbers]
        string  = "#{Spree.t(:page, scope: :print_invoice)} <page> #{Spree.t(:of, scope: :print_invoice)} <total>"

        options = {
          at: [pdf.bounds.right - 155, 0],
          width: 150,
          align: :right,
          start_count_at: 1,
          color: '000000'
        }
        
        pdf.number_pages string, options
        
      end
      
      pdf.render
    end

    def copy_view_attributes
      PERSISTED_ATTRS.each do |attr|
        send("#{attr}=", view.send(attr))
      end
    end

    # For a Spree::Order printable and an "invoice" template,
    # you would get "spree/documents/order/invoice_view"
    # --> Spree::Printables::Order::InvoiceView
    #
    def view_class
      @_view_class ||= "#{template_name}_view".classify.constantize
    end

    def single_lower_case_name(class_string)
      @_single_lower_class_name ||= class_string.demodulize.tableize.singularize
    end

    # Sends stored pdf for given template from disk.
    #
    # Renders and stores it if it's not yet present.
    #
    def send_or_create_pdf
      unless File.exist?(file_path)
        File.open(file_path, 'wb') { |f| f.puts render_pdf }
      end

      IO.binread(file_path)
    end
  end
end
