Rails.application.routes.draw do
  post 'register', to: 'users#register'
  # delete 'unregister', to: 'users@unregister'
  post 'login', to: 'users#login'
  get 'auto_login', to: 'users#auto_login'

  resources :users, only: %i(destroy) do
    resources :images, except: %i(edit, update)
  end
end
