Rails.application.config.after_initialize do
  Rails.application.config.spree_backend.main_menu.add(
    Spree::Admin::MainMenu::SectionBuilder.new('documents', 'file.svg').
      with_admin_ability_check(Spree::Order).
      with_items(
        Spree::Admin::MainMenu::ItemBuilder.new('invoices', Spree::Core::Engine.routes.url_helpers.admin_bookkeeping_documents_path(q: { template_eq: 'invoice' })).build,
        Spree::Admin::MainMenu::ItemBuilder.new('packaging_slips', Spree::Core::Engine.routes.url_helpers.admin_bookkeeping_documents_path(q: { template_eq: 'packaging_slip' })).build
      ).
      build
  )
end

