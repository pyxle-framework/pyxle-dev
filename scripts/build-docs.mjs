#!/usr/bin/env node
/**
 * build-docs.mjs — Convert Pyxle framework markdown docs into JSON for the website.
 *
 * Reads:  ../pyxle/docs/**\/*.md
 * Writes: public/docs-data/manifest.json     (navigation + search index)
 *         public/docs-data/{category}/{slug}.json  (individual pages)
 *
 * Run:  node scripts/build-docs.mjs
 */

import { marked } from "marked";
import { readFileSync, writeFileSync, mkdirSync, readdirSync, statSync, existsSync } from "fs";
import { join, dirname, basename, relative, sep } from "path";
import { fileURLToPath } from "url";
import { createHash } from "crypto";

const __dirname = dirname(fileURLToPath(import.meta.url));
const DOCS_SRC = join(__dirname, "..", "..", "pyxle", "docs");
const OUT_DIR = join(__dirname, "..", "public", "docs-data");

// ── Navigation structure (matches docs/README.md ordering) ──────────

const NAV_STRUCTURE = [
  {
    category: "Getting Started",
    slug: "getting-started",
    items: [
      { file: "getting-started/installation.md", slug: "installation" },
      { file: "getting-started/quick-start.md", slug: "quick-start" },
      { file: "getting-started/project-structure.md", slug: "project-structure" },
    ],
  },
  {
    category: "Core Concepts",
    slug: "core-concepts",
    items: [
      { file: "core-concepts/pyx-files.md", slug: "pyx-files" },
      { file: "core-concepts/routing.md", slug: "routing" },
      { file: "core-concepts/data-loading.md", slug: "data-loading" },
      { file: "core-concepts/server-actions.md", slug: "server-actions" },
      { file: "core-concepts/layouts.md", slug: "layouts" },
    ],
  },
  {
    category: "Guides",
    slug: "guides",
    items: [
      { file: "guides/styling.md", slug: "styling" },
      { file: "guides/head-management.md", slug: "head-management" },
      { file: "guides/api-routes.md", slug: "api-routes" },
      { file: "guides/middleware.md", slug: "middleware" },
      { file: "guides/environment-variables.md", slug: "environment-variables" },
      { file: "guides/error-handling.md", slug: "error-handling" },
      { file: "guides/client-components.md", slug: "client-components" },
      { file: "guides/security.md", slug: "security" },
      { file: "guides/deployment.md", slug: "deployment" },
    ],
  },
  {
    category: "Reference",
    slug: "reference",
    items: [
      { file: "reference/cli.md", slug: "cli" },
      { file: "reference/configuration.md", slug: "configuration" },
      { file: "reference/runtime-api.md", slug: "runtime-api" },
      { file: "reference/client-api.md", slug: "client-api" },
    ],
  },
  {
    category: "Advanced",
    slug: "advanced",
    items: [
      { file: "advanced/ssr-pipeline.md", slug: "ssr-pipeline" },
      { file: "advanced/compiler-internals.md", slug: "compiler-internals" },
    ],
  },
  {
    category: "FAQ",
    slug: "faq",
    items: [{ file: "faq.md", slug: "faq" }],
  },
];

// ── Markdown processing ─────────────────────────────────────────────

/** Add IDs to headings and extract TOC entries. */
function processMarkdown(md, currentCategory = '') {
  const toc = [];
  const slugCounts = {};

  const renderer = new marked.Renderer();

  let h1Skipped = false;

  renderer.heading = function ({ text, depth, raw: rawHeading }) {
    // Skip the first h1 — we render our own page title in the UI.
    if (depth === 1 && !h1Skipped) {
      h1Skipped = true;
      return "";
    }

    // The `text` parameter is raw markdown text (e.g., "`<Head>`").
    // Strip backticks for display text while keeping the content.
    const tocText = text.replace(/`/g, "");
    const decoded = tocText;

    let slug = decoded
      .toLowerCase()
      .replace(/[<>()]/g, "")  // remove angle brackets and parens for clean slugs
      .replace(/[^\w\s-]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "");

    // Ensure slug is not empty.
    if (!slug) {
      slug = "section-" + (toc.length + 1);
    }

    // Deduplicate slugs.
    if (slugCounts[slug]) {
      slugCounts[slug]++;
      slug = `${slug}-${slugCounts[slug]}`;
    } else {
      slugCounts[slug] = 1;
    }

    if (depth === 2 || depth === 3) {
      toc.push({ depth, text: tocText, slug });
    }

    // Convert backtick-wrapped content to <code> tags and escape HTML in heading text.
    const headingHtml = text
      .replace(/`([^`]+)`/g, (_, inner) => `<code>${inner.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</code>`)
      .replace(/^([^<`]*)<(?!code|\/code)([^>]*)>([^<]*)$/g, (m) => m.replace(/</g, '&lt;').replace(/>/g, '&gt;'));
    return `<h${depth} id="${slug}">${headingHtml}</h${depth}>`;
  };

  // Add language class to code blocks for syntax highlighting.
  renderer.code = function ({ text, lang }) {
    const langClass = lang ? ` class="language-${lang}"` : "";
    const escaped = text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
    return `<div class="code-block" data-lang="${lang || ""}"><pre><code${langClass}>${escaped}</code></pre></div>`;
  };

  // Convert internal .md links to /docs/ URLs.
  renderer.link = function ({ href, title, text }) {
    if (href && href.endsWith('.md')) {
      // Resolve relative .md links to /docs/ paths.
      // e.g., "head-management.md" → "/docs/guides/head-management"
      //        "../guides/error-handling.md" → "/docs/guides/error-handling"
      let docPath = href.replace(/\.md$/, '');
      // Remove leading ../ segments and resolve to flat doc path.
      docPath = docPath.replace(/\.\.\//g, '');
      // If no directory prefix, it's a same-category reference — prepend current category.
      if (!docPath.includes('/') && currentCategory) {
        docPath = `${currentCategory}/${docPath}`;
      }
      const titleAttr = title ? ` title="${title}"` : '';
      return `<a href="/docs/${docPath}"${titleAttr}>${text}</a>`;
    }
    // External or anchor links — pass through.
    const titleAttr = title ? ` title="${title}"` : '';
    const isExternal = href && (href.startsWith('http') || href.startsWith('//'));
    const targetAttr = isExternal ? ' target="_blank" rel="noreferrer"' : '';
    return `<a href="${href || '#'}"${titleAttr}${targetAttr}>${text}</a>`;
  };

  marked.setOptions({ renderer, gfm: true, breaks: false });
  const html = marked.parse(md);

  return { html, toc };
}

/** Extract the first h1 heading as the title. */
function extractTitle(md) {
  const match = md.match(/^#\s+(.+)$/m);
  return match ? match[1].replace(/`/g, "") : "Untitled";
}

/** Extract first paragraph as description (for SEO). */
function extractDescription(md) {
  // Skip headings and blank lines, find first paragraph.
  const lines = md.split("\n");
  let inParagraph = false;
  let desc = "";
  for (const line of lines) {
    if (line.startsWith("#") || line.startsWith("```") || line.startsWith("|")) continue;
    const trimmed = line.trim();
    if (!trimmed) {
      if (inParagraph) break;
      continue;
    }
    if (!trimmed.startsWith("-") && !trimmed.startsWith("*") && !trimmed.startsWith(">")) {
      inParagraph = true;
      desc += (desc ? " " : "") + trimmed;
    }
  }
  return desc.slice(0, 200);
}

/** Build search-friendly text from markdown (strip formatting). */
function extractSearchText(md) {
  return md
    .replace(/```[\s\S]*?```/g, "") // remove code blocks
    .replace(/`[^`]+`/g, "") // remove inline code
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1") // links → text
    .replace(/#{1,6}\s+/g, "") // remove heading markers
    .replace(/[*_~|>-]/g, "") // remove formatting
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 500);
}

// ── Build ───────────────────────────────────────────────────────────

function build() {
  console.log("Building docs from:", DOCS_SRC);

  if (!existsSync(DOCS_SRC)) {
    console.error("Docs source not found:", DOCS_SRC);
    process.exit(1);
  }

  mkdirSync(OUT_DIR, { recursive: true });

  const manifest = { nav: [], searchIndex: [], pages: {} };
  const flatPages = []; // for prev/next linking

  for (const section of NAV_STRUCTURE) {
    mkdirSync(join(OUT_DIR, section.slug), { recursive: true });

    const navSection = {
      category: section.category,
      slug: section.slug,
      items: [],
    };

    for (const item of section.items) {
      const filePath = join(DOCS_SRC, item.file);
      if (!existsSync(filePath)) {
        console.warn(`  SKIP: ${item.file} (not found)`);
        continue;
      }

      const md = readFileSync(filePath, "utf-8");
      const title = extractTitle(md);
      const description = extractDescription(md);
      const { html, toc } = processMarkdown(md, section.slug);
      const searchText = extractSearchText(md);

      const pagePath =
        section.slug === "faq" ? "faq" : `${section.slug}/${item.slug}`;

      // Page JSON (include raw markdown for "Copy page" feature)
      const pageData = { title, description, html, toc, path: pagePath, markdown: md };
      const outPath =
        section.slug === "faq"
          ? join(OUT_DIR, "faq.json")
          : join(OUT_DIR, section.slug, `${item.slug}.json`);
      writeFileSync(outPath, JSON.stringify(pageData));

      // Nav entry
      navSection.items.push({ title, slug: item.slug, path: pagePath });

      // Search index
      manifest.searchIndex.push({
        title,
        path: pagePath,
        category: section.category,
        description,
        searchText,
        headings: toc.map((t) => t.text),
      });

      // For prev/next
      flatPages.push({ title, path: pagePath });

      manifest.pages[pagePath] = { title, category: section.category };

      console.log(`  OK: ${pagePath} — "${title}"`);
    }

    manifest.nav.push(navSection);
  }

  // Add prev/next to each page JSON
  for (let i = 0; i < flatPages.length; i++) {
    const pagePath = flatPages[i].path;
    const outPath = pagePath.includes("/")
      ? join(OUT_DIR, ...pagePath.split("/")) + ".json"
      : join(OUT_DIR, pagePath + ".json");

    if (!existsSync(outPath)) continue;
    const data = JSON.parse(readFileSync(outPath, "utf-8"));
    if (i > 0) data.prev = { title: flatPages[i - 1].title, path: flatPages[i - 1].path };
    if (i < flatPages.length - 1) data.next = { title: flatPages[i + 1].title, path: flatPages[i + 1].path };
    writeFileSync(outPath, JSON.stringify(data));
  }

  writeFileSync(join(OUT_DIR, "manifest.json"), JSON.stringify(manifest, null, 2));
  console.log(`\nDone: ${flatPages.length} pages, manifest written.`);
}

build();
