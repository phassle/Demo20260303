Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :properties, only: [:index, :show] do
        resources :work_orders, only: [:index, :create, :update]
      end
      resources :work_orders, only: [:index]
    end
  end
end
