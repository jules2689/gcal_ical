class BasicAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    auth = Rack::Auth::Basic::Request.new(env)

    return unauthorized unless auth.provided?
    return bad_request unless auth.basic?

    if auth.credentials == [username, password]
      env['REMOTE_USER'] = auth.username
      return @app.call(env)
    end

    unauthorized
  end

  private

  def username
    ENV["USERNAME"]
  end
  
  def password
    ENV["PASSWORD"]
  end
  
  def unauthorized(www_authenticate = challenge)
    return [ 401,
      { 'Content-Type' => 'text/plain',
        'Content-Length' => '0',
        'WWW-Authenticate' => www_authenticate.to_s },
      []
    ]
  end

  def bad_request
    return [ 400,
      { 'Content-Type' => 'text/plain',
        'Content-Length' => '0' },
      []
    ]
  end

  def challenge
    'Basic realm="%s"' % realm
  end

  def realm
    'Realm'
  end
end