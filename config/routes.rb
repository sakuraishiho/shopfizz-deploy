require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :admins, controllers: {
    sessions: 'admin/sessions'
  }
  devise_for :customers, controllers: {
    sessions: 'customer/sessions',
    registrations: 'customer/registrations'
  }
  root to: 'pages#home'
  namespace :admin do
    root to: 'pages#home'
    resources :products, only: %i[index show new create edit update destroy]
    resources :orders, only: %i[show update]
    resources :customers, only: %i[index show update]
    authenticate :admin do
      mount Sidekiq::Web => '/sidekiq'
    end
  end

  scope module: :customer do
    resources :products, only: %i[index show] do
      resources :reviews, only: %i[index create]
    end
    resources :contacts, only: %i[new create]
    resources :cart_items, only: %i[index create destroy] do
      member do
        patch 'increase'
        patch 'decrease'
      end
    end
    resources :checkouts, only: [:create]
    resources :webhooks, only: [:create]
    resources :orders, only: %i[index show] do
      collection do
        get 'success'
      end
    end
    resources :customers do
      collection do
        get 'confirm_withdraw'
        patch 'withdraw'
      end
    end
  end

  get '/up/', to: 'up#index', as: :up
  get '/up/databases', to: 'up#databases', as: :up_databases
  match '/500', to: 'application#render500', via: :all
  match '/404', to: 'application#render404', via: :all
  get 'test_render500', to: 'error/errors#test_render500'
end
