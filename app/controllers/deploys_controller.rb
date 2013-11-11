class DeploysController < ApplicationController
  # POST /deploys
  def post
    chatter_api.request(
      :method => :post,
      :path   => "/services/data/v29.0/chatter/feeds/record/#{chatter_group_id(params['app'])}/feed-items",
      :query  => {
        'text' => "#{params['user']} deployed #{params['head']}",
      }
    )

    render :nothing => true, :status => 200
  end
end
