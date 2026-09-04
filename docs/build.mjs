import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"
import { marked } from "marked"
import hljs from "highlight.js"

const Root = path.dirname(fileURLToPath(import.meta.url))

const Site = "Vision"
const Motto = "Existence Begins With Perception."

const Nav = [
    { text: "Home", link: "/index" },
    { text: "Tutorials", link: "/tut/crash-course/1-introduction" },
    { text: "API", link: "/api/declarations" },
    { text: "Comparison", link: "/comparison" },
]

const Sidebars = [
    {
        match: "tut/",
        title: "Crash Course",
        items: [
            { text: "Introduction", link: "/tut/crash-course/1-introduction" },
            { text: "Declarations", link: "/tut/crash-course/2-declarations" },
            { text: "Staging and Mounting", link: "/tut/crash-course/3-mounting" },
            { text: "Values", link: "/tut/crash-course/4-values" },
            { text: "Lifecycle", link: "/tut/crash-course/5-lifecycle" },
            { text: "Sleeping and Cloning", link: "/tut/crash-course/6-sleeping" },
            { text: "Animation", link: "/tut/crash-course/7-animation" },
        ],
    },
    {
        match: "api/",
        title: "API",
        items: [
            { text: "Declarations", link: "/api/declarations" },
            { text: "Keywords", link: "/api/keywords" },
            { text: "Scope", link: "/api/scope" },
            { text: "Style", link: "/api/style" },
            { text: "Vision", link: "/api/vision" },
            { text: "Animation", link: "/api/animation" },
            { text: "Timeline", link: "/api/timeline" },
            { text: "Sprites", link: "/api/sprites" },
            { text: "Tools", link: "/api/tools" },
        ],
    },
]

const Languages = { luau: "lua", lua: "lua", bash: "bash", sh: "bash", json: "json", ts: "typescript" }

function Escape(Text) {
    return Text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
}

marked.use({
    renderer: {
        code({ text, lang }) {
            const Language = Languages[lang] ?? (hljs.getLanguage(lang) ? lang : null)
            const Body = Language ? hljs.highlight(text, { language: Language }).value : Escape(text)

            return `<pre class="code"><code class="hljs">${Body}</code></pre>\n`
        },

        heading({ tokens, depth }) {
            const Text = this.parser.parseInline(tokens)
            const Id = Text.replace(/<[^>]*>/g, "")
                .toLowerCase()
                .replace(/[^\w\s-]/g, "")
                .trim()
                .replace(/\s+/g, "-")

            return `<h${depth} id="${Id}"><a class="anchor" href="#${Id}">#</a>${Text}</h${depth}>\n`
        },
    },
})

function Walk(Directory) {
    const Found = []

    for (const Entry of fs.readdirSync(Directory, { withFileTypes: true })) {
        if (Entry.name === "node_modules" || Entry.name.startsWith(".")) continue

        const Full = path.join(Directory, Entry.name)

        if (Entry.isDirectory()) Found.push(...Walk(Full))
        else if (Entry.name.endsWith(".md")) Found.push(Full)
    }

    return Found
}

function StripFrontmatter(Source) {
    if (!Source.startsWith("---")) return Source

    const End = Source.indexOf("\n---", 3)

    return End === -1 ? Source : Source.slice(Source.indexOf("\n", End + 1) + 1)
}

function Badges(Source) {
    return Source.replace(
        /<Badge\s+type="(\w+)"\s+text="([^"]*)"\s*\/>/g,
        (_, Kind, Text) => `<span class="badge ${Kind}">${Text}</span>`
    )
}

function Containers(Source) {
    return Source.replace(/^::: *(tip|warning|danger|info)([^\n]*)\n([\s\S]*?)^:::\s*$/gm, (_, Kind, Title, Body) => {
        const Heading = Title.trim() || Kind[0].toUpperCase() + Kind.slice(1)

        return `<div class="callout ${Kind}">\n\n**${Heading}**\n\n${Body}\n</div>\n`
    })
}

function Relative(FromDirectory, Target) {
    const [Raw, Hash] = Target.split("#")

    let Clean = Raw === "/" || Raw === "" ? "/index" : Raw.replace(/\/$/, "")

    if (Clean.startsWith("/")) Clean = Clean.slice(1)
    if (!Clean.endsWith(".html")) Clean += ".html"

    let Link = path.relative(FromDirectory, Clean).split(path.sep).join("/")

    if (!Link.startsWith(".")) Link = "./" + Link

    return Hash ? `${Link}#${Hash}` : Link
}

function Asset(FromDirectory, File) {
    let Link = path.relative(FromDirectory, `assets/${File}`).split(path.sep).join("/")

    if (!Link.startsWith(".")) Link = "./" + Link

    return Link
}

function Links(Html, FromDirectory) {
    return Html.replace(/href="(\/[^"]*)"/g, (_, Target) => `href="${Relative(FromDirectory, Target)}"`)
}

function Menu(Items, FromDirectory, Current) {
    return Items.map((Item) => {
        const Active = Item.link === `/${Current}` ? ' class="active"' : ""

        return `<a${Active} href="${Relative(FromDirectory, Item.link)}">${Item.text}</a>`
    }).join("\n")
}

function Page(Slug, Title, Body) {
    const Directory = path.dirname(Slug) === "." ? "" : path.dirname(Slug)
    const Home = Slug === "index"
    const Sidebar = Sidebars.find((Entry) => Slug.startsWith(Entry.match))

    const Aside = Sidebar
        ? `<aside class="sidebar">
<p class="group-title">${Sidebar.title}</p>
<div class="items">
${Menu(Sidebar.items, Directory, Slug)}
</div>
</aside>`
        : ""

    return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="color-scheme" content="light dark">
<meta name="theme-color" content="#4a54d6" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#16171d" media="(prefers-color-scheme: dark)">
<title>${Title === Site ? Site : `${Title} | ${Site}`}</title>
<meta name="description" content="${Motto}">
<link rel="icon" type="image/svg+xml" href="${Asset(Directory, "logo.svg")}">
<link rel="stylesheet" href="${Asset(Directory, "style.css")}">
</head>
<body>
<header class="nav">
<a class="brand" href="${Relative(Directory, "/index")}">
<img src="${Asset(Directory, "logo.svg")}" alt="" width="26" height="26">
<span>${Site}</span>
</a>
<nav class="links">
${Menu(Nav, Directory, Slug)}
<a href="https://github.com/thekingofspace/Vision">GitHub</a>
</nav>
</header>
<div class="shell${Aside ? "" : " wide"}">
${Aside}
<main class="content${Home ? " home" : ""}">
${Body}
</main>
</div>
<footer class="foot">
<p>Released under the MIT License. Documentation structure and source concept adapted from <a href="https://github.com/centau/vide">Vide</a> by centau.</p>
<p class="motto">${Motto}</p>
</footer>
</body>
</html>
`
}

function Build() {
    const Sources = Walk(Root)
    let Count = 0

    for (const File of Sources) {
        const Slug = path.relative(Root, File).replace(/\.md$/, "").split(path.sep).join("/")
        const Directory = path.dirname(Slug) === "." ? "" : path.dirname(Slug)
        const Source = Badges(Containers(StripFrontmatter(fs.readFileSync(File, "utf8"))))

        const Heading = Source.match(/^#\s+(.+)$/m)
        const Title = Heading ? Heading[1].trim() : Site

        const Body = Links(marked.parse(Source), Directory)
        const Output = path.join(Root, `${Slug}.html`)

        fs.mkdirSync(path.dirname(Output), { recursive: true })
        fs.writeFileSync(Output, Page(Slug, Title, Body))

        Count += 1
        console.log(`  ${Slug}.html`)
    }

    if (!fs.existsSync(path.join(Root, ".nojekyll"))) {
        fs.writeFileSync(path.join(Root, ".nojekyll"), "")
    }

    console.log(`\n${Count} pages built into docs/`)
    console.log("open docs/index.html, or run `npm run serve`\n")
}

Build()
