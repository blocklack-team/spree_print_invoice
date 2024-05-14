items = [
	ItemBuilder.new('invoices', admin_bookkeeping_documents_path(q: { template_eq: 'invoice' })).build,
	ItemBuilder.new('packaging_slips', admin_bookkeeping_documents_path(q: { template_eq: 'packaging_slip' })).build
]

Rails.application.config.after_initialize do
  Rails.application.config.spree_backend.main_menu.add(
    Spree::Admin::MainMenu::SectionBuilder.new(Spree.t(:documents, scope: [:print_invoice]), 'file.svg').
      with_admin_ability_check(Spree::Order).
      with_items(items).
      build
  )
end
