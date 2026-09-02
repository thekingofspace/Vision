import fs from "node:fs"
import path from "node:path"
import http from "node:http"
import { fileURLToPath } from "node:url"

const Root = path.dirname(fileURLToPath(import.meta.url))
const Port = 8080

const Types = {
    ".html": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".svg": "image/svg+xml",
    ".js": "text/javascript; charset=utf-8",
    ".md": "text/plain; charset=utf-8",
}

http.createServer((Request, Response) => {
    let Target = decodeURIComponent(Request.url.split("?")[0])

    if (Target.endsWith("/")) Target += "index.html"

    const File = path.join(Root, Target)

    if (!File.startsWith(Root) || !fs.existsSync(File) || fs.statSync(File).isDirectory()) {
        Response.writeHead(404, { "Content-Type": "text/plain" })
        Response.end("404")
        return
    }

    Response.writeHead(200, { "Content-Type": Types[path.extname(File)] ?? "application/octet-stream" })
    Response.end(fs.readFileSync(File))
}).listen(Port, () => console.log(`\n  docs served at http://localhost:${Port}/\n`))
