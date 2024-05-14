require 'spree_core'
require 'spree_print_invoice/engine'
require 'spree_print_invoice/version'
require 'prawn-rails'
require 'spree_print_invoice/prawn_rails_configuration'
require 'spree_extension'
require 'deface'

module SpreePrintInvoice
  def self.setup
    yield Config
  end
end