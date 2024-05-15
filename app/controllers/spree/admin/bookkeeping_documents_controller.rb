module Spree
  module Admin
    class BookkeepingDocumentsController < ResourceController
      before_action :load_order, if: :order_focused?

      helper_method :order_focused?

      #def show
      #  respond_with(@bookkeeping_document) do |format|
      #    format.pdf do
      #      send_data @bookkeeping_document.pdf, type: 'application/pdf', disposition: 'inline'
      #    end
      #  end
      #end

      def show
        respond_to do |format|
          format.html
          format.pdf do
            pdf = generate_pdf(@bookkeeping_document)
            send_data pdf.render, filename: "document.pdf", type: "application/pdf", disposition: 'inline'
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

      def generate_pdf(bookkeeping_document)
        Prawn::Document.new do
          text "Hello, PDF!"
          text "Order ID: #{bookkeeping_document.number}"
          text "Document ID: #{bookkeeping_document.id}"
          text "Email: #{bookkeeping_document.email}"
          text "Name: #{bookkeeping_document.firstname}"
          # Añade más contenido aquí
        end
      end
    end
  end
end
