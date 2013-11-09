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
    oauth_access_token = JSON.parse(token_response.body)['access_token']

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
    puts groups_response.inspect
    group_id = JSON.parse(groups_response.body)['groups'].detect {|group| group['name'] == params['app']}['id']

    excon.request(
      :body   => JSON.encode({
        'body' => {
          'messageSegments' => [{
            'text' => "#{params['user']} deployed #{params['head']}",
            'type' => 'Text'
          }]
        }
      }),
      :method => :post,
      :path   => "/services/data/v29.0/chatter/feeds/record/#{group_id}/feed-items"
    )

    render :nothing => true, :status => 200
  end
end
