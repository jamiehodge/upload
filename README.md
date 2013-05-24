# Resumable Upload Demo

A simple chunked upload protocol for single or multiple files.

## Environment Variables

* `UPLOAD_PATH`
* `UPLOAD_MAX_LENGTH`

## Protocol

**Request:**

    GET /
    Host: tus.example.org
    

**Response:**

    HTTP/1.1 200 OK
    ...

    <form action="http://tus.example.org/" enctype="multipart/form-data" method="post">
      <input name="parent_id" type="text" />
      <input name="complete" type="hidden" value="true" />
      <input data-offset="0" maxLength="1024" name="file" type="file" />
      <button>Submit</button>
    </form>
    
**Request:**

    POST /
    Host: tus.example.org
    Content-Type: multipart/form-data; boundary=AaB03x
    
    --AaB03x
    Content-Disposition: form-data; name="complete"
    
    false
    --AaB03x
    Content-Disposition: form-data; name="parent_id"
    
    123
    --AaB03x
    Content-Disposition: form-data; name="file"
    Content-Type: multipart/mixed; boundary=BbC04y
    
    --BbC04y
    Content-Disposition: file; name="file.txt"
    Content-Type: text/plain
    --BbC04y--
    --AaB03x--

**Response:**

    HTTP/1.1 201 OK
    Location: http://tus.example.org/966218c0bfcec3a138f9e8d1c4eac592
    ...
**Request:**

    GET /966218c0bfcec3a138f9e8d1c4eac592
    Host: tus.example.org

**Response:**

    HTTP/1.1 200 OK
    ...
    
    <form action="http://tus.example.org/966218c0bfcec3a138f9e8d1c4eac592" enctype="multipart/form-data" method="post">
      <input name="_method" type="hidden" value="patch"
      <input name="parent_id" type="text" value="123" />
      <input name="complete" type="hidden" value="false" />
      <input data-offset="1023" maxLength="1024" name="file" type="file" format="file.txt" accept="text/plain" />
      <button>Submit</button>
    </form>
    
    <form action="http://tus.example.org/966218c0bfcec3a138f9e8d1c4eac592" method="post">
      <input name="_method" type="hidden" value="delete"
      <button>Submit</button>
    </form>

**Request:**

    POST /966218c0bfcec3a138f9e8d1c4eac592
    Host: tus.example.org
    Content-Type: multipart/form-data; boundary=AaB03x
    
    --AaB03x
    Content-Disposition: form-data; name="complete"
    
    true
    --AaB03x
    Content-Disposition: form-data; name="file"
    Content-Type: multipart/mixed; boundary=BbC04y
    
    --BbC04y
    Content-Disposition: file; name="file.txt"
    Content-Type: text/plain
    --BbC04y--
    --AaB03x--

**Response:**
  
    HTTP/1.1 200 OK
    ...
    
    <form action="http://tus.example.org/966218c0bfcec3a138f9e8d1c4eac592" method="post">
      <input name="_method" type="hidden" value="delete"
      <button>Submit</button>
    </form>
    
## Issues

Browser is currently ignoring file input pattern on resume.