import std/[asynchttpserver, asyncdispatch, re, files, paths, dirs, syncio,
    strutils, strformat, osproc, sugar, json]

const staticDir = Path("./public")

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

func buildHeaders(content: string): HttpHeaders =
  result = {"Content-type": fmt"{content.mimeType()}; charset=utf-8"}
    .newHttpHeaders()

proc listFiles(req: Request) {.async.} =
  let jsonHeaders = {"Content-type": "application/json; charset=utf-8"}
      .newHttpHeaders()
  let files =
    collect(for f in walkDir(staticDir):
      if f.kind == pcFile:
        $f.path.extractFilename())
  await req.respond(Http200, $(%*files), jsonHeaders)

proc serveFile(req: Request, folder: string, filename: string) {.async.} =
  let fullPath = Path(folder) / Path(filename)
  if fileExists(fullPath):
    let content = readFile($fullPath)
    let headers = buildHeaders(fullPath.splitFile().ext);
    await req.respond(Http200, content, headers)
  else:
    await req.respond(Http404, "Not found", buildHeaders("txt"))


proc executeContent(req: Request) {.async.} =
  let content = req.body;
  writeFile("input.txt", content)
  let res = execCmdEx("sh run.sh")
  await req.respond(Http200, res.output, buildHeaders("txt"))

proc callback(req: Request) {.async, gcsafe.} =
  let plainContent = {"Content-type": "text/plain; charset=utf-8"}.newHttpHeaders
  let url = $(req.url.path)
  if req.reqMethod == HttpGet:
    if url == "/":
      await  serveFile(req, "./static", "index.html")
    elif url == "/list":
      await listFiles(req)
    elif url.match(re"/static/\S+"):
      await serveFile(req, "./static", url[8..<url.len])
    elif url.match(re"/file/\S+"):
      await serveFile(req, "./public", url[6..<url.len])
    else:
      await req.respond(Http404, "Not found", plainContent)
  elif req.reqMethod == HttpPost:
    if url == "/execute":
      await executeContent(req)
    else:
      await req.respond(Http404, "Not found", plainContent)
  else:
    await req.respond(Http404, "Method not available", plainContent)

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
  waitFor main(8080)
