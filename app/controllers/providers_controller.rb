class ProvidersController < ApplicationController

  def index
  end

  def dashboard
    @provider_id = params[:provider_id]
  end

  def show
  end

end
