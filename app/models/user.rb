class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_attached_file :image, styles: { thumb: '50x50#' }
  # Validate content type
  validates_attachment_content_type :image, :content_type => /\Aimage/
  # Validate filename
  validates_attachment_file_name :image, :matches => [/png\Z/, /jpe?g\Z/]
  
  # Assigns the image specified by the url to the user's paperclip managed image attrtibute
  # paperclip requires that the extension and mime type match
  # this code will rewrite the temp file to have an extension if one is missing
  # @param [String] url - the full URL of the image to be assigned as the user's image
  def image_from_url(url)
    unless url.blank?
      begin      
        extname = File.extname(url)
        basename = File.basename(url, extname)
        file = Tempfile.new([basename, extname])
        file.binmode
        open(URI.parse(url)) do |data|
          file.write data.read
        end
        file.rewind
        if extname.blank?
          mime = `file --mime -br #{file.path}`.strip
          mime = mime.gsub(/^.*: */,"")
          mime = mime.gsub(/;.*$/,"")
          mime = mime.gsub(/,.*$/,"")
          extname = "."+mime.split("/")[1]
          File.rename(file.path, file.path+extname)
          file = File.new(file.path+extname)
        end
      rescue Exception => e
        logger.info "EXCEPTION IMPORTING PHOTO"
        logger.info "for user: #{self.inspect}"
        logger.info "error: #{e.message}"
      end
      begin      
        self.image = file
      rescue Exception => e
        logger.info "EXCEPTION STORING PHOTO"
        logger.info "for user: #{self.inspect}"
        logger.info "error: #{e.message}"
      end
    end
  end

  
  # Takes in auth credentials returned from a Facebook login and finds or creates the User
  # If a matching User is found in the system, that User is returned
  # If no matching User is found in the system, a new User is created
  # @param [OmniAuth::AuthHash] auth - the returned hash of user information from the facebook login request
  def self.find_for_facebook_oauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |user|
      unless user.persisted?
        user.provider = auth.provider
        user.uid = auth.uid
        user.email = auth.info.email
        user.password = Devise.friendly_token[0,20]
        user.name = auth.info.name
        (user.first_name = auth.info.first_name) if auth.has_key?("info") && auth.info.has_key?("first_name")
        (user.last_name = auth.info.last_name) if auth.has_key?("info") && auth.info.has_key?("last_name")
        (user.username = auth.info.nickname) if auth.has_key?("info") && auth.info.has_key?("nickname")
        if auth.has_key?("extra") && auth.extra.has_key?("raw_info") && auth.extra.raw_info.has_key?("gender")
          user.gender = auth.extra.raw_info.gender
        end
        if auth.has_key?("extra") && auth.extra.has_key?("raw_info") && auth.extra.raw_info.has_key?("locale")
          user.locale = auth.extra.raw_info.locale
        end
        if auth.has_key?("extra") && auth.extra.has_key?("raw_info") && auth.extra.raw_info.has_key?("age_range")
          user.age_range = auth.extra.raw_info.locale 
        end
        user.image_from_url auth.info.image
        user.save!
      end
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

end
