require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module NewDay0
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.middleware.insert_before Warden::Manager, Rack::Cors do
      allow do
        origins '*'
        resource '*',
        :headers => :any,
        :methods => [:get, :post, :options]
      end
    end

    # LOAD CREDENTIALS FROM YAML
    credentials_path = Rails.root.join("config", "provider_credentials.yml")
    provider_credentials = YAML.load(ERB.new(File.read(credentials_path)).result)[Rails.env]
    Rails.application.config.provider_credentials = provider_credentials
    provider_credentials.each_pair do |provider_name, creds|
      ENV["#{provider_name.upcase}_KEY"] = creds["app_id"]
      ENV["#{provider_name.upcase}_SECRET"] = creds["app_secret"]
    end
    # PERMISSIONS SCOPE FOR FACEBOOK - login partial, engine.rb
    ENV["FACEBOOK_SCOPE"] = 'email, offline_access, user_birthday, read_friendlists'
  end
end
