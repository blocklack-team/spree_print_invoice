module Spree
  class Printables::Order::InvoiceView < Printables::Invoice::BaseView
    def_delegators :@printable,
                   :email,
                   :bill_address,
                   :ship_address,
                   :tax_address,
                   :item_total,
                   :total,
                   :comment,
                   :payments,
                   :shipments

    def items
      printable.line_items.map do |item|
        Spree::Printables::Invoice::Item.new(
          variant_id: item.variant.id,
          product_id: item.variant.product_id,
          sku: item.variant.product.sku,
          name: item.variant.name,
          options_text: item.variant.options_text,
          price: item.price,
          quantity: item.quantity,
          total: item.total,
          parts: item.variant.parts
        )
      end
    end

    def firstname
      printable.tax_address.firstname
    end

    def lastname
      printable.tax_address.lastname
    end

    private

    def all_adjustments
      printable.all_adjustments.eligible
    end
  end
end
