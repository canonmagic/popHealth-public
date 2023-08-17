Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root :to => 'home#index'

  apipie

  # devise_for :users, :controllers => {:registrations => "registrations"}
  devise_for :users, :controllers => {
    :registrations => "registrations",
    :omniauth_callbacks => 'azure_auth/omniauth_callbacks'  
    #:omniauth_callbacks => 'users/omniauth_callbacks' 
  }

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy' # This was neccesary, DELETE method is not working as intended
    get 'azure_auth/processLogin', to: 'azure_auth/omniauth_callbacks#logout_from_ad'
  end

  resources :practices

  resources :practices do
    collection do
      get :search
    end
  end

  get 'home/check_authorization'
  post 'home/set_reporting_period'

  get "admin/users"
  post "admin/promote"
  post "admin/demote"
  post "admin/approve"
  post "admin/disable"
  post "admin/update_npi"
  get "admin/patients"
  get "admin/jobs"
  put "admin/upload_patients"
  put "admin/upload_providers"
  delete "admin/remove_patients"
  delete "admin/remove_caches"
  delete "admin/remove_providers"
  delete "admin/remove_jobs"
  get "admin/user_profile"
  delete "admin/delete_user"
  post 'admin/set_user_practice'
  post 'admin/set_user_practice_provider'
  
  delete "practices/remove_patients"
  delete "practices/remove_providers"

  post "teams/:id/update", :to => 'teams#update'
  post "teams/create"
  post "teams/create_default"
  
  resources :practices

  namespace :admin do

    resource :caches do
      collection do
        get :count
        #get :spinner
        #get :static_measure
        #get 'static_measure/:id', :to => :static_measure
      end
    end

    resource :patients do
      collection do
        get :count
      end
    end
    resource :providers do
      collection do
        get :count
      end
    end
    resources :users do
      member do
        get :enable
        get :disable
        post :promote
        post :demote
        get :approve
        get :update_npi
      end
    end
  end

  resources :providers do
    resources :patients do
      collection do
        get :manage
        put :update_all
      end
    end

    get :measure_baseline

    member do
      get :merge_list
      put :merge
    end
  end

  resources :teams
  
  get "logs/index"

  namespace :api do
    
    resource :reports do
      get '*cat1.zip', :to =>'reports#cat1_zip', :format => :zip
      get 'cat1/:id/:measure_ids', :to =>'reports#cat1', :format => :xml
      get '*qrda_cat3.xml', :to =>'reports#cat3', :format => :xml
      get 'measures_spreadsheet', :to =>'reports#measures_spreadsheet'
      get 'patients', :to => 'reports#patients'
      get 'teams/team_providers/:id', :to => 'teams#team_providers'
      get 'team_report', :to => 'reports#team_report'
    end

    # The OID may contain periods, so specify a regex to allow that
    get 'value_sets/:oid', :to => 'value_sets#show', :oid => /([^\/])+?/, :format => :json

    resources :practices do
      collection do
        get :search
      end
    end

    resources :practices
    resources :teams

    resources :providers do
      collection do
        get :search
      end
      resources :patients do
        collection do
          get :manage
          put :update_all
        end
      end
    end

    resources :measures

    resources :queries do
      member do
       get :patients
       get :patient_results
       put :recalculate
       post :filter
       post :clearfilters
      end
    end

    namespace :admin do

      resource :caches do
        collection do
          get :count
          #get :spinner REMOVE ME
          #get :static_measure REMOVE ME
          #get 'static_measure/:id', :to => :static_measure REMOVE ME
        end
      end

      resource :patients do
        collection do
          get :count
        end
      end

      resource :providers do
        collection do
          get :count
        end
      end

      resources :users do
        member do
          get :enable
          get :disable
          post :promote
          post :demote
          get :approve
          get :update_npi
        end
      end
    end
  end
end
