Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root "eat_records#index"

  resources :eat_records
  #get "eat_records", to: "eat_records#index"
  #get "eat_records/:id", to: "eat_records#show"
end
