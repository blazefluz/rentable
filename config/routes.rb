Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root path
  root "products#index"

  # Products
  resources :products do
    member do
      get :availability
    end
  end

  # Kits
  resources :kits do
    member do
      get :availability
    end
  end

  # Bookings
  resources :bookings do
    member do
      patch :confirm
      patch :cancel
      patch :complete
    end
    collection do
      get :check_availability
    end
  end
end
