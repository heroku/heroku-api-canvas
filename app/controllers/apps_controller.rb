class AppsController < ApplicationController
  before_filter do
    unless session[:username]
      render :status => 401, :text => 'Unauthorized'
    end
  end

  # GET /apps/new
  def new
  end

  # POST /apps
  def create
    # create app
    heroku_response = heroku_api.request(
      :body   => JSON.dump(
        :name => params['name']
      ),
      :method => :post,
      :path   => '/apps'
    )
    puts heroku_response.inspect
    app = JSON.load(heroku_response.body)

    # add deploy hook
    puts heroku_api.request(
      :body   => JSON.dump(
        :plan => 'deployhooks:http',
        :url  => 'http://heroku-api-canvas.herokuapp.com/deploys'
      ),
      :method => :post,
      :path   => "/apps/#{params['name']}/addons"
    ).inspect

    # create chatter group
    puts chatter_api.request(
      :method => :post,
      :path   => "/services/data/v29.0/chatter/groups",
      :query  => {
        :name       => params[:name],
        :visibility => 'PublicAccess'
      }
    ).inspect

    redirect_to "/apps/#{app['name']}"
  end

  # GET /apps/:app_identifier
  def show
    heroku_response = heroku_api.request(
      :method => :get,
      :path   => "/apps/#{params[:app_identifier]}"
    )
    @app = JSON.load(heroku_response.body)

    # allow eventual consistency right after creating
    @feed_items = if group_id = chatter_group_id(params[:app_identifier])
      chatter_response = chatter_api.request(
        :method => :get,
        :path   => "/services/data/v29.0/chatter/feeds/record/#{group_id}/feed-items"
      )
      JSON.load(chatter_response.body)['items']
    else
      []
    end
  end

end
