class DeploysController < ApplicationController
  # POST /deploys
  def post
    excon = Excon.new(
      'https://na15.salesforce.com',
      :headers => {
        'Authorization' => "Bearer #{ENV['SALESFORCE_OAUTH_TOKEN']}"
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
