module Spree
  class Printables::Invoice::Item
    extend Spree::DisplayMoney

    attr_accessor :variant_id, :product_id, :sku, :name, :options_text, :price, :quantity, :total, :variant, :product, :parts

    money_methods :price, :total

    def initialize(args = {})
      args.each do |key, value|
        send("#{key}=", value)
      end
    end
  end
end
