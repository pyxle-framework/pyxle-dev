from pyxle import __version__
from pyxle.runtime import ActionError

HEAD = [
    '<title>Playground - Pyxle Framework</title>',
    '<meta name="description" content="Experience Pyxle live. Every interaction on this page hits a real Python server. Try server loaders, actions, SPA navigation, and more." />',
    '<meta name="viewport" content="width=device-width, initial-scale=1" />',
    '<link rel="icon" href="/favicon.svg" type="image/svg+xml" />',
    '<link rel="preconnect" href="https://fonts.googleapis.com" />',
    '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />',
    '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap" rel="stylesheet" />',
    '<link rel="stylesheet" href="/styles/tailwind.css?v=4" />',
    '<meta property="og:title" content="Pyxle Playground - Try Pyxle Live" />',
    '<meta property="og:description" content="Interactive demos of server loaders, actions, SPA navigation, and more. Every interaction hits a real Python server." />',
]

VALID_EMOJIS = ["heart", "fire", "mind_blown", "rocket", "sparkles", "clap"]


@server
async def load_playground(request):
    import time, platform, uuid
    from datetime import datetime
    from db import get_reactions, increment_playground_views

    start = time.perf_counter()
    views = increment_playground_views()
    reactions = get_reactions()
    render_ms = round((time.perf_counter() - start) * 1000, 1)

    return {
        "serverTime": datetime.now().isoformat(),
        "pythonVersion": platform.python_version(),
        "requestId": uuid.uuid4().hex[:8],
        "renderMs": render_ms,
        "totalViews": views,
        "reactions": reactions,
        "version": __version__,
    }


@action
async def react_emoji(request):
    from db import increment_reaction

    body = await request.json()
    emoji = body.get("emoji", "")
    if emoji not in VALID_EMOJIS:
        raise ActionError("Invalid reaction", status_code=400)

    new_count = increment_reaction(emoji)
    return {"ok": True, "emoji": emoji, "count": new_count}


@action
async def transform_text(request):
    body = await request.json()
    text = (body.get("text", "") or "")[:500]
    mode = body.get("mode", "upper")
    transforms = {
        "upper": str.upper,
        "lower": str.lower,
        "title": str.title,
        "reverse": lambda t: t[::-1],
        "word_count": lambda t: str(len(t.split())) + " words",
        "char_count": lambda t: str(len(t)) + " characters",
    }
    fn = transforms.get(mode)
    if not fn:
        raise ActionError("Invalid transform mode", status_code=400)
    return {"ok": True, "result": fn(text), "mode": mode}


# --- client ---
import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useTheme } from './layout.jsx';
import { useAction, Link, refresh } from 'pyxle/client';
import { tokenizeBlock, HIGHLIGHT_CSS } from './components/code-highlighter.jsx';
import { ThemeToggle } from './components/theme-toggle.jsx';

export const slots = {};
export const createSlots = () => slots;

/* ── scroll animation ────────────────────────────────────── */

function useScrollReveal(options = {}) {
    const ref = useRef(null);
    const [isVisible, setIsVisible] = useState(false);
    const { threshold = 0.15, once = true } = options;

    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        const observer = new IntersectionObserver(
            ([entry]) => {
                if (entry.isIntersecting) {
                    setIsVisible(true);
                    if (once) observer.unobserve(el);
                } else if (!once) {
                    setIsVisible(false);
                }
            },
            { threshold, rootMargin: '0px 0px -60px 0px' }
        );
        observer.observe(el);

        function onVisibilityChange() {
            if (document.visibilityState === 'visible' && el) {
                const rect = el.getBoundingClientRect();
                if (rect.top < window.innerHeight && rect.bottom > 0) {
                    setIsVisible(true);
                    if (once) observer.unobserve(el);
                    document.removeEventListener('visibilitychange', onVisibilityChange);
                }
            }
        }
        document.addEventListener('visibilitychange', onVisibilityChange);
        return () => {
            observer.disconnect();
            document.removeEventListener('visibilitychange', onVisibilityChange);
        };
    }, [threshold, once]);
    return [ref, isVisible];
}

function Reveal({ children, className = '', delay = 0, direction = 'up' }) {
    const [ref, isVisible] = useScrollReveal();
    const transforms = {
        up: 'translate3d(0, 48px, 0)',
        down: 'translate3d(0, -48px, 0)',
        left: 'translate3d(48px, 0, 0)',
        right: 'translate3d(-48px, 0, 0)',
        none: 'translate3d(0, 0, 0)',
    };
    return (
        <div
            ref={ref}
            className={className}
            style={{
                opacity: isVisible ? 1 : 0,
                transform: isVisible ? 'translate3d(0,0,0)' : transforms[direction],
                transition: `opacity 0.7s cubic-bezier(0.16,1,0.3,1) ${delay}ms, transform 0.7s cubic-bezier(0.16,1,0.3,1) ${delay}ms`,
                willChange: 'opacity, transform',
            }}
        >
            {children}
        </div>
    );
}

/* ── helpers ──────────────────────────────────────────────── */

function CopyButton({ text }) {
    const [copied, setCopied] = useState(false);
    const { theme } = useTheme();
    const copy = () => {
        if (typeof navigator !== 'undefined') {
            navigator.clipboard.writeText(text);
            setCopied(true);
            setTimeout(() => setCopied(false), 2000);
        }
    };
    return (
        <button
            onClick={copy}
            className={`absolute right-3 top-3 rounded-md border px-2 py-1 text-xs transition ${
                theme === 'dark'
                    ? 'border-white/10 bg-white/5 text-zinc-400 hover:bg-white/10 hover:text-white'
                    : 'border-zinc-200 bg-zinc-100 text-zinc-500 hover:bg-zinc-200 hover:text-zinc-900'
            }`}
            aria-label="Copy to clipboard"
        >
            {copied ? "Copied!" : "Copy"}
        </button>
    );
}

function SectionLabel({ label, title, subtitle }) {
    const { theme } = useTheme();
    return (
        <div className="mb-10">
            <p className="text-sm font-semibold uppercase tracking-widest text-emerald-400">{label}</p>
            <h2 className="mt-3 text-2xl font-bold tracking-tight sm:text-3xl">{title}</h2>
            {subtitle && <p className={`mt-3 max-w-3xl ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>{subtitle}</p>}
        </div>
    );
}

function HighlightedCode({ code, lang = 'pyx' }) {
    const blocks = tokenizeBlock(code, lang);
    return (
        <>
            {blocks.map((line, i) => (
                <div key={i}>
                    {line.map((tok, j) => (
                        tok.cls ? <span key={j} className={tok.cls}>{tok.text}</span> : tok.text
                    ))}
                    {'\n'}
                </div>
            ))}
        </>
    );
}

function CodeWindow({ title, code, lang = 'pyx', className = '' }) {
    const { theme } = useTheme();
    return (
        <div className={`relative rounded-xl border overflow-hidden min-w-0 ${
            theme === 'dark' ? 'border-white/10 bg-[#111113]' : 'border-zinc-200 bg-[#1a1a2e]'
        } ${className}`}>
            <div className={`flex items-center gap-2 border-b px-4 py-3 ${
                theme === 'dark' ? 'border-white/5' : 'border-zinc-700/30'
            }`}>
                <span className="h-3 w-3 rounded-full bg-red-500/80" />
                <span className="h-3 w-3 rounded-full bg-yellow-500/80" />
                <span className="h-3 w-3 rounded-full bg-green-500/80" />
                <span className="ml-2 text-xs text-zinc-500 font-mono">{title}</span>
            </div>
            <CopyButton text={code} />
            <pre className="p-4 sm:p-6 text-xs sm:text-sm leading-relaxed font-mono overflow-x-auto text-zinc-300">
                <code><HighlightedCode code={code} lang={lang} /></code>
            </pre>
        </div>
    );
}

/* ── nav ──────────────────────────────────────────────────── */

function PlaygroundNav({ version }) {
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
                    <a href="#" onClick={(e) => { e.preventDefault(); window.scrollTo({ top: 0, behavior: 'smooth' }); }} className="text-sm font-medium cursor-pointer">Playground</a>
                </div>
                <div className="flex items-center gap-2 sm:gap-4">
                    <Link href="/" className={`hidden sm:block text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Home</Link>
                    <Link href="/benchmarks" className={`hidden sm:block text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Benchmarks</Link>
                    <Link href="/docs" className={`hidden sm:block text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Docs</Link>
                    <a href="https://github.com/pyxle-framework/pyxle" target="_blank" rel="noreferrer"
                       className={`hidden sm:block text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>GitHub</a>
                    <a
                        href="https://github.com/pyxle-framework/pyxle-dev/blob/main/pages/playground.pyx"
                        target="_blank"
                        rel="noreferrer"
                        title="View page source"
                        className={`rounded-lg border p-2 transition ${
                            theme === 'dark'
                                ? 'border-white/10 bg-white/5 text-zinc-400 hover:bg-white/10 hover:text-white'
                                : 'border-zinc-200 bg-zinc-100 text-zinc-600 hover:bg-zinc-200 hover:text-zinc-900'
                        }`}
                    >
                        <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M17.25 6.75L22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3l-4.5 16.5" />
                        </svg>
                    </a>
                    <ThemeToggle />
                </div>
            </div>
        </nav>
    );
}

/* ── hero background: interactive dot grid ────────────────── */

function DotGridBackground({ sectionRef }) {
    const canvasRef = useRef(null);
    const mouseRef = useRef({ x: -1, y: -1, tx: -1, ty: -1 });
    const { theme } = useTheme();

    useEffect(() => {
        const canvas = canvasRef.current;
        const section = sectionRef?.current;
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        let w, h, animId;
        const cols = 40;
        const rows = 20;

        function resize() {
            const dpr = Math.min(window.devicePixelRatio || 1, 2);
            w = canvas.offsetWidth;
            h = canvas.offsetHeight;
            canvas.width = w * dpr;
            canvas.height = h * dpr;
            ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        }

        function onMouseMove(e) {
            const rect = canvas.getBoundingClientRect();
            mouseRef.current.tx = e.clientX - rect.left;
            mouseRef.current.ty = e.clientY - rect.top;
        }

        function onMouseLeave() {
            mouseRef.current.tx = -1;
            mouseRef.current.ty = -1;
        }

        const target = section || canvas;

        function draw(t) {
            ctx.clearRect(0, 0, w, h);
            const m = mouseRef.current;

            if (m.tx >= 0) {
                m.x += (m.tx - m.x) * 0.08;
                m.y += (m.ty - m.y) * 0.08;
            } else {
                m.x = -1;
                m.y = -1;
            }

            const time = t * 0.001;
            const isDark = theme === 'dark';
            const baseAlpha = isDark ? 0.15 : 0.25;
            const glowAlpha = isDark ? 0.6 : 0.8;
            const lineAlpha = isDark ? 0.08 : 0.12;
            const spacing = { x: w / (cols + 1), y: h / (rows + 1) };
            const interactRadius = 150;
            const connectRadius = 100;

            const points = [];

            for (let r = 1; r <= rows; r++) {
                for (let c = 1; c <= cols; c++) {
                    const bx = c * spacing.x;
                    const by = r * spacing.y;
                    const pulse = Math.sin(time * 1.5 + c * 0.3 + r * 0.5) * 0.5 + 0.5;

                    let px = bx;
                    let py = by;
                    let proximity = 0;

                    if (m.x >= 0) {
                        const dx = bx - m.x;
                        const dy = by - m.y;
                        const dist = Math.sqrt(dx * dx + dy * dy);
                        if (dist < interactRadius) {
                            proximity = 1 - dist / interactRadius;
                            const push = proximity * 12;
                            px += (dx / dist) * push;
                            py += (dy / dist) * push;
                        }
                    }

                    const alpha = baseAlpha + pulse * 0.05 + proximity * (glowAlpha - baseAlpha);
                    const size = 1 + pulse * 0.3 + proximity * 1.5;

                    ctx.beginPath();
                    ctx.arc(px, py, size, 0, Math.PI * 2);
                    ctx.fillStyle = `rgba(16, 185, 129, ${alpha})`;
                    ctx.fill();

                    if (proximity > 0.3) {
                        ctx.beginPath();
                        ctx.arc(px, py, size + 4, 0, Math.PI * 2);
                        ctx.fillStyle = `rgba(16, 185, 129, ${proximity * 0.1})`;
                        ctx.fill();
                    }

                    points.push({ x: px, y: py, proximity });
                }
            }

            for (let i = 0; i < points.length; i++) {
                if (points[i].proximity < 0.1) continue;
                for (let j = i + 1; j < points.length; j++) {
                    if (points[j].proximity < 0.1) continue;
                    const dx = points[i].x - points[j].x;
                    const dy = points[i].y - points[j].y;
                    const dist = Math.sqrt(dx * dx + dy * dy);
                    if (dist < connectRadius) {
                        const strength = (1 - dist / connectRadius) * Math.min(points[i].proximity, points[j].proximity);
                        ctx.beginPath();
                        ctx.moveTo(points[i].x, points[i].y);
                        ctx.lineTo(points[j].x, points[j].y);
                        ctx.strokeStyle = `rgba(16, 185, 129, ${strength * lineAlpha * 3})`;
                        ctx.lineWidth = 0.5 + strength;
                        ctx.stroke();
                    }
                }
            }

            animId = requestAnimationFrame(draw);
        }

        resize();
        animId = requestAnimationFrame(draw);
        window.addEventListener('resize', resize, { passive: true });
        target.addEventListener('mousemove', onMouseMove, { passive: true });
        target.addEventListener('mouseleave', onMouseLeave);

        return () => {
            cancelAnimationFrame(animId);
            window.removeEventListener('resize', resize);
            target.removeEventListener('mousemove', onMouseMove);
            target.removeEventListener('mouseleave', onMouseLeave);
        };
    }, [theme]);

    return (
        <canvas
            ref={canvasRef}
            className="pointer-events-none absolute inset-0 h-full w-full"
            aria-hidden="true"
        />
    );
}

/* ── hero ─────────────────────────────────────────────────── */

function AnimatedCounter({ value }) {
    const [display, setDisplay] = useState(0);
    const prevRef = useRef(0);

    useEffect(() => {
        const start = prevRef.current;
        const end = value;
        if (start === end) return;
        const duration = 1200;
        const startTime = performance.now();

        function tick(now) {
            const elapsed = now - startTime;
            const progress = Math.min(elapsed / duration, 1);
            const eased = 1 - Math.pow(1 - progress, 3);
            setDisplay(Math.round(start + (end - start) * eased));
            if (progress < 1) requestAnimationFrame(tick);
        }
        requestAnimationFrame(tick);
        prevRef.current = end;
    }, [value]);

    return <>{display.toLocaleString()}</>;
}

function Hero({ data }) {
    const { theme } = useTheme();
    const sectionRef = useRef(null);

    const scrollToContent = (e) => {
        e.preventDefault();
        const next = document.getElementById('format-section');
        if (next) next.scrollIntoView({ behavior: 'smooth', block: 'start' });
    };

    return (
        <section ref={sectionRef} className="relative overflow-hidden px-6 pt-20 pb-16 sm:pt-28 sm:pb-24">
            <DotGridBackground sectionRef={sectionRef} />

            <div className="relative z-10 mx-auto max-w-4xl text-center">
                <Reveal>
                    <h1 className="text-5xl font-bold tracking-tight sm:text-6xl md:text-7xl">
                        <span className="bg-gradient-to-r from-emerald-400 via-cyan-400 to-blue-500 bg-clip-text text-transparent">
                            Playground
                        </span>
                    </h1>
                </Reveal>

                <Reveal delay={80}>
                    <p className={`mt-6 text-lg sm:text-xl max-w-2xl mx-auto ${
                        theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'
                    }`}>
                        This page is a live Pyxle app. Every interaction below hits a real Python server.
                    </p>
                </Reveal>

                <Reveal delay={160}>
                    <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
                        <span className={`inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-mono ${
                            theme === 'dark'
                                ? 'border-emerald-500/20 bg-emerald-500/10 text-emerald-400'
                                : 'border-emerald-200 bg-emerald-50 text-emerald-700'
                        }`}>
                            <span className="h-2 w-2 rounded-full bg-emerald-400 animate-pulse" />
                            Rendered by Python in {data.renderMs}ms
                        </span>
                        <span className={`inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm ${
                            theme === 'dark'
                                ? 'border-white/10 bg-white/5 text-zinc-400'
                                : 'border-zinc-200 bg-zinc-100 text-zinc-600'
                        }`}>
                            <AnimatedCounter value={data.totalViews} /> developers have explored this page
                        </span>
                    </div>
                </Reveal>

                <Reveal delay={240}>
                    <a
                        href="#format-section"
                        onClick={scrollToContent}
                        className={`mt-12 inline-block animate-bounce cursor-pointer transition ${
                            theme === 'dark' ? 'text-zinc-600 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'
                        }`}
                        aria-label="Scroll to content"
                    >
                        <svg className="mx-auto h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
                        </svg>
                    </a>
                </Reveal>
            </div>
        </section>
    );
}

/* ── section: .pyx format ────────────────────────────────── */

const PYX_DEMO_CODE = `from pyxle import __version__

HEAD = '<title>My Dashboard</title>'

@server
async def load_dashboard(request):
    user = await get_current_user(request)
    stats = await fetch_stats(user.id)
    return {"user": user.name, "stats": stats}

@action
async def update_settings(request):
    body = await request.json()
    await save_settings(request.state.user_id, body)
    return {"ok": True, "message": "Settings saved"}

# --- client ---
import React from 'react';
import { useAction } from 'pyxle/client';

export default function Dashboard({ data }) {
    const save = useAction('update_settings');

    return (
        <div>
            <h1>Welcome, {data.user}</h1>
            <StatsGrid stats={data.stats} />
            <SettingsForm onSave={save} />
        </div>
    );
}`;

const FORMAT_ANNOTATIONS = [
    { marker: 'HEAD', color: 'text-cyan-400', desc: 'Static or dynamic document head. Strings, lists, or a lambda that receives loader data.', lines: [2] },
    { marker: '@server', color: 'text-yellow-400', desc: 'Async Python function that fetches data. Receives a Starlette Request, returns a dict. It becomes React props.', lines: [4, 5, 6, 7, 8] },
    { marker: '@action', color: 'text-yellow-400', desc: 'Server mutation callable from the browser. useAction() sends a POST, Python processes it, result comes back as JSON.', lines: [10, 11, 12, 13, 14] },
    { marker: 'export default', color: 'text-blue-400', desc: 'Standard React component. Receives { data } from the loader. Server-rendered, then hydrated on the client.', lines: [19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] },
];

function HighlightedCodeWithLines({ code, lang = 'pyx', highlightLines = [] }) {
    const blocks = tokenizeBlock(code, lang);
    const highlightSet = new Set(highlightLines);
    return (
        <>
            {blocks.map((line, i) => (
                <div key={i} className={`-mx-4 sm:-mx-6 px-4 sm:px-6 transition-colors duration-200 ${
                    highlightSet.has(i) ? 'bg-emerald-500/10' : ''
                }`}>
                    {line.map((tok, j) => (
                        tok.cls ? <span key={j} className={tok.cls}>{tok.text}</span> : tok.text
                    ))}
                    {'\n'}
                </div>
            ))}
        </>
    );
}

function PyxFormatSection() {
    const { theme } = useTheme();
    const [activeAnnotation, setActiveAnnotation] = useState(-1);
    const highlightLines = activeAnnotation >= 0 ? FORMAT_ANNOTATIONS[activeAnnotation].lines : [];

    return (
        <section id="format-section" className="relative px-6 py-24 overflow-hidden">
            <div className="relative z-10 mx-auto max-w-6xl">
                <Reveal>
                    <SectionLabel
                        label="The Format"
                        title="One File. Full Stack."
                        subtitle="Python server logic and React UI live in the same .pyx file. The compiler splits them apart. You never think about it."
                    />
                </Reveal>

                <Reveal delay={80}>
                    <div className="grid lg:grid-cols-5 gap-6 items-stretch">
                        <div className="lg:col-span-3 flex min-w-0">
                            <div className={`flex-1 min-w-0 relative rounded-xl border overflow-hidden ${
                                theme === 'dark' ? 'border-white/10 bg-[#111113]' : 'border-zinc-200 bg-[#1a1a2e]'
                            }`}>
                                <div className={`flex items-center gap-2 border-b px-4 py-3 ${
                                    theme === 'dark' ? 'border-white/5' : 'border-zinc-700/30'
                                }`}>
                                    <span className="h-3 w-3 rounded-full bg-red-500/80" />
                                    <span className="h-3 w-3 rounded-full bg-yellow-500/80" />
                                    <span className="h-3 w-3 rounded-full bg-green-500/80" />
                                    <span className="ml-2 text-xs text-zinc-500 font-mono">pages/dashboard.pyx</span>
                                </div>
                                <CopyButton text={PYX_DEMO_CODE} />
                                <pre className="p-4 sm:p-6 text-xs sm:text-sm leading-relaxed font-mono overflow-x-auto text-zinc-300">
                                    <code><HighlightedCodeWithLines code={PYX_DEMO_CODE} highlightLines={highlightLines} /></code>
                                </pre>
                            </div>
                        </div>
                        <div className="lg:col-span-2 space-y-4 flex flex-col">
                            {FORMAT_ANNOTATIONS.map((item, i) => (
                                <Reveal key={i} delay={120 + i * 70}>
                                    <div
                                        className={`rounded-lg border p-4 cursor-pointer transition-all ${
                                            activeAnnotation === i
                                                ? theme === 'dark'
                                                    ? 'border-emerald-500/30 bg-emerald-500/[0.05]'
                                                    : 'border-emerald-500/40 bg-emerald-50/50'
                                                : theme === 'dark'
                                                    ? 'border-white/5 bg-white/[0.02] hover:border-white/10'
                                                    : 'border-zinc-200 bg-zinc-50 hover:border-zinc-300'
                                        }`}
                                        onMouseEnter={() => setActiveAnnotation(i)}
                                        onMouseLeave={() => setActiveAnnotation(-1)}
                                    >
                                        <code className={`text-sm font-mono font-semibold ${item.color}`}>{item.marker}</code>
                                        <p className={`mt-1 text-sm ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>{item.desc}</p>
                                    </div>
                                </Reveal>
                            ))}
                        </div>
                    </div>
                </Reveal>
            </div>
        </section>
    );
}

/* ── section: @server live demo ──────────────────────────── */

const SERVER_CODE = `@server
async def load_playground(request):
    views = increment_playground_views()
    reactions = get_reactions()

    return {
        "serverTime": datetime.now().isoformat(),
        "pythonVersion": platform.python_version(),
        "requestId": uuid.uuid4().hex[:8],
        "renderMs": render_ms,
        "totalViews": views,
        "reactions": reactions,
    }`;

function ServerDemoSection({ data }) {
    const { theme } = useTheme();
    const [refreshing, setRefreshing] = useState(false);
    const [highlight, setHighlight] = useState(false);

    const handleRefresh = useCallback(() => {
        setRefreshing(true);
        refresh().then(() => {
            setRefreshing(false);
            setHighlight(true);
            setTimeout(() => setHighlight(false), 1000);
        }).catch(() => setRefreshing(false));
    }, []);

    const formatTime = (iso) => {
        const d = new Date(iso);
        const pad = (n) => String(n).padStart(2, '0');
        return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
    };

    const fields = [
        { label: 'Server Time', value: formatTime(data.serverTime), changing: true },
        { label: 'Python Version', value: data.pythonVersion, changing: false },
        { label: 'Request ID', value: data.requestId, changing: true },
        { label: 'Platform', value: 'Python + React', changing: false },
        { label: 'Render Time', value: `${data.renderMs}ms`, changing: true },
    ];

    return (
        <section className={`relative px-6 py-24 ${theme === 'dark' ? 'bg-white/[0.01]' : 'bg-zinc-50/50'}`}>
            <div className="relative z-10 mx-auto max-w-6xl">
                <Reveal>
                    <SectionLabel
                        label="Live Demo"
                        title="Server Data"
                        subtitle="The @server loader runs on every request. Python fetches data, React renders it. Refresh to see it change."
                    />
                </Reveal>

                <div className="grid lg:grid-cols-2 gap-6 items-stretch">
                    <Reveal delay={80} className="flex min-w-0">
                        <CodeWindow title="@server loader" code={SERVER_CODE} lang="python" className="flex-1" />
                    </Reveal>

                    <Reveal delay={160} className="flex min-w-0">
                        <div className={`flex-1 rounded-xl border p-6 sm:p-8 flex flex-col ${
                            theme === 'dark' ? 'border-white/10 bg-white/[0.02]' : 'border-zinc-200 bg-white'
                        }`}>
                            <div className="flex items-center justify-between mb-6">
                                <h3 className="text-lg font-semibold">Live Result</h3>
                                <button
                                    onClick={handleRefresh}
                                    disabled={refreshing}
                                    className={`inline-flex items-center gap-2 rounded-lg border px-3 py-1.5 text-xs font-medium transition ${
                                        theme === 'dark'
                                            ? 'border-white/10 bg-white/5 text-zinc-400 hover:bg-white/10 hover:text-white'
                                            : 'border-zinc-200 bg-zinc-100 text-zinc-600 hover:bg-zinc-200 hover:text-zinc-900'
                                    } ${refreshing ? 'opacity-50 cursor-not-allowed' : ''}`}
                                >
                                    <svg className={`h-3.5 w-3.5 ${refreshing ? 'animate-spin' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                                        <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182" />
                                    </svg>
                                    {refreshing ? 'Refreshing...' : 'Re-run loader'}
                                </button>
                            </div>
                            <div className="space-y-4 flex-1">
                                {fields.map((f, i) => (
                                    <div key={f.label} className="flex items-baseline justify-between gap-4">
                                        <span className={`text-xs uppercase tracking-wider ${
                                            theme === 'dark' ? 'text-zinc-500' : 'text-zinc-400'
                                        }`}>{f.label}</span>
                                        <span className={`font-mono text-sm transition-colors duration-500 ${
                                            f.changing && highlight
                                                ? 'text-emerald-400'
                                                : theme === 'dark' ? 'text-zinc-200' : 'text-zinc-800'
                                        }`}>{f.value}</span>
                                    </div>
                                ))}
                            </div>
                            <p className={`mt-auto pt-6 text-xs ${theme === 'dark' ? 'text-zinc-600' : 'text-zinc-400'}`}>
                                This data came from Python, rendered by React, in one file.
                            </p>
                        </div>
                    </Reveal>
                </div>
            </div>
        </section>
    );
}

/* ── section: @action reaction board ─────────────────────── */

const EMOJI_MAP = {
    heart: { icon: '\u2764\uFE0F', label: 'Love' },
    fire: { icon: '\uD83D\uDD25', label: 'Fire' },
    mind_blown: { icon: '\uD83E\uDD2F', label: 'Mind-blown' },
    rocket: { icon: '\uD83D\uDE80', label: 'Rocket' },
    sparkles: { icon: '\u2728', label: 'Sparkles' },
    clap: { icon: '\uD83D\uDC4F', label: 'Clap' },
};

const ACTION_CODE = `@action
async def react_emoji(request):
    body = await request.json()
    emoji = body.get("emoji", "")
    if emoji not in VALID_EMOJIS:
        raise ActionError("Invalid reaction")

    new_count = increment_reaction(emoji)
    return {"ok": True, "emoji": emoji, "count": new_count}`;

const ACTION_CLIENT_CODE = `const react = useAction('react_emoji');

async function handleClick(emoji) {
    const result = await react({ emoji });
    if (result.ok) {
        setCounts(prev => ({ ...prev, [result.emoji]: result.count }));
    }
}`;

function ReactionBoard({ data }) {
    const { theme } = useTheme();
    const react = useAction('react_emoji');
    const [counts, setCounts] = useState(data.reactions || {});
    const [latencies, setLatencies] = useState({});
    const [animating, setAnimating] = useState({});

    const handleClick = async (emoji) => {
        setCounts(prev => ({ ...prev, [emoji]: (prev[emoji] || 0) + 1 }));
        setAnimating(prev => ({ ...prev, [emoji]: true }));
        const start = performance.now();

        const result = await react({ emoji });
        const ms = Math.round(performance.now() - start);

        if (result.ok) {
            setCounts(prev => ({ ...prev, [result.emoji]: result.count }));
            setLatencies(prev => ({ ...prev, [emoji]: ms }));
            setTimeout(() => setLatencies(prev => { const n = { ...prev }; delete n[emoji]; return n; }), 2000);
        } else {
            setCounts(prev => ({ ...prev, [emoji]: Math.max(0, (prev[emoji] || 1) - 1) }));
        }
        setTimeout(() => setAnimating(prev => ({ ...prev, [emoji]: false })), 200);
    };

    const total = Object.values(counts).reduce((a, b) => a + b, 0);

    return (
        <section className="relative px-6 py-24 overflow-hidden">
            <div className="relative z-10 mx-auto max-w-6xl">
                <Reveal>
                    <SectionLabel
                        label="Live Demo"
                        title="Server Actions"
                        subtitle="Click a reaction. It hits Python, writes to SQLite, and returns. Every count is real and persistent."
                    />
                </Reveal>

                <div className="grid lg:grid-cols-2 gap-6 items-stretch">
                    <Reveal delay={80} className="flex min-w-0">
                        <div className={`flex-1 rounded-xl border p-6 sm:p-8 flex flex-col ${
                            theme === 'dark' ? 'border-white/10 bg-white/[0.02]' : 'border-zinc-200 bg-white'
                        }`}>
                            <div className="flex items-center justify-between mb-6">
                                <h3 className="text-lg font-semibold">React to this page</h3>
                                <span className={`text-sm font-mono ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-400'}`}>
                                    <AnimatedCounter value={total} /> total
                                </span>
                            </div>
                            <div className="grid grid-cols-3 gap-3">
                                {Object.entries(EMOJI_MAP).map(([key, { icon, label }]) => (
                                    <button
                                        key={key}
                                        onClick={() => handleClick(key)}
                                        className={`relative flex flex-col items-center gap-2 rounded-xl border p-4 transition-all ${
                                            animating[key] ? 'scale-95' : 'scale-100'
                                        } ${
                                            theme === 'dark'
                                                ? 'border-white/10 bg-white/[0.02] hover:border-emerald-500/30 hover:bg-emerald-500/[0.05]'
                                                : 'border-zinc-200 bg-white hover:border-emerald-500/30 hover:bg-emerald-50/50'
                                        }`}
                                    >
                                        <span className="text-2xl select-none">{icon}</span>
                                        <span className={`text-xs ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-400'}`}>{label}</span>
                                        <span className={`font-mono text-sm font-semibold ${
                                            theme === 'dark' ? 'text-zinc-300' : 'text-zinc-700'
                                        }`}>{counts[key] || 0}</span>
                                        {latencies[key] && (
                                            <span className="absolute -top-2 -right-2 rounded-full bg-emerald-500 px-1.5 py-0.5 text-[10px] font-mono text-white animate-fade-in">
                                                {latencies[key]}ms
                                            </span>
                                        )}
                                    </button>
                                ))}
                            </div>
                            <p className={`mt-auto pt-6 text-xs ${theme === 'dark' ? 'text-zinc-600' : 'text-zinc-400'}`}>
                                Every click is a POST to Python. No API routes needed.
                            </p>
                        </div>
                    </Reveal>

                    <Reveal delay={160} className="flex min-w-0">
                        <div className="flex-1 min-w-0 space-y-4 flex flex-col">
                            <CodeWindow title="Python @action" code={ACTION_CODE} lang="python" className="flex-1" />
                            <CodeWindow title="React client" code={ACTION_CLIENT_CODE} lang="js" />
                        </div>
                    </Reveal>
                </div>
            </div>
        </section>
    );
}

/* ── section: text transform ─────────────────────────────── */

const TRANSFORM_MODES = [
    { key: 'upper', label: 'UPPER' },
    { key: 'lower', label: 'lower' },
    { key: 'title', label: 'Title' },
    { key: 'reverse', label: 'esreveR' },
    { key: 'word_count', label: 'Words' },
    { key: 'char_count', label: 'Chars' },
];

const TRANSFORM_CODE = `@action
async def transform_text(request):
    body = await request.json()
    text = (body.get("text", "") or "")[:500]
    mode = body.get("mode", "upper")
    transforms = {
        "upper": str.upper,
        "lower": str.lower,
        "title": str.title,
        "reverse": lambda t: t[::-1],
        "word_count": lambda t: str(len(t.split())) + " words",
        "char_count": lambda t: str(len(t)) + " characters",
    }
    return {"ok": True, "result": transforms[mode](text)}`;

function TextTransformSection() {
    const { theme } = useTheme();
    const transform = useAction('transform_text');
    const [text, setText] = useState('');
    const [mode, setMode] = useState('upper');
    const [result, setResult] = useState('');
    const timerRef = useRef(null);

    const runTransform = useCallback(async (t, m) => {
        if (!t.trim()) { setResult(''); return; }
        const res = await transform({ text: t, mode: m });
        if (res.ok) setResult(res.result);
    }, [transform]);

    useEffect(() => {
        if (timerRef.current) clearTimeout(timerRef.current);
        timerRef.current = setTimeout(() => runTransform(text, mode), 300);
        return () => clearTimeout(timerRef.current);
    }, [text, mode, runTransform]);

    return (
        <section className={`relative px-6 py-24 ${theme === 'dark' ? 'bg-white/[0.01]' : 'bg-zinc-50/50'}`}>
            <div className="relative z-10 mx-auto max-w-6xl">
                <Reveal>
                    <SectionLabel
                        label="Live Demo"
                        title="Multiple Actions, One File"
                        subtitle="A second @action in the same file. Type text, pick a transform — Python processes it on the server."
                    />
                </Reveal>

                <div className="grid lg:grid-cols-2 gap-6 items-stretch">
                    <Reveal delay={80} className="flex min-w-0">
                        <div className={`flex-1 rounded-xl border p-6 sm:p-8 ${
                            theme === 'dark' ? 'border-white/10 bg-white/[0.02]' : 'border-zinc-200 bg-white'
                        }`}>
                            <div className="mb-4">
                                <input
                                    type="text"
                                    value={text}
                                    onChange={(e) => setText(e.target.value)}
                                    placeholder="Type something..."
                                    maxLength={500}
                                    className={`w-full rounded-lg border px-4 py-3 text-sm outline-none transition placeholder:text-zinc-500 focus:ring-2 focus:ring-emerald-500/40 ${
                                        theme === 'dark'
                                            ? 'border-white/10 bg-white/5 text-white'
                                            : 'border-zinc-300 bg-white text-zinc-900'
                                    }`}
                                />
                            </div>
                            <div className="flex flex-wrap gap-2 mb-6">
                                {TRANSFORM_MODES.map(m => (
                                    <button
                                        key={m.key}
                                        onClick={() => setMode(m.key)}
                                        className={`rounded-lg border px-3 py-1.5 text-xs font-medium transition ${
                                            mode === m.key
                                                ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400'
                                                : theme === 'dark'
                                                    ? 'border-white/10 bg-white/5 text-zinc-400 hover:bg-white/10'
                                                    : 'border-zinc-200 bg-zinc-100 text-zinc-600 hover:bg-zinc-200'
                                        }`}
                                    >
                                        {m.label}
                                    </button>
                                ))}
                            </div>
                            <div className={`min-h-[60px] rounded-lg border p-4 font-mono text-sm transition-all ${
                                theme === 'dark'
                                    ? 'border-white/5 bg-white/[0.02] text-zinc-300'
                                    : 'border-zinc-200 bg-zinc-50 text-zinc-700'
                            }`}>
                                {transform.pending ? (
                                    <span className={theme === 'dark' ? 'text-zinc-600' : 'text-zinc-400'}>Processing...</span>
                                ) : result ? (
                                    result
                                ) : (
                                    <span className={theme === 'dark' ? 'text-zinc-700' : 'text-zinc-300'}>Result appears here...</span>
                                )}
                            </div>
                        </div>
                    </Reveal>

                    <Reveal delay={160} className="flex min-w-0">
                        <CodeWindow title="@action transform_text" code={TRANSFORM_CODE} lang="python" className="flex-1" />
                    </Reveal>
                </div>
            </div>
        </section>
    );
}

/* ── section: SPA navigation ─────────────────────────────── */

const NAV_PAGES = [
    { href: '/', title: 'Home', desc: 'Landing page with hero, features, and benchmarks' },
    { href: '/benchmarks', title: 'Benchmarks', desc: 'Performance comparison against FastAPI, Django, and more' },
    { href: '/docs', title: 'Documentation', desc: 'Full docs with search, code examples, and guides' },
];

function SPANavSection() {
    const { theme } = useTheme();

    return (
        <section className="relative px-6 py-24 overflow-hidden">
            <div className="relative z-10 mx-auto max-w-6xl">
                <Reveal>
                    <SectionLabel
                        label="Navigation"
                        title="Instant Page Transitions"
                        subtitle="Click any link below. No reload, no white flash. Pyxle fetches only the data and swaps React props."
                    />
                </Reveal>

                <div className="grid sm:grid-cols-3 gap-4">
                    {NAV_PAGES.map((page, i) => (
                        <Reveal key={page.href} delay={80 + i * 70}>
                            <Link
                                href={page.href}
                                className={`group block rounded-xl border p-6 transition-all ${
                                    theme === 'dark'
                                        ? 'border-white/10 bg-white/[0.02] hover:border-emerald-500/30 hover:bg-emerald-500/[0.03]'
                                        : 'border-zinc-200 bg-white hover:border-emerald-500/30 hover:bg-emerald-50/50'
                                }`}
                            >
                                <h3 className="text-lg font-semibold flex items-center gap-2">
                                    {page.title}
                                    <svg className="h-4 w-4 opacity-0 -translate-x-1 transition group-hover:opacity-100 group-hover:translate-x-0 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                                        <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                                    </svg>
                                </h3>
                                <p className={`mt-2 text-sm ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>{page.desc}</p>
                                <span className={`inline-block mt-3 font-mono text-xs ${theme === 'dark' ? 'text-zinc-600' : 'text-zinc-400'}`}>{page.href}</span>
                            </Link>
                        </Reveal>
                    ))}
                </div>

                <Reveal delay={300}>
                    <p className={`mt-8 text-sm text-center ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-400'}`}>
                        View page source (Ctrl+U) — the HTML is already there. Server-rendered by Python.
                    </p>
                </Reveal>
            </div>
        </section>
    );
}

/* ── section: file routing ───────────────────────────────── */

const FILE_TREE = [
    { file: 'pages/', url: null, indent: 0, type: 'dir' },
    { file: 'index.pyx', url: '/', indent: 1, type: 'page' },
    { file: 'playground.pyx', url: '/playground', indent: 1, type: 'page', current: true },
    { file: 'benchmarks.pyx', url: '/benchmarks', indent: 1, type: 'page' },
    { file: 'not-found.pyx', url: null, indent: 1, type: 'special', label: '(404)' },
    { file: 'layout.pyx', url: null, indent: 1, type: 'special', label: '(layout)' },
    { file: 'docs/', url: null, indent: 1, type: 'dir' },
    { file: '[[...slug]].pyx', url: '/docs', indent: 2, type: 'page', label: '/docs/*' },
    { file: 'api/', url: null, indent: 1, type: 'dir' },
    { file: 'healthz.py', url: '/api/healthz', indent: 2, type: 'api' },
];

function FileRoutingSection() {
    const { theme } = useTheme();

    return (
        <section className={`relative px-6 py-24 ${theme === 'dark' ? 'bg-white/[0.01]' : 'bg-zinc-50/50'}`}>
            <div className="relative z-10 mx-auto max-w-6xl">
                <Reveal>
                    <SectionLabel
                        label="Routing"
                        title="Files Are Routes"
                        subtitle="Drop a .pyx file in pages/. It's a route. Dynamic segments, catch-all routes, layouts — zero configuration."
                    />
                </Reveal>

                <Reveal delay={80}>
                    <div className={`rounded-xl border overflow-hidden max-w-2xl ${
                        theme === 'dark' ? 'border-white/10 bg-[#111113]' : 'border-zinc-200 bg-[#1a1a2e]'
                    }`}>
                        <div className={`flex items-center gap-2 border-b px-4 py-3 ${
                            theme === 'dark' ? 'border-white/5' : 'border-zinc-700/30'
                        }`}>
                            <span className="h-3 w-3 rounded-full bg-red-500/80" />
                            <span className="h-3 w-3 rounded-full bg-yellow-500/80" />
                            <span className="h-3 w-3 rounded-full bg-green-500/80" />
                            <span className="ml-2 text-xs text-zinc-500 font-mono">pyxle routes</span>
                        </div>
                        <div className="p-4 sm:p-6 font-mono text-xs sm:text-sm">
                            {FILE_TREE.map((item, i) => {
                                const pad = item.indent * 24;
                                const routeLabel = item.label || item.url;
                                const isClickable = item.url && !item.current;

                                const content = (
                                    <div
                                        key={i}
                                        className={`flex items-center justify-between py-1.5 px-2 -mx-2 rounded transition ${
                                            item.current
                                                ? 'bg-emerald-500/10'
                                                : isClickable
                                                    ? 'hover:bg-white/5 cursor-pointer'
                                                    : ''
                                        }`}
                                        style={{ paddingLeft: `${pad + 8}px` }}
                                    >
                                        <span className="flex items-center gap-2">
                                            {item.type === 'dir' ? (
                                                <svg className="h-4 w-4 text-yellow-400/70" fill="currentColor" viewBox="0 0 20 20">
                                                    <path d="M2 6a2 2 0 012-2h5l2 2h5a2 2 0 012 2v6a2 2 0 01-2 2H4a2 2 0 01-2-2V6z" />
                                                </svg>
                                            ) : item.type === 'api' ? (
                                                <svg className="h-4 w-4 text-cyan-400/70" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                                                    <path strokeLinecap="round" strokeLinejoin="round" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                                </svg>
                                            ) : (
                                                <svg className={`h-4 w-4 ${item.type === 'special' ? 'text-zinc-500' : 'text-emerald-400/70'}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                                                    <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                                </svg>
                                            )}
                                            <span className={item.current ? 'text-emerald-400' : 'text-zinc-300'}>{item.file}</span>
                                            {item.current && <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />}
                                        </span>
                                        {routeLabel && (
                                            <span className={`text-xs ${item.current ? 'text-emerald-400/70' : 'text-zinc-500'}`}>
                                                {routeLabel}
                                            </span>
                                        )}
                                    </div>
                                );

                                if (isClickable) {
                                    return <Link key={i} href={item.url} className="block">{content}</Link>;
                                }
                                return <div key={i}>{content}</div>;
                            })}
                        </div>
                    </div>
                </Reveal>
            </div>
        </section>
    );
}

/* ── section: feature grid ───────────────────────────────── */

const FEATURES = [
    { title: 'SSR + Hydration', desc: 'Every page server-rendered, then hydrated. Fast first paint, great SEO.', icon: 'M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2' },
    { title: 'CSRF Protection', desc: 'Enabled by default. Double-submit cookie pattern. Zero config.', icon: 'M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z' },
    { title: 'Error Boundaries', desc: 'error.pyx files catch errors at any directory level.', icon: 'M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z' },
    { title: 'Nested Layouts', desc: 'Compose UIs with layout.pyx. Each level wraps the level below.', icon: 'M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z' },
    { title: 'Head Management', desc: 'Dynamic <title>, meta tags via HEAD variable or <Head> component.', icon: 'M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25' },
    { title: 'Middleware', desc: 'Application-level and route-level hooks. Full Starlette integration.', icon: 'M10.5 6h9.75M10.5 6a1.5 1.5 0 11-3 0m3 0a1.5 1.5 0 10-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-9.75 0h9.75' },
    { title: 'API Routes', desc: 'Pure Python endpoints under pages/api/. Any HTTP method.', icon: 'M7.5 21L3 16.5m0 0L7.5 12M3 16.5h13.5m0-13.5L21 7.5m0 0L16.5 12M21 7.5H7.5' },
    { title: 'Env Variables', desc: 'PYXLE_PUBLIC_ prefix for safe client injection. Server secrets stay secret.', icon: 'M15.75 5.25a3 3 0 013 3m3 0a6 6 0 01-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1121.75 8.25z' },
    { title: 'TypeScript', desc: 'Optional type checking. IDE support coming soon.', icon: 'M6.75 7.5l3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0021 18V6a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 6v12a2.25 2.25 0 002.25 2.25z' },
    { title: 'Tailwind CSS', desc: 'Pre-configured with dark mode. Built-in watcher in dev.', icon: 'M9.53 16.122a3 3 0 00-5.78 1.128 2.25 2.25 0 01-2.4 2.245 4.5 4.5 0 008.4-2.245c0-.399-.078-.78-.22-1.128zm0 0a15.998 15.998 0 003.388-1.62m-5.043-.025a15.994 15.994 0 011.622-3.395m3.42 3.42a15.995 15.995 0 004.764-4.648l3.876-5.814a1.151 1.151 0 00-1.597-1.597L14.146 6.32a15.996 15.996 0 00-4.649 4.763m3.42 3.42a6.776 6.776 0 00-3.42-3.42' },
    { title: 'Progressive Enhancement', desc: '<Form> works without JavaScript. Actions degrade gracefully.', icon: 'M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z' },
    { title: 'Hot Reload', desc: 'Python + JSX changes reflect instantly. Vite HMR built in.', icon: 'M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182' },
];

function FeatureGrid() {
    const { theme } = useTheme();
    return (
        <section className="relative px-6 py-24 overflow-hidden">
            <div className="relative z-10 mx-auto max-w-6xl">
                <Reveal>
                    <SectionLabel
                        label="Features"
                        title="And There's More"
                        subtitle="Everything you need to build production-ready full-stack apps."
                    />
                </Reveal>

                <div className="grid sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                    {FEATURES.map((f, i) => (
                        <Reveal key={f.title} delay={i * 50}>
                            <div className={`rounded-xl border p-5 transition ${
                                theme === 'dark'
                                    ? 'border-white/5 bg-white/[0.02] hover:border-emerald-500/20 hover:bg-emerald-500/[0.03]'
                                    : 'border-zinc-200 bg-white hover:border-emerald-500/30 hover:bg-emerald-50/50'
                            }`}>
                                <div className={`inline-flex rounded-lg border p-2 text-emerald-400 mb-3 ${
                                    theme === 'dark' ? 'border-white/10 bg-white/5' : 'border-zinc-200 bg-zinc-50'
                                }`}>
                                    <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" d={f.icon} />
                                    </svg>
                                </div>
                                <h3 className="text-sm font-semibold mb-1">{f.title}</h3>
                                <p className={`text-xs leading-relaxed ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-500'}`}>{f.desc}</p>
                            </div>
                        </Reveal>
                    ))}
                </div>
            </div>
        </section>
    );
}

/* ── section: ecosystem ──────────────────────────────────── */

const ECOSYSTEM = [
    {
        title: 'Pyxle Auth',
        desc: 'Drop-in authentication and session management. OAuth providers, email/password, magic links — all pre-wired.',
        icon: 'M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z',
    },
    {
        title: 'Pyxle DB',
        desc: 'Database toolkit with migrations, query builder, and connection pooling. SQLite to Postgres — same API.',
        icon: 'M20.25 6.375c0 2.278-3.694 4.125-8.25 4.125S3.75 8.653 3.75 6.375m16.5 0c0-2.278-3.694-4.125-8.25-4.125S3.75 4.097 3.75 6.375m16.5 0v11.25c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125V6.375m16.5 0v3.75m-16.5-3.75v3.75m16.5 0v3.75C20.25 16.153 16.556 18 12 18s-8.25-1.847-8.25-4.125v-3.75m16.5 0c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125',
    },
    {
        title: 'Pyxle Langkit',
        desc: 'VS Code extension with .pyx syntax highlighting, go-to-definition, inline diagnostics, and autocomplete.',
        icon: 'M6.75 7.5l3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0021 18V6a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 6v12a2.25 2.25 0 002.25 2.25z',
    },
    {
        title: 'Debug Tools',
        desc: 'Built-in error overlay, request inspector, and performance profiling. See exactly what your server does.',
        icon: 'M12 12.75c1.148 0 2.278.08 3.383.237 1.037.146 1.866.966 1.866 2.013 0 3.728-2.35 6.75-5.25 6.75S6.75 18.728 6.75 15c0-1.046.83-1.867 1.866-2.013A24.204 24.204 0 0112 12.75zm0 0c2.883 0 5.647.508 8.207 1.44a23.91 23.91 0 01-1.152 6.06M12 12.75c-2.883 0-5.647.508-8.208 1.44.125 2.104.52 4.136 1.153 6.06M12 12.75a2.25 2.25 0 002.248-2.354M12 12.75a2.25 2.25 0 01-2.248-2.354M12 8.25c.995 0 1.971-.08 2.922-.236.403-.066.74-.358.795-.762a3.778 3.778 0 00-.399-2.25M12 8.25c-.995 0-1.97-.08-2.922-.236-.402-.066-.74-.358-.795-.762a3.734 3.734 0 01.4-2.253M12 8.25a2.25 2.25 0 00-2.248 2.146M12 8.25a2.25 2.25 0 012.248 2.146M8.683 5a6.032 6.032 0 01-1.155-1.002c.07-.63.27-1.222.574-1.747m.581 2.749A3.75 3.75 0 0115.318 5m0 0c.427-.283.815-.62 1.155-.999a4.471 4.471 0 00-.575-1.752M4.921 6a24.048 24.048 0 00-.392 3.314c1.668.546 3.416.914 5.223 1.082M19.08 6c.205 1.08.337 2.187.392 3.314a23.882 23.882 0 01-5.223 1.082',
    },
];

function EcosystemSection() {
    const { theme } = useTheme();
    return (
        <section className={`relative px-6 py-24 ${theme === 'dark' ? 'bg-white/[0.01]' : 'bg-zinc-50/50'}`}>
            <div className="relative z-10 mx-auto max-w-4xl">
                <Reveal>
                    <SectionLabel
                        label="Ecosystem"
                        title="The Foundation Is Solid"
                        subtitle="Pyxle is production-ready today. These tools are in active development to make the ecosystem even more powerful."
                    />
                </Reveal>

                <div className="grid sm:grid-cols-2 gap-5">
                    {ECOSYSTEM.map((item, i) => (
                        <Reveal key={item.title} delay={80 + i * 70}>
                            <div className={`rounded-xl border p-6 sm:p-8 h-full transition ${
                                theme === 'dark'
                                    ? 'border-white/10 bg-white/[0.02] hover:border-emerald-500/20 hover:bg-emerald-500/[0.02]'
                                    : 'border-zinc-200 bg-white hover:border-emerald-500/30 hover:bg-emerald-50/30'
                            }`}>
                                <div className="flex items-start gap-4">
                                    <div className={`flex-shrink-0 inline-flex rounded-lg border p-2.5 text-emerald-400 ${
                                        theme === 'dark' ? 'border-white/10 bg-white/5' : 'border-zinc-200 bg-zinc-50'
                                    }`}>
                                        <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                                            <path strokeLinecap="round" strokeLinejoin="round" d={item.icon} />
                                        </svg>
                                    </div>
                                    <div>
                                        <div className="flex items-center gap-2 mb-2">
                                            <h3 className="font-semibold">{item.title}</h3>
                                            <span className={`rounded-full border px-2 py-0.5 text-[10px] font-medium ${
                                                theme === 'dark'
                                                    ? 'border-white/10 bg-white/5 text-zinc-500'
                                                    : 'border-zinc-200 bg-zinc-100 text-zinc-500'
                                            }`}>
                                                Coming soon
                                            </span>
                                        </div>
                                        <p className={`text-sm leading-relaxed ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>{item.desc}</p>
                                    </div>
                                </div>
                            </div>
                        </Reveal>
                    ))}
                </div>
            </div>
        </section>
    );
}

/* ── section: CTA ────────────────────────────────────────── */

function CTASection() {
    const { theme } = useTheme();
    return (
        <section className="relative px-6 py-24 overflow-hidden">
            <div className="relative z-10 mx-auto max-w-3xl text-center">
                <Reveal>
                    <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
                        Ready to Build?
                    </h2>
                    <p className={`mt-4 text-lg ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>
                        Get started in under a minute.
                    </p>
                </Reveal>

                <Reveal delay={80}>
                    <div className="mt-8 space-y-3 max-w-lg mx-auto text-left">
                        {[
                            'pip install pyxle-framework',
                            'pyxle init my-app && cd my-app',
                            'pyxle install',
                            'pyxle dev',
                        ].map((cmd, i) => (
                            <div key={i} className={`relative group rounded-lg border font-mono text-sm px-4 py-3 ${
                                theme === 'dark'
                                    ? 'border-white/10 bg-white/[0.02] text-emerald-400'
                                    : 'border-zinc-200 bg-zinc-50 text-emerald-600'
                            }`}>
                                <span className={`mr-2 select-none ${theme === 'dark' ? 'text-zinc-600' : 'text-zinc-400'}`}>$</span>
                                {cmd}
                                <CopyButton text={cmd} />
                            </div>
                        ))}
                    </div>
                </Reveal>

                <Reveal delay={160}>
                    <div className="mt-10 flex flex-wrap items-center justify-center gap-4">
                        <Link
                            href="/docs"
                            className={`rounded-xl px-6 py-3 text-sm font-semibold transition ${
                                theme === 'dark'
                                    ? 'bg-white text-black hover:bg-zinc-200'
                                    : 'bg-zinc-900 text-white hover:bg-zinc-700'
                            }`}
                        >
                            Read the docs
                        </Link>
                        <a
                            href="https://github.com/pyxle-framework/pyxle"
                            target="_blank"
                            rel="noreferrer"
                            className={`inline-flex items-center gap-2 rounded-xl border px-6 py-3 text-sm font-semibold transition ${
                                theme === 'dark'
                                    ? 'border-white/10 text-white hover:bg-white/5'
                                    : 'border-zinc-300 text-zinc-900 hover:bg-zinc-50'
                            }`}
                        >
                            <svg className="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
                            </svg>
                            Star on GitHub
                        </a>
                    </div>
                </Reveal>
            </div>
        </section>
    );
}

/* ── footer ──────────────────────────────────────────────── */

function PlaygroundFooter() {
    const { theme } = useTheme();
    return (
        <footer className={`border-t px-6 py-12 ${theme === 'dark' ? 'border-white/5' : 'border-zinc-200'}`}>
            <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-6 sm:flex-row">
                <div className="flex items-center gap-3">
                    <img src="/branding/pyxle-mark.svg" alt="Pyxle" className="h-6 w-6 opacity-50" />
                    <span className={`text-sm ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-400'}`}>Pyxle Framework</span>
                </div>
                <div className="flex flex-wrap justify-center items-center gap-x-6 gap-y-2">
                    <Link href="/" className={`text-sm transition ${theme === 'dark' ? 'text-zinc-500 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'}`}>Home</Link>
                    <Link href="/docs" className={`text-sm transition ${theme === 'dark' ? 'text-zinc-500 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'}`}>Docs</Link>
                    <Link href="/benchmarks" className={`text-sm transition ${theme === 'dark' ? 'text-zinc-500 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'}`}>Benchmarks</Link>
                    <a href="https://github.com/pyxle-framework/pyxle" target="_blank" rel="noreferrer"
                       className={`text-sm transition ${theme === 'dark' ? 'text-zinc-500 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'}`}>GitHub</a>
                </div>
            </div>
            <div className={`mx-auto max-w-6xl mt-8 pt-6 border-t text-center ${
                theme === 'dark' ? 'border-white/5' : 'border-zinc-100'
            }`}>
                <p className={`text-xs ${theme === 'dark' ? 'text-zinc-600' : 'text-zinc-400'}`}>
                    This site is built with Pyxle.{' '}
                    <a
                        href="https://github.com/pyxle-framework/pyxle-dev"
                        target="_blank"
                        rel="noreferrer"
                        className="underline decoration-dotted underline-offset-2 hover:text-emerald-400 transition"
                    >
                        View source
                    </a>
                </p>
            </div>
        </footer>
    );
}

/* ── page ─────────────────────────────────────────────────── */

export default function PlaygroundPage({ data }) {
    return (
        <>
            <style dangerouslySetInnerHTML={{ __html: HIGHLIGHT_CSS }} />
            <PlaygroundNav version={data.version} />
            <Hero data={data} />
            <PyxFormatSection />
            <ServerDemoSection data={data} />
            <ReactionBoard data={data} />
            <TextTransformSection />
            <SPANavSection />
            <FileRoutingSection />
            <FeatureGrid />
            <EcosystemSection />
            <CTASection />
            <PlaygroundFooter />
        </>
    );
}
