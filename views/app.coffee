class Progress
  
  constructor: (@name, @class = 'progress') ->
    
    @figure = document.createElement('figure')
    @figure.classList.add @class
      
    @progress = document.createElement 'progress'
    @progress.value = 0
    
    @button = document.createElement 'button'
    @button.innerHTML = 'pause'
      
    @caption = document.createElement 'figcaption'
    @caption.innerHTML = @name
    
    @figure.appendChild @progress
    @figure.appendChild @button
    @figure.appendChild @caption
  
  update: (progress) ->
    
    @progress.value = progress
      
  appendAfter: (element) ->    
    element.parentNode.appendChild @figure
    
class Form
  
  constructor: (@element) ->
    
    @method = @element.querySelector('[name=_method]')?.value or @element.method
    @action = @element.action
    
    @offset = parseInt @params()['offset'], 10 or 0
    
    @file_input = @element.querySelector '[type=file]'

    @length = parseInt @file_input?.maxLength, 10
    
    @metadata = @element.querySelectorAll 'input:not([type=file]):not([name=complete])'
    
    @parentNode = @element.parentNode
    
  files: ->
    @file_input.files
    
  addEventListener: (type, listener, useCapture = true) ->
    @element.addEventListener type, listener, useCapture
    
  params: ->
    plus = /\+/g
    search = /([^&=]+)=?([^&]*)/g
    decode = (s) -> decodeURIComponent s.replace(plus, ' ')
  
    index = @action.indexOf '?'
    if index isnt -1 then hash = @action.substr index + 1 else hash = ''
  
    result = {}
    while match = search.exec(hash)
      key = decode match[1]
      value = decode match[2]
      result[key] = value
    result
    
class Upload
  
  constructor: (@form, @file, @progress, @callback) ->
    
    @isPaused = false
    
    @progress.button.addEventListener 'click', @onPauseToggle
    
    if 'onLine' in navigator
      window.addEventListener 'online',  @onConnectionFound
      window.addEventListener 'offline', @onConnectionLost
        
      false
    
  start: ->
    factory = new ChunkFactory
    chunk = factory.create(@form, @file, @progress)
    
    chunk.submit @onSuccess
    
  onSuccess: (e) =>    
    if form = e.target.responseXML?.querySelector 'form.upload'
      @form = new Form(form)
      @start() unless @isPaused
    else
      @callback @
    
  onConnectionFound: =>
    @resume()
    
  onConnectionLost: =>
    @pause()
    
  onPauseToggle: =>
    if @isPaused
      @resume()
    else
      @pause()
    
  pause: ->
    @isPaused = true
    
  resume: ->
    @isPaused = false
    @start()

class Uploader
  
  constructor: (form) ->
    
    @queue = []
    @form  = new Form form
    
    @form.addEventListener 'submit', (e) =>
      
      e.preventDefault()
      
      for file in @form.files()
        
        progress = new Progress file.name
        progress.appendAfter @form
        
        upload = new Upload @form, file, progress, @onSuccess
        
        @queue.push upload
        
        upload.start()
      
  onSuccess: (upload) =>
    
    index = @queue.indexOf(upload)
    @queue.splice(index, 1)

    window.location.reload(true) unless @queue.length
        
class Chunk
  
  constructor: (@form, @file, @progress) ->
  
    @form.complete_input
    
    @startByte  = @form.offset
    @endByte    = @startByte + @form.length
    @isComplete = @endByte >= @file.size
    
    @slice = @file.webkitSlice || @file.mozSlice || @file.slice
    
  submit: (load, error = @onError, timeout = @onTimeout) ->
    
    xhr = new XMLHttpRequest
    
    xhr.responseType = 'document'
    xhr.timeout = 1800
    
    xhr.open @form.method, @form.action, true
    xhr.onerror = error
    xhr.onload = load
    xhr.ontimeout = timeout
    
    xhr.upload.onprogress = (e) =>
      @progress.update (@startByte + e.loaded) / @file.size if e.lengthComputable
    
    xhr.send @data()
  
  data: ->
    result = new FormData
    result.append 'complete', @isComplete
    result.append 'file', @slice.call(@file, @startByte, @endByte), @file.name
    result
    
  onError: ->
    console.log "upload error: #{@file.name}"
    
  onTimeout: ->
    console.log "upload timeout: #{@file.name}"
    
class Create extends Chunk
  
  data: ->
    result = super
    for input in @form.metadata
      result.append input.name, input.value
    result
    
class ChunkFactory
  create: (form, file, progress) ->
    
    matches = form.method.match /^(post|put)$/i
    type = matches[1].toLowerCase()
    switch type
      when 'post' then new Create(form, file, progress)
      when 'put' then new Chunk(form, file, progress)
      else console.log "upload failed: #{file.name}"
      
window.addEventListener 'DOMContentLoaded', ->
  
  for form in document.querySelectorAll('form.upload')
    new Uploader form
