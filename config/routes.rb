Rails.application.routes.draw do
  get "/health", to: "health#show"
  get "/health/ready", to: "health#ready"
  get "/dashboard", to: "dashboard#index"
end
