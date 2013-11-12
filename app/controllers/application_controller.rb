# Copyright (c) 2011, salesforce.com, inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided
# that the following conditions are met:
#
#    Redistributions of source code must retain the above copyright notice, this list of conditions and the
#    following disclaimer.
#
#    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
#    the following disclaimer in the documentation and/or other materials provided with the distribution.
#
#    Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or
#    promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter do
    if params[:signed_request]
      @sr = params[:signed_request]

      # Validate the signed request was provided.
      raise "Signed request parameter required." if @sr.blank?()

      # Retrieve consumer secret from environment
      secret = ENV["CANVAS_CONSUMER_SECRET"]
      raise "No consumer secret found in environment [CANVAS_CONSUMER_SECRET]." if secret.blank?()

      # Construct the signed request helper
      srHelper = SignedRequest.new(secret,@sr)

      # Verify and decode the signed request.
      @canvasRequestJson = srHelper.verifyAndDecode()

      puts JSON.parse(@canvasRequestJson)

      session[:username] = JSON.parse(@canvasRequestJson)['context']['user']['userName']
    end
  end

  private

  def chatter_api
    @chatter_api ||= begin
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

      Excon.new(
        'https://na15.salesforce.com',
        :headers => {
          'Authorization' => "Bearer #{oauth_access_token}"
        }
      )
    end
  end

  def chatter_group_id(name)
    @chatter_group_ids ||= {}
    @chatter_group_ids[name] ||= begin
      groups_response = chatter_api.request(
        :method => :get,
        :path   => '/services/data/v29.0/chatter/groups',
        :query  => { 'q' => name }
      )
      group_id = JSON.load(groups_response.body)['groups'].detect {|group| group['name'] == name}['id']
    rescue
      nil
    end
  end

  def heroku_api
    @heroku_api ||= begin
      credential = Base64.encode64(":#{ENV['HEROKU_API_KEY']}").delete("\r\n")

      Excon.new(
        'https://api.heroku.com',
        :headers => {
          'Accept'        => 'application/vnd.heroku+json; version=3',
          'Authorization' => "Basic #{credential}",
        }
      )
    end
  end
end
