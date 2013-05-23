window.addEventListener 'DOMContentLoaded', ->
  
  class Upload
  
    constructor: (@form) ->
      
      @progress = document.createElement('progress')
      @progress.value = 0
      
      @form.appendChild(@progress)
    
      @form.addEventListener 'submit', (e) =>
      
        e.preventDefault()
      
        @input = @form.querySelector('input[type=file]')
        @file  = @input.files[0]
        
        @submit(@form)
        
    submit: (form) ->
      
      new Chunk(form, @file, @progress).submit (e) =>
        newForm = e.target.responseXML.querySelector('form.upload')
        if newForm
          @submit(newForm)
        else
          window.location.reload(true)
        
  class Chunk
    
    constructor: (@form, @file, @progress) ->
      
      @method = @form.querySelector('[name=_method]')?.value or @form.method
      @action = @form.action
      
      @offset = parseInt @form.querySelector('[name=offset]').value
      
      @buffer = parseInt @form.querySelector('[type=file]').maxLength
      
      complete = (@offset + @buffer) >= @file.size
      @form.querySelector('[name=complete]').value = complete
      
      @data = new FormData
      @data.append 'file', @file.slice(@offset, @offset + @buffer), @file.name
      
      for input in @form.querySelectorAll('input:not([type=file])')
        @data.append input.name, input.value
      
    submit: (callback) ->
      
      xhr = new XMLHttpRequest
      xhr.responseType = 'document'
      xhr.timeout = 1800
      xhr.open @method, @action, true
      xhr.upload.onprogress = (e) =>
        @progress.value = ((@offset + e.loaded) / @file.size) if e.lengthComputable
      xhr.onload = callback
      xhr.onerror = -> console.log 'upload error'
      xhr.ontimeout = -> console.log 'upload timeout'
        
      xhr.send(@data)
          
  for form in document.querySelectorAll('form.upload')
    new Upload form