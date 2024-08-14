module Spree
  module Admin
    class BookkeepingDocumentsController < ResourceController
      before_action :load_order, if: :order_focused?

      helper_method :order_focused?

      require 'open-uri'
      require 'combine_pdf'
      require 'axlsx'

      def show
        respond_with(@bookkeeping_document) do |format|
          format.pdf do
            send_data @bookkeeping_document.pdf, filename: "document.pdf", type: "application/pdf", disposition: "inline"
          end
        end
      end

      def index
        # Inicializa los parámetros de búsqueda si no están definidos
        params[:q] ||= {}
        
        # Configura el orden predeterminado a 'created_at desc' si no se ha establecido
        params[:q][:s] ||= 'number asc'
        
        # Configura el filtro predeterminado para la fecha de creación al día actual si no se ha establecido
        if params[:q][:created_at_gt].blank?
          params[:q][:created_at_gt] = Time.current.beginning_of_day
        end

        if params[:q][:template_eq].blank?
          params[:q][:template_eq] = 'invoice'
        end

        @search = Spree::BookkeepingDocument.ransack(params[:q])
        @bookkeeping_documents = @search.result
      
        @bookkeeping_documents = @bookkeeping_documents.where(printable: @order) if order_focused?
        
        # Apply manual shipment state filter if provided and if the `printable` is an `Spree::Order`
        if params[:shipment_state_eq].present?
          @bookkeeping_documents = @bookkeeping_documents.select do |doc|
            doc.printable_type == 'Spree::Order' && doc.printable.shipment_state == params[:shipment_state_eq]
          end
          # Reapply pagination to the array
          @bookkeeping_documents = Kaminari.paginate_array(@bookkeeping_documents).page(params[:page] || 1).per(50)
        else
          @bookkeeping_documents = @bookkeeping_documents.page(params[:page] || 1).per(50)
        end
      end

      def refresh
        unless @order.nil?
          @order.bookkeeping_documents.delete_all
          @order.invoice_for_order
        end
        redirect_to action: 'index'
      end

      def combine_and_print
        document_ids = params[:document_ids]

        if document_ids.blank?
          flash[:error] = 'No documents have been selected.'
          redirect_back(fallback_location: admin_bookkeeping_documents_path) and return
        end

        combined_pdf = CombinePDF.new

        document_ids.each do |id|
          document = Spree::BookkeepingDocument.find(id)
          pdf = document.pdf
          combined_pdf << CombinePDF.parse(pdf)
        end

        send_data combined_pdf.to_pdf, filename: 'combined_documents.pdf', type: 'application/pdf', disposition: 'inline'
      end

      def export_to_excel
        document_ids = params[:document_ids]
        documents = BookkeepingDocument.where(id: document_ids)
    
        p = Axlsx::Package.new
        wb = p.workbook
    
        wb.add_worksheet(name: "Documents") do |sheet|
          sheet.add_row ["ORDER ID", "EMAIL", "DATE", "FULL NAME", "COMPANY", "STREET ADDRESS 1", "CITY", "STATE/PROVINCE", "ZIP CODE", "PRODUCT COUNT"]

          total_items_per_article = 0

          documents.each do |doc|
            doc.items.each do |item|
              total_items_per_article += item.quantity
            end

            sheet.add_row [
              doc.number,
              doc.email,
              doc.created_at.to_date.to_s,
              "#{doc.firstname} #{doc.lastname}",
              "",
              doc.ship_address.address1,
              doc.ship_address.city,
              doc.ship_address.state.name,
              doc.ship_address.zipcode,
              total_items_per_article
            ]

            total_items_per_article = 0
          end
        end
    
        send_data p.to_stream.read, type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", filename: "selected_documents.xlsx"
      end

      private

      def order_focused?
        params[:order_id].present?
      end

      def load_order
        @order = Spree::Order.find_by(number: params[:order_id])
      end
    end
  end
end
