import std/[asynchttpserver, asyncdispatch, re, files, paths, dirs, syncio,
    strutils, strformat, osproc, sugar, json]

# You can modify this constans in case any of the
# default values need to be changed
const port = 8080
const staticFolder = "./static"
const publicFolder = "./public"

## Returns the mime type for a content given
## and extension file.
func mimeType(content: string): string =
  result =
    case content:
      of ".txt":
        "text/plain"
      of ".html":
        "text/html"
      of ".json":
        "application/json"
      of ".css":
        "text/css"
      of ".js":
        "application/javascript"
      else:
        "text/plain"

## Returns appropiated headers based on an string
## describing the content, like "txt" or "json".
func buildHeaders(content: string): HttpHeaders =
  result = {"Content-type": fmt"{content.mimeType()}; charset=utf-8"}
    .newHttpHeaders()

## Returns the list of files contained in the public folder
proc listFiles(req: Request) {.async.} =
  let files =
    collect(for f in walkDir(Path(publicFolder)):
      if f.kind == pcFile:
        $f.path.extractFilename())
  await req.respond(Http200, $(%*files), buildHeaders("json"))

## Endpoint provided to return the content of a file. It is used both,
## to return files from the static folder and the public folder.
proc serveFile(req: Request, folder: string, filename: string) {.async.} =
  let fullPath = Path(folder) / Path(filename)
  if fileExists(fullPath):
    let content = readFile($fullPath)
    let headers = buildHeaders(fullPath.splitFile().ext);
    await req.respond(Http200, content, headers)
  else:
    await req.respond(Http404, "Not found", buildHeaders("txt"))

## It is responsible to run the code, catch up the ouput and send
## it to the client. It assumes a script `run.sh` exists.
proc executeContent(req: Request) {.async.} =
  let content = req.body;
  writeFile("input.txt", content)
  when defined(windows):
    let res = execCmd("./run.bat")
  else:
    let res = execCmdEx("sh run.sh")
  await req.respond(Http200, res.output, buildHeaders("txt"))


## It processes the routes and executes the appropiated endpoints
## when the client sends a request.
proc callback(req: Request) {.async, gcsafe.} =
  let url = $(req.url.path)
  let headers = buildHeaders("txt")
  if req.reqMethod == HttpGet:
    if url == "/":
      await  serveFile(req, staticFolder, "index.html")
    elif url == "/list":
      await listFiles(req)
    elif url.match(re"/static/\S+"):
      await serveFile(req, staticFolder, url[8..<url.len])
    elif url.match(re"/file/\S+"):
      await serveFile(req, publicFolder, url[6..<url.len])
    else:
      await req.respond(Http404, "Not found", headers)
  elif req.reqMethod == HttpPost:
    if url == "/execute":
      await executeContent(req)
    else:
      await req.respond(Http404, "Not found", headers)
  else:
    await req.respond(Http404, "Method not available", headers)

proc main(port: int) {.async.} =
  var server = newAsyncHttpServer()
  server.listen(Port(port))
  echo "Server running at http://0.0.0.0:" & $port &
      " (Ctrl+C to shut it down)"
  while true:
    if server.shouldAcceptRequest():
      await server.acceptRequest(callback)
    else:
      await sleepAsync(10)

when isMainModule:
  waitFor main(port)
