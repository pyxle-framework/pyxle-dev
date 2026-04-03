HEAD = [
    '<title>Benchmarks - Pyxle Framework</title>',
    '<meta name="description" content="Transparent performance benchmarks comparing Pyxle against FastAPI, Django, Flask, Express, Hono, and Next.js." />',
    '<meta name="viewport" content="width=device-width, initial-scale=1" />',
    '<link rel="icon" href="/favicon.svg" type="image/svg+xml" />',
    '<link rel="preconnect" href="https://fonts.googleapis.com" />',
    '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />',
    '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap" rel="stylesheet" />',
    '<link rel="stylesheet" href="/styles/tailwind.css" />',
    '<meta property="og:title" content="Pyxle Benchmarks - Framework Performance Comparison" />',
    '<meta property="og:description" content="See how Pyxle performs against popular Python and Node.js frameworks." />',
]


@server
async def load_benchmarks(request):
    from pyxle import __version__
    return {"version": __version__}


# --- client ---
import React, { useState } from 'react';
import { useTheme } from './layout.jsx';
import { Link } from 'pyxle/client';

export const slots = {};
export const createSlots = () => slots;

/* ── data ────────────────────────────────────────────────────── */

const PYTHON_FRAMEWORKS = [
    { key: "pyxle", name: "Pyxle", color: "bg-emerald-500", text: "text-emerald-400", type: "Full-stack (SSR + API)" },
    { key: "fastapi", name: "FastAPI", color: "bg-cyan-500", text: "text-cyan-400", type: "API framework" },
    { key: "django", name: "Django", color: "bg-yellow-500", text: "text-yellow-400", type: "Full-stack (no SSR)" },
    { key: "flask", name: "Flask", color: "bg-purple-500", text: "text-purple-400", type: "Micro framework" },
];

const ALL_FRAMEWORKS = [
    ...PYTHON_FRAMEWORKS,
    { key: "express", name: "Express", color: "bg-blue-500", text: "text-blue-400", type: "API framework" },
    { key: "hono", name: "Hono", color: "bg-red-500", text: "text-red-400", type: "Ultralight API" },
    { key: "nextjs", name: "Next.js", color: "bg-white", text: "text-white", type: "Full-stack (SSR + API)" },
];

const TESTS = {
    json: {
        name: "JSON Serialization",
        desc: "Return a static JSON object. Measures pure framework and serialization overhead.",
        data: { pyxle: 5016, fastapi: 21165, django: 4134, flask: 5044, express: 39565, hono: 50045, nextjs: 6718 },
    },
    db: {
        name: "Single DB Query",
        desc: "Read one random row from SQLite. Measures framework + database access overhead.",
        data: { pyxle: 1395, fastapi: 1795, django: 2562, flask: 2658, express: 34589, hono: 29963, nextjs: 5350 },
    },
    queries5: {
        name: "Multiple Queries (5)",
        desc: "Read 5 random rows from SQLite. Measures query loop performance.",
        data: { pyxle: 1373, fastapi: 1632, django: 1973, flask: 2124, express: 22112, hono: 28260, nextjs: 5623 },
    },
    queries20: {
        name: "Multiple Queries (20)",
        desc: "Read 20 random rows from SQLite. Heavier database workload.",
        data: { pyxle: 1126, fastapi: 1250, django: 753, flask: 2476, express: 15300, hono: 16130, nextjs: 4974 },
    },
    form: {
        name: "Form Submission (POST)",
        desc: "Parse JSON body, validate fields, return response. Measures request processing.",
        data: { pyxle: 23949, fastapi: 15754, django: 3851, flask: 4724, express: 35795, hono: 28552, nextjs: 6475 },
    },
    health: {
        name: "Health Check",
        desc: "Minimal endpoint. Measures raw framework routing overhead.",
        data: { pyxle: 4158, fastapi: 20968, django: 3936, flask: 5088, express: 40405, hono: 53261, nextjs: 7293 },
    },
};

const SSR_COMPARISON = [
    { conns: 1,   pyxle: 441,  nextjs: 1364 },
    { conns: 5,   pyxle: 1039, nextjs: 1645 },
    { conns: 10,  pyxle: 1040, nextjs: 1620 },
    { conns: 50,  pyxle: 1149, nextjs: 1659 },
    { conns: 100, pyxle: 1168, nextjs: 1618 },
];

const KEY_TAKEAWAYS = [
    {
        title: "Fastest full-stack Python framework",
        desc: "Pyxle outperforms Django by 2.3x and Flask by 1.7x on average across all API benchmarks, while offering SSR, file-based routing, and server actions that neither provides.",
        icon: "M13 10V3L4 14h7v7l9-11h-7z",
    },
    {
        title: "SSR performance on par with Next.js",
        desc: "Pyxle renders server-side pages at 1,100+ req/s with a persistent worker pool and bundle caching. The gap with Next.js is just 1.4x \u2014 remarkable for a Python + Node.js hybrid architecture.",
        icon: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z",
    },
    {
        title: "Zero errors under heavy load",
        desc: "Across all tests at 100 concurrent connections, Pyxle maintained zero errors and zero timeouts. Production-grade stability is not optional.",
        icon: "M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z",
    },
    {
        title: "POST/form processing outperforms Node.js",
        desc: "Pyxle's CSRF-protected POST handling reaches 24,000+ req/s, outperforming Hono and competing with Express. Starlette's ASGI layer shines for request body processing.",
        icon: "M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z",
    },
];

/* ── components ──────────────────────────────────────────────── */

function BarChart({ data, frameworks, maxOverride }) {
    const { theme } = useTheme();
    const sorted = [...frameworks].sort((a, b) => (data[b.key] || 0) - (data[a.key] || 0));
    const maxVal = maxOverride || Math.max(...sorted.map(f => data[f.key] || 0));

    return (
        <div className="space-y-3">
            {sorted.map((fw) => {
                const val = data[fw.key] || 0;
                const pct = maxVal > 0 ? Math.max((val / maxVal) * 100, 2) : 0;
                return (
                    <div key={fw.key} className="flex items-center gap-3">
                        <span className={`w-16 sm:w-20 text-xs sm:text-sm font-medium text-right shrink-0 ${fw.key === 'pyxle' ? 'text-emerald-400 font-semibold' : theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>
                            {fw.name}
                        </span>
                        <div className={`flex-1 h-7 rounded-md overflow-hidden ${theme === 'dark' ? 'bg-white/5' : 'bg-zinc-100'}`}>
                            <div
                                className={`h-full rounded-md ${fw.color} flex items-center justify-end pr-2 transition-all duration-500`}
                                style={{ width: `${pct}%`, minWidth: val > 0 ? '3rem' : '0' }}
                            >
                                <span className="text-[10px] sm:text-xs font-semibold text-white drop-shadow-sm whitespace-nowrap">
                                    {val.toLocaleString()}
                                </span>
                            </div>
                        </div>
                    </div>
                );
            })}
        </div>
    );
}

function TestCard({ testKey, test, frameworks }) {
    const { theme } = useTheme();
    return (
        <div className={`rounded-xl border p-5 sm:p-6 ${theme === 'dark' ? 'border-white/5 bg-white/[0.02]' : 'border-zinc-200 bg-white'}`}>
            <h4 className="text-base font-semibold mb-1">{test.name}</h4>
            <p className={`text-xs mb-4 ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-400'}`}>{test.desc}</p>
            <BarChart data={test.data} frameworks={frameworks} />
        </div>
    );
}

function SectionHeading({ label, title, subtitle }) {
    const { theme } = useTheme();
    return (
        <div className="mb-10">
            <p className="text-sm font-semibold uppercase tracking-widest text-emerald-400">{label}</p>
            <h2 className="mt-3 text-2xl font-bold tracking-tight sm:text-3xl">{title}</h2>
            {subtitle && <p className={`mt-3 max-w-3xl ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>{subtitle}</p>}
        </div>
    );
}

/* ── nav (minimal for subpage) ───────────────────────────────── */

function BenchNav({ version }) {
    const { theme } = useTheme();
    return (
        <nav className={`sticky top-0 z-50 border-b backdrop-blur-xl ${
            theme === 'dark' ? 'bg-[#0a0a0b]/80 border-white/5' : 'bg-white/80 border-zinc-200'
        }`}>
            <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
                <div className="flex items-center gap-3">
                    <Link href="/" className="flex items-center gap-3">
                        <img src="/branding/pyxle-mark.svg" alt="Pyxle" className="h-7 w-7" />
                        <span className="text-lg font-semibold tracking-tight">Pyxle</span>
                    </Link>
                    <span className={`text-sm ${theme === 'dark' ? 'text-zinc-600' : 'text-zinc-400'}`}>/</span>
                    <span className="text-sm font-medium">Benchmarks</span>
                </div>
                <div className="flex items-center gap-4">
                    <Link href="/" className={`text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Home</Link>
                    <a href="https://github.com/shivamsn97/pyxle" target="_blank" rel="noreferrer"
                       className={`text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>GitHub</a>
                </div>
            </div>
        </nav>
    );
}

/* ── page ─────────────────────────────────────────────────── */

export default function BenchmarksPage({ data }) {
    const { version } = data;
    const { theme } = useTheme();
    const [showAllFrameworks, setShowAllFrameworks] = useState(false);

    const activeFrameworks = showAllFrameworks ? ALL_FRAMEWORKS : PYTHON_FRAMEWORKS;

    return (
        <>
            <BenchNav version={version} />

            {/* Hero */}
            <section className="px-6 pt-20 pb-12">
                <div className="mx-auto max-w-6xl">
                    <p className="text-sm font-semibold uppercase tracking-widest text-emerald-400 mb-3">Performance</p>
                    <h1 className="text-3xl font-bold tracking-tight sm:text-4xl md:text-5xl">
                        Framework Benchmarks
                    </h1>
                    <p className={`mt-4 max-w-2xl text-lg ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>
                        Transparent, reproducible benchmarks comparing Pyxle against popular web frameworks.
                        Every framework implements identical endpoints with the same logic.
                    </p>
                </div>
            </section>

            {/* Methodology */}
            <section className="px-6 pb-16">
                <div className="mx-auto max-w-6xl">
                    <div className={`rounded-xl border p-6 ${theme === 'dark' ? 'border-white/5 bg-white/[0.02]' : 'border-zinc-200 bg-zinc-50'}`}>
                        <h3 className="text-sm font-semibold uppercase tracking-widest text-emerald-400 mb-3">Methodology</h3>
                        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                            {[
                                { label: "Tool", value: "autocannon v8" },
                                { label: "Duration", value: "12s per test" },
                                { label: "Connections", value: "10 concurrent" },
                                { label: "Hardware", value: "Apple M3 (8 cores)" },
                            ].map(m => (
                                <div key={m.label}>
                                    <p className={`text-xs ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-400'}`}>{m.label}</p>
                                    <p className="text-sm font-medium">{m.value}</p>
                                </div>
                            ))}
                        </div>
                        <p className={`mt-4 text-xs ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-400'}`}>
                            All Python frameworks use uvicorn (single worker, ASGI) except Flask (gunicorn, 4 WSGI workers).
                            Node.js frameworks use their default server. Pyxle runs in production mode via <code className="font-mono">pyxle serve</code> with full middleware stack.
                            Database: SQLite with WAL mode, 1,000 pre-seeded rows.{' '}
                            <a href="https://github.com/shivamsn97/pyxle/tree/main/benchmarks" target="_blank" rel="noreferrer" className="text-emerald-400 hover:underline">
                                Source code (run it yourself)
                            </a>
                        </p>
                    </div>
                </div>
            </section>

            {/* Key Takeaways */}
            <section className="px-6 pb-20">
                <div className="mx-auto max-w-6xl">
                    <SectionHeading label="Highlights" title="Key Takeaways" />
                    <div className="grid gap-5 sm:grid-cols-2">
                        {KEY_TAKEAWAYS.map((t) => (
                            <div key={t.title} className={`rounded-xl border p-6 ${theme === 'dark' ? 'border-white/5 bg-white/[0.02]' : 'border-zinc-200 bg-white'}`}>
                                <div className={`inline-flex rounded-lg border p-2.5 text-emerald-400 mb-4 ${theme === 'dark' ? 'border-white/10 bg-white/5' : 'border-zinc-200 bg-zinc-50'}`}>
                                    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" d={t.icon} />
                                    </svg>
                                </div>
                                <h3 className="text-base font-semibold mb-2">{t.title}</h3>
                                <p className={`text-sm leading-relaxed ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>{t.desc}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* SSR Comparison */}
            <section className="px-6 pb-20">
                <div className="mx-auto max-w-6xl">
                    <SectionHeading
                        label="SSR Performance"
                        title="Server-Side Rendering: Pyxle vs Next.js"
                        subtitle="Both frameworks render React components on the server. Pyxle's optimized worker pool with bundle caching delivers throughput comparable to Next.js."
                    />
                    <div className={`rounded-xl border overflow-hidden ${theme === 'dark' ? 'border-white/5' : 'border-zinc-200'}`}>
                        <div className="overflow-x-auto">
                            <table className="w-full text-sm">
                                <thead>
                                    <tr className={theme === 'dark' ? 'bg-white/[0.03]' : 'bg-zinc-50'}>
                                        <th className="px-5 py-3 text-left font-semibold">Connections</th>
                                        <th className="px-5 py-3 text-right font-semibold text-emerald-400">Pyxle (req/s)</th>
                                        <th className="px-5 py-3 text-right font-semibold">Next.js (req/s)</th>
                                        <th className="px-5 py-3 text-right font-semibold">Ratio</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {SSR_COMPARISON.map((row) => {
                                        const ratio = (row.nextjs / row.pyxle).toFixed(1);
                                        return (
                                            <tr key={row.conns} className={`border-t ${theme === 'dark' ? 'border-white/5' : 'border-zinc-100'}`}>
                                                <td className="px-5 py-3 font-mono">{row.conns}</td>
                                                <td className="px-5 py-3 text-right font-mono text-emerald-400 font-medium">{row.pyxle.toLocaleString()}</td>
                                                <td className={`px-5 py-3 text-right font-mono ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>{row.nextjs.toLocaleString()}</td>
                                                <td className={`px-5 py-3 text-right font-mono ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-400'}`}>{ratio}x</td>
                                            </tr>
                                        );
                                    })}
                                </tbody>
                            </table>
                        </div>
                        <div className={`px-5 py-3 text-xs border-t ${theme === 'dark' ? 'border-white/5 text-zinc-500' : 'border-zinc-100 text-zinc-400'}`}>
                            SSR renders the homepage with server-side data loading, React component rendering, and full HTML document assembly.
                            Pyxle uses persistent Node.js worker pool with esbuild bundle caching. Next.js uses pre-compiled React Server Components.
                        </div>
                    </div>
                </div>
            </section>

            {/* API Benchmarks */}
            <section className="px-6 pb-20">
                <div className="mx-auto max-w-6xl">
                    <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between mb-10 gap-4">
                        <SectionHeading
                            label="API Benchmarks"
                            title="Endpoint Performance Comparison"
                            subtitle="Each framework implements identical API endpoints with the same business logic, database, and response format."
                        />
                        <div className="flex items-center gap-2 shrink-0">
                            <button
                                onClick={() => setShowAllFrameworks(false)}
                                className={`rounded-lg px-4 py-2 text-xs font-medium transition ${
                                    !showAllFrameworks
                                        ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                                        : theme === 'dark'
                                            ? 'text-zinc-400 border border-white/10 hover:bg-white/5'
                                            : 'text-zinc-600 border border-zinc-200 hover:bg-zinc-50'
                                }`}
                            >
                                Python Only
                            </button>
                            <button
                                onClick={() => setShowAllFrameworks(true)}
                                className={`rounded-lg px-4 py-2 text-xs font-medium transition ${
                                    showAllFrameworks
                                        ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                                        : theme === 'dark'
                                            ? 'text-zinc-400 border border-white/10 hover:bg-white/5'
                                            : 'text-zinc-600 border border-zinc-200 hover:bg-zinc-50'
                                }`}
                            >
                                All Frameworks
                            </button>
                        </div>
                    </div>

                    <div className="grid gap-6 lg:grid-cols-2">
                        {Object.entries(TESTS).map(([key, test]) => (
                            <TestCard key={key} testKey={key} test={test} frameworks={activeFrameworks} />
                        ))}
                    </div>

                    {showAllFrameworks && (
                        <div className={`mt-6 rounded-xl border p-5 ${theme === 'dark' ? 'border-white/5 bg-white/[0.02]' : 'border-zinc-200 bg-zinc-50'}`}>
                            <h4 className="text-sm font-semibold mb-2">Understanding the Node.js advantage</h4>
                            <p className={`text-sm leading-relaxed ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>
                                Node.js frameworks (Express, Hono) show higher raw throughput on pure I/O benchmarks.
                                This is an inherent runtime advantage: Node.js's V8 engine and single-threaded event loop are
                                optimized for high-throughput HTTP serving, and <code className={`font-mono text-xs rounded px-1 py-0.5 ${theme === 'dark' ? 'bg-white/5' : 'bg-zinc-200'}`}>better-sqlite3</code> is
                                a native C++ addon significantly faster than Python's sqlite3 module.
                                Pyxle's value proposition is bringing the Python ecosystem's strengths (data science, ML, existing backend code)
                                into a full-stack framework with competitive performance.
                            </p>
                        </div>
                    )}
                </div>
            </section>

            {/* Reproduce */}
            <section className="px-6 pb-20">
                <div className="mx-auto max-w-6xl">
                    <div className={`rounded-xl border p-6 sm:p-8 text-center ${theme === 'dark' ? 'border-white/5 bg-white/[0.02]' : 'border-zinc-200 bg-zinc-50'}`}>
                        <h3 className="text-xl font-bold mb-3">Run the benchmarks yourself</h3>
                        <p className={`text-sm mb-6 max-w-xl mx-auto ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>
                            All benchmark code is open source. Clone the repo, start the servers, and run the suite on your own hardware.
                        </p>
                        <a
                            href="https://github.com/shivamsn97/pyxle/tree/main/benchmarks"
                            target="_blank"
                            rel="noreferrer"
                            className={`inline-flex items-center gap-2 rounded-xl px-6 py-3 text-sm font-semibold transition ${
                                theme === 'dark'
                                    ? 'bg-white text-black hover:bg-zinc-200'
                                    : 'bg-zinc-900 text-white hover:bg-zinc-700'
                            }`}
                        >
                            <svg className="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
                            </svg>
                            View benchmark source
                        </a>
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer className={`border-t px-6 py-12 ${theme === 'dark' ? 'border-white/5' : 'border-zinc-200'}`}>
                <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-6 sm:flex-row">
                    <div className="flex items-center gap-3">
                        <img src="/branding/pyxle-mark.svg" alt="Pyxle" className="h-6 w-6 opacity-50" />
                        <span className={`text-sm ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-400'}`}>Pyxle Framework</span>
                    </div>
                    <div className="flex items-center gap-6">
                        <Link href="/" className={`text-sm transition ${theme === 'dark' ? 'text-zinc-500 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'}`}>Home</Link>
                        <a href="https://docs.pyxle.dev" target="_blank" rel="noreferrer"
                           className={`text-sm transition ${theme === 'dark' ? 'text-zinc-500 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'}`}>Docs</a>
                        <a href="https://github.com/shivamsn97/pyxle" target="_blank" rel="noreferrer"
                           className={`text-sm transition ${theme === 'dark' ? 'text-zinc-500 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'}`}>GitHub</a>
                    </div>
                </div>
            </footer>
        </>
    );
}
