Rails.application.config.after_initialize do

  items = [
  	Spree::Admin::MainMenu::ItemBuilder.new(Spree.t(:invoices, scope: [:admin.tab]), Spree::Core::Engine.routes.url_helpers.admin_bookkeeping_documents_path(q: { template_eq: 'invoice' })).build,
    Spree::Admin::MainMenu::ItemBuilder.new(Spree.t(:packaging_slips, scope: [:admin.tab]), Spree::Core::Engine.routes.url_helpers.admin_bookkeeping_documents_path(q: { template_eq: 'packaging_slip' })).build
  ]

  Rails.application.config.spree_backend.main_menu.add(
    Spree::Admin::MainMenu::SectionBuilder.new(Spree.t(:documents, scope: [:print_invoice]), 'file.svg').
      with_admin_ability_check(Spree::Order).
      with_items(items).
      build
  )
end
