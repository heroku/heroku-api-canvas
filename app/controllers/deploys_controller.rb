class DeploysController < ApplicationController
  # POST /deploys
  def post
    token_response = Excon.post(
      'https://login.salesforce.com/services/oauth2/token',
      :query => {
        'client_id'     => ENV['SALESFORCE_CLIENT_ID'],
        'client_secret' => ENV['SALESFORCE_CLIENT_SECRET'],
        'grant_type'    => 'refresh_token',
        'refresh_token' => ENV['SALESFORCE_REFRESH_TOKEN']
      }
    )
    oauth_access_token = JSON.load(token_response.body)['access_token']

    excon = Excon.new(
      'https://na15.salesforce.com',
      :headers => {
        'Authorization' => "Bearer #{oauth_access_token}"
      }
    )

    groups_response = excon.request(
      :method => :get,
      :path   => '/services/data/v29.0/chatter/groups',
      :query  => { 'q' => params['app'] }
    )
    group_id = JSON.load(groups_response.body)['groups'].detect {|group| group['name'] == params['app']}['id']

    chatter_response = excon.request(
      :method => :post,
      :path   => "/services/data/v29.0/chatter/feeds/record/#{group_id}/feed-items",
      :query  => {
        'text' => "#{params['user']} deployed #{params['head']}",
      }
    )
    puts chatter_response.body

    render :nothing => true, :status => 200
  end
end
