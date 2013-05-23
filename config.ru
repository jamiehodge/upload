require 'rack/cors'

use Rack::Cors do
  allow do
    origins '*'
    resource '/', headers: :any, methods: :any
  end
end

require './app'
run App