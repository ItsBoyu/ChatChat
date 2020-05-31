Rails.application.routes.draw do

  devise_for :users
  resources :keyword_mappings
  resources :push_messages, only: [:new, :create]

  get "/chatchat/eat", to: "chatchat#eat"
  get "/chatchat/request_headers", to: "chatchat#request_headers"
  post "/chatchat/webhook", to: "chatchat#webhook"
  
end
