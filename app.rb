require 'coffee-script'
require 'mustermann'
require 'sinatra/base'
require 'slim'

require_relative 'resource'

class App < Sinatra::Base
  
  set(:model) { Resource }
  
  set :pattern, capture: { id: :digit }
  
  enable :method_override
  
  register Mustermann
  
  get '/' do
    slim :list
  end
  
  post '/' do
    if resource.valid? and resource.save
      redirect(to resource.id)
    else
      [ 400, slim(:error) ]
    end
  end
  
  before '/:id' do
    not_found unless resource
  end
  
  get '/:id' do
    slim :read
  end
  
  get '/:id/media' do
    send_file resource.path
  end
  
  patch '/:id' do
    resource.set params
    
    if resource.valid? and resource.save
      slim :read
    else
      [ 400, slim(:error) ]
    end
  end
  
  delete '/:id' do
    resource.destroy
    
    redirect to '/'
  end
  
  get '/app.js' do
    content_type :js
    coffee :app
  end
  
  def resources
    @resources ||= settings.model.all
  end
  
  def resource
    @resource ||= params[:id] ? settings.model[params[:id]] : settings.model.new(params)
  end
end