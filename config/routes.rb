Rails.application.routes.draw do
  get '/healthcheck', to: 'health_check#index'
  get "up" => "rails/health#show", as: :rails_health_check
  post '/new_liquidity_request', to: 'liquidity_request#new_liquidity_request'
  post '/create_liquidity_request', to: 'liquidity_request#create_liquidity_request'

  resources :senders do
    collection do
      post :search
    end
  end
end
