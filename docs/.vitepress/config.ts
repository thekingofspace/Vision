import { defineConfig } from "vitepress"

export default defineConfig({
    title: "Vision",
    description: "Existence Begins With Perception.",
    base: "/vision/",

    head: [
        ["link", { rel: "icon", type: "image/svg+xml", href: "/vision/logo.svg" }],
        ["meta", { name: "theme-color", content: "#5865F2" }],
    ],

    themeConfig: {
        logo: "/logo.svg",

        nav: [
            { text: "Home", link: "/" },
            { text: "Tutorials", link: "/tut/crash-course/1-introduction" },
            { text: "API", link: "/api/declarations" },
            { text: "Comparison", link: "/comparison" },
        ],

        sidebar: {
            "/api/": [
                {
                    text: "API",
                    items: [
                        { text: "Declarations", link: "/api/declarations" },
                        { text: "Keywords", link: "/api/keywords" },
                        { text: "Scope", link: "/api/scope" },
                        { text: "Vision", link: "/api/vision" },
                        { text: "Animation", link: "/api/animation" },
                    ],
                },
            ],

            "/tut/": [
                {
                    text: "Crash Course",
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
            ],
        },

        search: {
            provider: "local",
        },

        socialLinks: [{ icon: "github", link: "https://github.com/thekingofspace/Vision" }],

        footer: {
            message:
                'Released under the MIT License. Documentation structure and source concept adapted from <a href="https://github.com/centau/vide">Vide</a> by centau.',
            copyright: "Existence Begins With Perception.",
        },
    },
})
