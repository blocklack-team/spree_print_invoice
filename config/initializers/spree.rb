Spree::Backend::Config.configure do |config|
	config.menu_items << config.class::MenuItem.new(
		[:documents],          # Icono del menú (debe ser un símbolo)
		'#sidebar-documents',  # Ruta que actúa como ancla para el submenú
		label: Spree.t(:documents, scope: [:print_invoice]), # Texto que aparecerá en el menú
		condition: -> { can?(:admin, Spree::Order) }, # Condición para mostrar el ítem
		icon: 'file.svg',      # Icono para el menú (debe estar en la carpeta de iconos)
		sub_menu: 'documents_sub_menu'
	)
end
