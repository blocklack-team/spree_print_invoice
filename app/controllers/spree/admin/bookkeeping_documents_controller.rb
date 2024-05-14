module Spree
  module Admin
    class BookkeepingDocumentsController < ResourceController
      before_action :load_order, if: :order_focused?

      helper_method :order_focused?

      def show
        @bookkeeping_document = Spree::BookkeepingDocument.find(params[:id])

        respond_to do |format|
          format.html
          format.pdf do
            #send_data @bookkeeping_document.pdf, type: 'application/pdf', disposition: 'inline'
            send_data filename: "bookkeeping_document_#{@bookkeeping_document.id}.pdf",
                                  type: 'application/pdf',
                                  disposition: 'inline'
          end
        end
      end

      def index
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

      def generate_pdf(bookkeeping_document)
        Prawn::Document.new do
          text "Document ##{bookkeeping_document.id}", size: 30, style: :bold
          move_down 20
          text "Details: #{bookkeeping_document.details}"
          # Agrega más contenido según sea necesario
        end
      end
    end
  end
end
