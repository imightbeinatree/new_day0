

  class OmniauthCallbacksController < Devise::OmniauthCallbacksController

    include Facebookable
    
    #
    # callback failure from omniauth
    #
    def failure
      flash[:error] = "Could not authenticate with #{params[:strategy]}"
      return redirect_to "/"
    end

    def create
      #------------------------------------------------
      # Grab infor from omniauth auth_hash and create an
      # Authentication
      #-------------------------------------------------
      
      #--------------------------------------------------
      # PROVIDER SPECIFIC MODIFICATIONS TO THE TOKEN HASH
      #--------------------------------------------------
      if provider.name == 'facebook'
        facebook_authed()
      end
    end

#
# BEGIN PROTECTED METHODS
#

  protected
    def auth_hash
      request.env['omniauth.auth']
    end

    def auth_info
      return auth_hash().info
    end

    def auth_uid
      return auth_hash().uid
    end

    #
    #@return [Provider]
    #
    def provider
      return ::Provider::Provider.find_by_name(auth_hash.provider)
    end
    
    def auth_and_sign_in_user(obj)
      #  assign authentication
      Authentication.create_or_update_by_uid_and_provider_id(auth_hash_attrs.merge!({authenticatable_id: obj.id, authenticatable_type: obj.class.name}))
      #  signin user
      sign_in(obj.class.name.underscore.downcase.to_sym, obj)
      #  see if we have a stored location
      stored_location = stored_location_for(obj)
      if stored_location.present?
        redirect_path = stored_location
      else
        fb_callback_return_to = get_fb_callback_return_to()
        #  if no stored location, send them to their wall
        if fb_callback_return_to.present?
          redirect_path = fb_callback_return_to
        else
          redirect_path = main_app.root_path
        end
      end
      return render json: {redirect_path: redirect_path }
    end
    
    def auth_hash_attrs
      token = auth_hash().credentials.token
      secret = auth_hash().credentials.secret
      refresh_token = auth_hash().credentials.refresh_token
      expires_at = !auth_hash().credentials.expires_at.blank? ? Time.at(auth_hash().credentials.expires_at) : nil
      
      return {token: token,
             refresh_token: refresh_token,
             secret: secret,
             uid: auth_uid,
             provider_id: provider.id,
             expires_at: expires_at}
    end
    
    def assign_user_attrs_and_save(u)
      u.first_name = auth_info.first_name if auth_info.first_name.present?
      u.last_name = auth_info.last_name if auth_info.last_name.present?
      u.birth_date = auth_hash.extra.raw_info.birthday.to_date if auth_hash.extra.raw_info.birthday
      # validate false on this otherwise zipcode and other required fields on user throw errors
      u.save(validate: false)
    end
    
    # Set a session based on the information from the Facebook oauth response to populate a User object
    def set_facebook_user_session
        session[:facebook_auth] = {}.tap do |fa|
          fa[:first_name] = auth_info.first_name
          fa[:last_name]  = auth_info.last_name
          fa[:email]      =  auth_info.email
          fa[:picture]      =  auth_info.image
          fa[:birth_date] = auth_hash.extra.raw_info.birthday
        end
        set_facebook_user_authentication_session()
      end

    # Set a session based on the information from the Facebook oauth response to populate a UserAuthentication object
    def set_facebook_user_authentication_session
      session[:facebook_auth][:user_authentication] = {}.tap do |ua|
        expires_at = !auth_hash().credentials.expires_at.blank? ? Time.at(auth_hash().credentials.expires_at) : nil
        ua[:token]         = auth_hash().credentials.token
        ua[:refresh_token] = auth_hash().credentials.refresh_token
        ua[:secret]        = auth_hash().credentials.secret
        ua[:uid]           = auth_uid
        ua[:provider_id]   = provider.id
        ua[:expires_at]    = expires_at
      end
    end

    def facebook_authed()
      # check for existing authentication for provider(facebook) uid
      # provider_authentication = ::Provider::Authentication.where("uid = ?", auth_uid).first
      provider_authentication = Authentication.find_by_uid_and_provider_id(auth_uid, provider.id)

      # get user from provider_authentication should it exist
      u = provider_authentication.present? ? provider_authentication.authenticatable : nil

      #  EXISTING AUTH
      if provider_authentication.present?
        #
        # if theyre trying to auth, and the fb acct is already authed to another user besides current_user
        # throw an error and ask them to sign out
        #
        if current_user && current_user.id != u.id
          flash[:error] = "The Facebook account you are trying to access is not authorized for this Uwithus account. Please login to your Facebook account and try again."
          redirect_path = session["fb_callback_return_to"].present? ? session["fb_callback_return_to"] : main_app.new_user_registration_path
          return render json: {redirect_path: redirect_path}
        else
          auth_and_sign_in_user(provider_authentication.authenticatable)
        end
        
        # else
          # TODO:  we have an authentication matching the uid, but no user matching the email
        # end
      #  NEW AUTH
      else
        #  HAVE USER?
        #  found user - not invited
        if u.present? && u.invitation_token.nil?
          auth_and_sign_in_user(u)
        #  found user - invited
        elsif u.present? && u.invitation_token.present?
          #  assign authentication
          Authentication.create_or_update_by_uid_and_provider_id(auth_hash_attrs.merge!({authenticatable_id: u.id, authenticatable_type: obj.class.name}))
          # complete registration
          assign_user_attrs_and_save(u)
          set_facebook_user_session()
          return render json: {redirect_path: "/#{u.class.name.pluralize.underscore}/sign_up?invitation_token=#{u.invitation_token}"}
        else
        #  DONT HAVE USER
        #    new user
        #    send to registration
        #    assign Autnetication after reg
        #    clear session after registration
          set_facebook_user_session()
          redirect_path = session["fb_callback_return_to"].present? ? session["fb_callback_return_to"] : main_app.new_user_registration_path
          return render json: {redirect_path: redirect_path}
        end
      end
    end
  #
  # END PROTECTED METHODS
  #

  end
