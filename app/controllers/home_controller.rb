class HomeController < ApplicationController

  before_filter :authenticate_user!, only: [:authed_request]

  def index
  end

  def authed_request
    render json: {success: true, data: "it's a boy!"}
  end
end
