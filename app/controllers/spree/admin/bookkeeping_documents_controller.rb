module Spree
  module Admin
    class BookkeepingDocumentsController < ResourceController
      before_action :load_order, if: :order_focused?

      helper_method :order_focused?

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
        params[:q][:s] ||= 'created_at desc'
        
        # Configura el filtro predeterminado para la fecha de creación al día actual si no se ha establecido
        if params[:q][:created_at_gt].blank?
          params[:q][:created_at_gt] = Time.current.beginning_of_day
        end
      
        @search = Spree::BookkeepingDocument.ransack(params[:q])
        @bookkeeping_documents = @search.result
        @bookkeeping_documents = @bookkeeping_documents.where(printable: @order) if order_focused?
        @bookkeeping_documents = @bookkeeping_documents.page(params[:page] || 1).per(50)
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
