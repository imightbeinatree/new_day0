# Probably call this Providerable, and pass the provider name into these methods to make them generic

module Facebookable
  extend ActiveSupport::Concern

  def set_fb_stored_location(local_path)
    session["fb_callback_return_to"] = local_path
  end

  def get_fb_callback_return_to
    return_path = session["fb_callback_return_to"]
    session["fb_callback_return_to"] = nil
    return_path
  end
  
  def get_facebook_user_session(user)
    if session[:facebook_auth].present?
      user.first_name = session[:facebook_auth][:first_name] if session[:facebook_auth][:first_name].present? && user.first_name.nil?
      user.last_name = session[:facebook_auth][:last_name] if session[:facebook_auth][:last_name].present? && user.last_name.nil?
      if session[:facebook_auth][:birth_date].to_date.present? && user.birth_date.nil?
        user.birth_date = session[:facebook_auth][:birth_date].to_date
        user.birth_date_year = user.birth_date.year
        user.birth_date_month = user.birth_date.month
        user.birth_date_day = user.birth_date.day
      end
      user.email = session[:facebook_auth][:email] if session[:facebook_auth][:email].present?
      # user.picture = URI.parse(session[:facebook_auth][:picture]) if session[:facebook_auth][:picture] && user.picture_file_name.nil?
      # Rails.logger.info "\n\nuser.picture: #{user.picture.inspect}\n\n"
    end
    user
  end
  
  def get_facebook_user_authentication_session(user)
    if session[:facebook_auth].present? && session[:facebook_auth][:user_authentication].present?
      user_authentication = Provider::Authentication.new()
      user_authentication.token = session[:facebook_auth][:user_authentication][:token]
      user_authentication.refresh_token = session[:facebook_auth][:user_authentication][:refresh_token]
      user_authentication.secret = session[:facebook_auth][:user_authentication][:secret]
      user_authentication.uid = session[:facebook_auth][:user_authentication][:uid]
      user_authentication.authenticateable = user
      user_authentication.expires_at = session[:facebook_auth][:user_authentication][:expires_at]
      user_authentication.provider_id = session[:facebook_auth][:user_authentication][:provider_id]
      user_authentication
    else
      nil
    end
  end
  
  def clear_facebook_auth_session
    session[:facebook_auth] = nil if session[:facebook_auth].present?
    session[:connection_auth_msg] = nil if session[:connection_auth_msg].present?
    session["fb_callback_return_to"] = nil if session["fb_callback_return_to"].present?
  end
  
  def set_fb_friends
    if @providers_hash[:facebook].present? && @authentications_hash[:facebook].present? && @authentications_hash[:facebook][:token].present?
      fb_friends = @providers_hash[:facebook].get_friends(@authentications_hash[:facebook][:token], @authentications_hash[:facebook][:secret], @authentications_hash[:facebook][:refresh_token])
      
      if fb_friends.present?
        fb_friends = fb_friends["data"].reject {|friend| friend if friend["uid"] == @authentications_hash[:facebook][:uid]}
        @fb_friends = {}
        ("A".."Z").to_a.each do |letter|
          if fb_friends.present?
            @fb_friends[letter] = fb_friends.select { |friend| friend["name"][0].downcase == letter.downcase}
          else 
            @fb_friends[letter] = {}
          end
        end
      else
        # False vs nil matters here for knowing if we've auth'ed yet, or if our tokens have expired.
        # nil means we haven't auth'ed yet
        # false means something is wrong with our tokens and we need to prompt a reauth
        @fb_friends = fb_friends
      end
    end
  end
end