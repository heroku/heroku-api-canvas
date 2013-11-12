class AppsController < ApplicationController
  before_filter do
    unless session[:username]
      render 'Unauthorized', :status => 401
    end
  end

  # GET /apps/new
  def new
  end

  # POST /apps
  def create
    # create app
    heroku_response = heroku_api.request(
      :body   => JSON.encode(
        :name => params['name']
      ),
      :method => :post,
      :path   => '/apps'
    )
    app = JSON.parse(heroku_response.body)

    # add deploy hook
    heroku_response = heroku_api.request(
      :body   => JSON.encode(
        :plan => 'deployhooks:http',
        :url  => 'http://heroku-api-canvas.herokuapp.com/deploys'
      ),
      :method => :post,
      :path   => "/apps/#{params['name']}/addons"
    )

    # create chatter group
    chatter_response = chatter_api.request(
      :method => :post,
      :path   => "/services/data/v29.0/chatter/groups",
      :query  => {
        :name       => params[:name],
        :visibility => 'PublicAccess'
      }
    )

    redirect "/apps/#{app['name']}"
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
      :path   => "/services/data/v29.0/chatter/feeds/record/#{chatter_group_id(params[:app_identifier])}/feed-items"
    )
    @feed_items = JSON.parse(chatter_response.body)['items']
  end

end
