class OAuthProvider
  def initialize
    @request = nil
    @name = nil
    @email = nil
    @sub = nil
    @jwk = JWT::JWK.new(OpenSSL::PKey::RSA.new(2048))
  end

  def call(env)
    @request = Rack::Request.new(env)

    case [ @request.request_method, @request.path_info ]
    when [ "GET", "/provider/.well-known/openid-configuration" ]
      discovery_document
    when [ "GET", "/provider/certs" ]
      json_web_key_set
    when [ "GET", "/provider/authorize" ]
      authorize
    when [ "GET", "/provider/authorized" ]
      authorized
    when [ "POST", "/provider/oauth/access_token" ]
      oauth_tokens
    when [ "GET", "/provider/api/user_info" ]
      api_user_info
    else
      [ 404, { "content-type" => "text/plain" }, [ "Not Found" ] ]
    end
  end

  private

  def discovery_document
    response = JSON.generate({
      authorization_endpoint: "http://localhost:3001/provider/authorize",
      token_endpoint: "http://localhost:3001/provider/oauth/access_token",
      userinfo_endpoint: "http://localhost:3001/provider/api/user_info",
      jwks_uri: "http://localhost:3001/provider/certs"
    })

    [ 200, { "content-type" => "application/json" }, [ response ] ]
  end

  def json_web_key_set
    response = JWT::JWK::Set.new(@jwk).export.to_json

    [ 200, { "content-type" => "application/json" }, [ response ] ]
  end

  def authorize
    response = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <title>User Info</title>
      </head>
      <body style='text-align:center;'>
        <h1>User Info</h1>
        <form method='get' action='/provider/authorized' noValidate='noValidate' style='display:flex;flex-direction:column;width:fit-content;margin:1rem auto;text-align:left;gap:1rem;'>
          <input type='hidden' name='state' value='#{@request.params["state"]}' />
          <input type='hidden' name='callback_url' value='#{@request.params["redirect_uri"]}' />

          <label for='name'>Name:</label>
          <input type='text' id='name' name='name' />

          <label for='email'>Email:</label>
          <input type='text' id='email' name='email' />

          <button type='submit'>Submit</button>
      </body>
    HTML

    [ 200, { "content-type" => "text/html" }, [ response ] ]
  end

  def authorized
    @name = @request.params["name"]
    @email = @request.params["email"]
    @sub = rand(1000)

    uri = URI(@request.params["callback_url"])
    uri.query = Rack::Utils.build_query({
      state: @request.params["state"],
      code: "AUTHORIZATION-CODE-#{SecureRandom.hex(8)}"
    })

    [ 302, { "Location" => uri.to_s }, [] ]
  end

  def oauth_tokens
    current_time = Time.now.to_i
    headers = { kid: @jwk.kid, typ: "JWT" }
    payload = {
      aud: Rails.application.credentials.provider.client_id,
      exp: current_time + 300,
      iat: current_time,
      iss: "http://localhost:3001",
      id: @sub,
      name: @name,
      email: @email
    }

    response = JSON.generate({
      access_token: "gho_16C7e42F292c6912E7710c838347Ae178B4a",
      id_token: JWT.encode(payload, @jwk.signing_key, "RS256", headers),
      scope: "repo,gist",
      token_type: "bearer"
    })

    [ 200, { "content-type" => "application/json" }, [ response ] ]
  end

  def api_user_info
    response = JSON.generate({
      id: @sub,
      name: @name,
      email: @email
    })

    [ 200, { "content-type" => "application/json" }, [ response ] ]
  end
end
