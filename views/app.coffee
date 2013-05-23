class Progress
  
  constructor: (@name, @class = 'progress') ->
    
    @figure = document.createElement('figure')
    @figure.classList.add @class
      
    @progress = document.createElement 'progress'
    @progress.value = 0  
      
    @caption = document.createElement 'figcaption'
    @caption.innerHTML = @name
    
    @figure.appendChild @progress
    @figure.appendChild @caption
  
  update: (progress) ->
    
    @progress.value = progress
      
  appendTo: (element) ->
    
    element.appendChild @figure
    
class Queue
  
  constructor: ->
    
    @queue = []
    
  push: (obj) ->
    
    @queue.push obj
    
  delete: (obj) ->
    
    index = @queue.indexOf(obj)
    @queue.splice(index, 1)
        
  isEmpty: ->
    
    not @queue.length
    
class Form
  
  constructor: (@element) ->
    
    @method = @element.querySelector('[name=_method]')?.value or @element.method
    @action = @element.action
    
    @file_input = @element.querySelector '[type=file]'
    
    @offset = parseInt @file_input.getAttribute('data-offset') or 0, 10
    @length = parseInt @file_input?.maxLength, 10
    
    @metadata = @element.querySelectorAll 'input:not([type=file])'
    
  files: ->
    @file_input.files
    
  addEventListener: (type, listener, useCapture = true) ->
    @element.addEventListener type, listener, useCapture
    
  appendChild: (obj) ->
    @element.appendChild obj

class Upload
  
  constructor: (form) ->
    
    @form  = new Form form
    @queue = new Queue
    
    @form.addEventListener 'submit', (e) =>
      
      e.preventDefault()
      
      for file in @form.files()
        
        @queue.push file
        
        progress = new Progress file.name
        progress.appendTo @form
        
        @submit @form, file, progress
        
      false
    
  submit: (form, file, progress) ->
    
    factory = new ChunkFactory
    chunk = factory.create(form, file, progress)
    
    chunk.submit (e) =>
      
      form = e.target.responseXML?.querySelector 'form.upload.patch'
      
      if form
        @submit(new Form(form), file, progress)
      else
        @queue.delete file
        @done() if @queue.isEmpty()

  done: ->
    
    window.location.reload(true)
      
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
    
  onError: ->
    console.log 'upload error'
    
  onTimeout: ->
    console.log 'upload timeout'
    
class Create extends Chunk
  
  data: ->
    result = super
    
    for input in @form.metadata
      result.append input.name, input.value
      
    result.append 'file[name]', @file.name
    result.append 'file[type]', @file.type
    result.append 'file[size]', @file.size
    result
      
class Patch extends Chunk
  
  data: ->
    result = super
    result.append 'file', @slice.call @file, @startByte, @endByte, @file.name
    result
    
class ChunkFactory
  create: (form, file, progress) ->
    
    matches = form.method.match /^(post|patch)$/i
    type = matches[1].toLowerCase()
    switch type
      when 'post' then new Create(form, file, progress)
      when 'patch' then new Patch(form, file, progress)
      else console.log 'upload failed'
      
window.addEventListener 'DOMContentLoaded', ->
  
  for form in document.querySelectorAll('form.upload')
    new Upload form
