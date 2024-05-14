module SpreePrintInvoice
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_print_invoice'

    config.autoload_paths += %W(#{config.root}/lib)

    initializer 'spree_print_invoice.environment', before: :load_config_initializers do
      SpreePrintInvoice::Config = SpreePrintInvoice::Configuration.new
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end
    
    config.menu_items << config.class::MenuItem.new(
      [:documents],          # Icono del menú (debe ser un símbolo)
      '#sidebar-documents',  # Ruta que actúa como ancla para el submenú
      label: Spree.t(:documents, scope: [:print_invoice]), # Texto que aparecerá en el menú
      condition: -> { can?(:admin, Spree::Order) }, # Condición para mostrar el ítem
      icon: 'file.svg',      # Icono para el menú (debe estar en la carpeta de iconos)
      sub_menu: 'documents_sub_menu'
    )
    
    config.to_prepare(&method(:activate).to_proc)
  end
end
