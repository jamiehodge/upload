require 'coffee-script'
require 'sinatra/base'
require 'slim'

require_relative 'resource'

class App < Sinatra::Base
  
  set(:model) { Resource }

  enable :method_override
  
  ID = %r{(?<id>\d+)$}
  
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
  
  before ID do
    not_found unless resource
  end
  
  get ID do
    slim :read
  end
  
  get %r{(?<id>\d+)/media$} do
    send_file resource.path, 
      filename: resource.name, type: resource.type, disposition: 'inline'
  end
  
  patch ID do
    halt 409 if resource.complete?
    
    resource.set resource_params
    
    if resource.valid? and resource.save
      slim :read
    else
      [ 400, slim(:error) ]
    end
  end
  
  delete ID do
    resource.destroy
    
    redirect to '/'
  end
  
  get '/app.js' do
    coffee :app
  end
  
  def resources
    @resources ||= settings.model.all
  end
  
  def resource
    @resource ||= params[:id] ? settings.model[params[:id]] : settings.model.new(resource_params)
  end
  
  def resource_params    
    params.merge file_params
  end
  
  def file_params
    return {} unless params['file']
    { 'tempfile' => params['file'][:tempfile], 'name' => params['file'][:filename] }
  end
end