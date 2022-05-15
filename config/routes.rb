Rails.application.routes.draw do
  get 'top/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root "eat_records#index"
  #root to: 'top#index'
  
  resources :eat_records do
    collection do
      get 'stat'
      get 'manifest'
    end
    #get "eat_records", to: "eat_records#index"
    #get "eat_records/:id", to: "eat_records#show"
  end

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
end
