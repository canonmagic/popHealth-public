class Azure::OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def azure_activedirectory_v2
        puts 'AJA!!!!'
        response_params = request.env['omniauth.auth']['info']
        @user = User.find_by(email: response_params['email'])

        #abort request.env['omniauth.auth'].inspect

        if !@user.nil? || @user&.persisted?
            sign_in_and_redirect @user, event: :authentication
        else
            redirect_to azure_auth_processLogin_path
            #"https://login.windows.net/2159ca91-1fc3-43e2-8ade-4f1dbf0385c0/oauth2/logout?post_logout_redirect_uri=https://pophealthtest.com/azure_auth/processLogin"
            #redirect_to "https://login.windows.net/2159ca91-1fc3-43e2-8ade-4f1dbf0385c0/oauth2/logout?post_logout_redirect_uri=https://pophealthtest.com/users/sign_in"
        end
    end

    def logout
        
        abort request.env['omniauth.auth'].inspect

        flash[:alert] = "This Azure AD account does not exist on our system, please contact a administrator."
        redirect_to new_user_session_url
    end
end
