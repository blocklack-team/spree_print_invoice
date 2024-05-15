module Spree
  module Admin
    class BookkeepingDocumentsController < ResourceController
      before_action :load_order, if: :order_focused?

      helper_method :order_focused?

      def show
        respond_with(@bookkeeping_document) do |format|
          format.pdf do
            send_data @bookkeeping_document, type: 'application/pdf', disposition: 'inline'
          end
        end
      end

      def show
        respond_to do |format|
          format.pdf do
            pdf = Prawn::Document.new
            # Aquí agregarías el contenido de tu PDF utilizando Prawn
            pdf.text "Hello, PDF!"

            pdf.font_families.update(Spree::PrintInvoiceSetting.additional_fonts)
            pdf.define_grid(columns: 5, rows: 8, gutter: 10)
            pdf.font font_style[:face], size: font_style[:size]
          
            pdf.repeat(:all) do
              render 'spree/printables/shared/header', pdf: pdf, printable: doc
            end
          
            # CONTENT
            pdf.grid([1,0], [6,4]).bounding_box do
          
              # address block on first page only
              if pdf.page_number == 1
                #render 'spree/printables/shared/address_block', pdf: pdf, printable: doc
              end
          
              pdf.move_down 10
          
              #render 'spree/printables/shared/invoice/items', pdf: pdf, invoice: doc
          
              pdf.move_down 10
          
              #render 'spree/printables/shared/totals', pdf: pdf, invoice: doc
          
              pdf.move_down 30
          
              pdf.text Spree::PrintInvoice::Config[:return_message], align: :right, size: font_style[:size]
            end
          
            # Footer
            if Spree::PrintInvoice::Config[:use_footer]
              #render 'spree/printables/shared/footer', pdf: pdf
            end
          
            # Page Number
            if Spree::PrintInvoice::Config[:use_page_numbers]
              #render 'spree/printables/shared/page_number', pdf: pdf
            end
            
            send_data pdf.render, filename: "document.pdf", type: "application/pdf", disposition: "inline"
          end
        end
      end

      def index
        # Massaging the params for the index view like Spree::Admin::Orders#index
        params[:q] ||= {}
        @search = Spree::BookkeepingDocument.ransack(params[:q])
        @bookkeeping_documents = @search.result
        @bookkeeping_documents = @bookkeeping_documents.where(printable: @order) if order_focused?
        @bookkeeping_documents = @bookkeeping_documents.page(params[:page] || 1).per(10)
      end

      def refresh
        unless @order.nil?
          @order.bookkeeping_documents.delete_all
          @order.invoice_for_order
        end
        redirect_to action: 'index'
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
