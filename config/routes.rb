Spree::Core::Engine.add_routes do
  namespace :admin do
    resources :orders do
      resources :bookkeeping_documents, only: :index do
        get 'refresh', on: :collection
      end
    end

    resource :print_invoice_settings, only: [:edit, :update]
    resources :bookkeeping_documents, only: [:index, :show] do
      collection do
        post :combine_and_print
      end
    end
  end
end
