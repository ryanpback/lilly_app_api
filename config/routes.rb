Rails.application.routes.draw do
  post 'register', to: 'users#register'
  post 'login', to: 'users#login'
  get 'auto_login', to: 'users#auto_login'
end
