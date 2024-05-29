class OAuthProvider
  def initialize
    @request = nil
    @name = nil
    @email = nil
  end

  def call(env)
    @request = Rack::Request.new(env)

    case [ @request.request_method, @request.path_info ]
    when [ "GET", "/provider/authorize" ]
      authorize
    when [ "GET", "/provider/authorized" ]
      authorized
    when [ "POST", "/provider/oauth/access_token" ]
      oauth_access_token
    when [ "GET", "/provider/api/user_info" ]
      api_user_info
    else
      [ 404, { "content-type" => "text/plain" }, [ "Not Found" ] ]
    end
  end

  private

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
    uri = URI(@request.params["callback_url"])
    uri.query = Rack::Utils.build_query({
      state: @request.params["state"],
      code: "AUTHORIZATION-CODE-#{SecureRandom.hex(8)}"
    })

    [ 302, { "Location" => uri.to_s }, [] ]
  end

  def oauth_access_token
    response = JSON.generate({
      access_token: "gho_16C7e42F292c6912E7710c838347Ae178B4a",
      scope: "repo,gist",
      token_type: "bearer"
    })

    [ 200, { "content-type" => "application/json" }, [ response ] ]
  end

  def api_user_info
    response = JSON.generate({
      id: rand(1000),
      name: @name,
      email: @email
    })

    [ 200, { "content-type" => "application/json" }, [ response ] ]
  end
end
