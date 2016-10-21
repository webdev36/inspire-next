require 'sidekiq/web'

Liveinspired::Application.routes.draw do

  mount Sidekiq::Web => '/sidekiq'

  root :to => "home#index"
  devise_for :users
  resources :channels do
    member do
      get 'list_subscribers'
      get 'messages_report'
    end
    resources :messages do
      member do
        post 'broadcast'
        post 'move_up'
        post 'move_down'
        get 'responses'
      end
      collection do
        get 'select_import'
        post 'import'
      end
      resources :response_actions do
        collection do
          get 'select_import'
          post 'import'
        end

      end
    end
  end
  post 'channels/:channel_id/add_subscriber/:id',    to: 'channels#add_subscriber',    :as => 'channel_add_subscriber'
  post 'channels/:channel_id/remove_subscriber/:id', to: 'channels#remove_subscriber', :as => 'channel_remove_subscriber'

  resources :channel_groups, :except => [:index] do
    member do
      get 'messages_report'
    end
  end
  post 'channel_groups/:channel_group_id/remove_channel/:id', to: 'channel_groups#remove_channel',  :as => 'channel_group_remove_channel'


  resources :users
  resources :subscribers do
  end
  resources :subscriber_activities,:except=>[:new,:create,:destroy] do
    member do
      post 'reprocess'
    end
  end

  resources :downloads, only: [:index]

  match 'subscribe/:channel_group_id' => "home#new_web_subscriber", :via => [:get, :post]
  match 'thank_you' => "home#sign_up_success", via: [:get]
  match 'twilio' =>'twilio#callback', :via => [:post]

  match 'help/user_show',            via: [:get]
  match 'help/edit_channel',         via: [:get]
  match 'help/edit_message',         via: [:get]
  match 'help/index_channels',       via: [:get]
  match 'help/edit_response_action', via: [:get]
  match 'help/glossary',             via: [:get]

end
