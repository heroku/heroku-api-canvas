class AppsController < ApplicationController
  before_filter do
    unless session[:username]
      render :status => 400
    end
  end

  # GET /apps/:app_identifier
  def show
    heroku_response = heroku_api.request(
      :method => :get,
      :path   => "/apps/#{params[:app_identifier]}"
    )
    @app = JSON.parse(heroku_response.body)

    chatter_response = chatter_api.request(
      :method => :get,
      :path   => "/services/data/v29.0/chatter/feeds/record/#{chatter_group_id(params['app'])}/feed-items"
    )
    @feed_items = JSON.parse(chatter_response.body)['items']


  end

end
