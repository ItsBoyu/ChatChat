Rails.application.routes.draw do

  get "/chatchat/eat", to: "chatchat#eat"
  get "/chatchat/request_headers", to: "chatchat#request_headers"
  post "/chatchat/webhook", to: "chatchat#webhook"
  
end
