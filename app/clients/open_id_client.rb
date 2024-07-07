# frozen_string_literal: true

class OpenIdClient < ApplicationClient
  SCOPE = "openid profile email".freeze

  attr_reader :discovery_document_url, :client_id, :client_secret

  def initialize(discovery_document_url:, client_id:, client_secret:)
    super()
    @discovery_document_url = discovery_document_url
    @client_id = client_id
    @client_secret = client_secret
  end

  def configuration_document
    # This is a very naive approach to caching the discovery document so that it does not have to be queried for every
    # request. According to the spec you should look at the cache control header of the response and cache it based on
    # that value.
    response_body = Rails.cache.fetch("open_id_client.configuration_document", expires_in: 1.day) do
      get(discovery_document_url).body
    end

    JSON.parse(response_body, object_class: OpenStruct)
  end

  def json_web_key_set
    # This is a very naive approach to caching the JSON Web Key Set so that it does not have to be queried for every
    # request. According to the spec you should look at the cache control header of the response and cache it based on
    # that value.
    response_body = Rails.cache.fetch("open_id_client.json_web_key_set", expires_in: 1.day) do
      get(configuration_document.jwks_uri).body
    end

    JSON.parse(response_body, symbolize_names: true)
  end

  def authorize_url(redirect_uri:, state:)
    uri = URI(configuration_document.authorization_endpoint)
    uri.query = Rack::Utils.build_query(response_type: "code", client_id:, redirect_uri:, scope: SCOPE, state:)
    uri.to_s
  end

  def fetch_tokens(code:, redirect_uri:)
    url = configuration_document.token_endpoint
    body = { client_id:, client_secret:, code:, redirect_uri: }

    post(url, body:).parsed_body
  end
end
