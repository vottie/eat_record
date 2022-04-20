Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  # Defines the root path route ("/")
  # root "articles#index"
  root "eat_records#index"

  resources :eat_records do
    collection do
      get 'stat'
    end
    #get "eat_records", to: "eat_records#index"
    #get "eat_records/:id", to: "eat_records#show"
  end
end
