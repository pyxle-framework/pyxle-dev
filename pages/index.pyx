import re as _re
from pyxle import __version__
from pyxle.runtime import ActionError

HEAD = [
    '<title>Pyxle - Python-First Full-Stack Framework</title>',
    '<meta name="description" content="Build like Next.js without leaving Python. Colocate server loaders and React components in .pyx files." />',
    '<meta name="viewport" content="width=device-width, initial-scale=1" />',
    '<link rel="icon" href="/favicon.ico" />',
    '<link rel="preconnect" href="https://fonts.googleapis.com" />',
    '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />',
    '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap" rel="stylesheet" />',
    '<link rel="stylesheet" href="/styles/tailwind.css" />',
    '<meta property="og:title" content="Pyxle - Python-First Full-Stack Framework" />',
    '<meta property="og:description" content="Build like Next.js without leaving Python." />',
]

_EMAIL_RE = _re.compile(r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$")


@server
async def load_home(request):
    return {
        "version": __version__,
    }


@action
async def subscribe_newsletter(request):
    import sys, os
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
    from db import add_subscriber

    body = await request.json()
    email = (body.get("email") or "").strip().lower()

    if not email:
        raise ActionError("Please enter your email address.", status_code=400)

    if not _EMAIL_RE.match(email):
        raise ActionError("Please enter a valid email address.", status_code=400)

    if len(email) > 254:
        raise ActionError("Email address is too long.", status_code=400)

    add_subscriber(email)
    return {"message": "You're on the list! We'll keep you posted."}


# --- client ---
import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useTheme } from './layout.jsx';
import { useAction } from 'pyxle/client';

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

function GradientOrb({ className }) {
    return (
        <div
            className={`pointer-events-none absolute rounded-full blur-[120px] opacity-20 ${className}`}
            aria-hidden="true"
        />
    );
}

/* ── helpers ──────────────────────────────────────────────── */

function scrollToSection(e, id) {
    e.preventDefault();
    const el = document.getElementById(id);
    if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
        window.history.replaceState(null, '', '#' + id);
    }
}

/* ── theme toggle ─────────────────────────────────────────── */

function ThemeToggle() {
    const { theme, toggle } = useTheme();
    return (
        <button
            onClick={toggle}
            className={`rounded-lg border p-2 transition ${
                theme === 'dark'
                    ? 'border-white/10 bg-white/5 text-zinc-400 hover:bg-white/10 hover:text-white'
                    : 'border-zinc-200 bg-zinc-100 text-zinc-600 hover:bg-zinc-200 hover:text-zinc-900'
            }`}
            aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
        >
            {theme === 'dark' ? (
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z" />
                </svg>
            ) : (
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z" />
                </svg>
            )}
        </button>
    );
}

/* ── mobile menu ──────────────────────────────────────────── */

function MobileMenu() {
    const [open, setOpen] = useState(false);
    const { theme } = useTheme();

    return (
        <div className="sm:hidden">
            <button
                onClick={() => setOpen(!open)}
                className={`rounded-lg border p-2 transition ${
                    theme === 'dark'
                        ? 'border-white/10 bg-white/5 text-zinc-400 hover:bg-white/10'
                        : 'border-zinc-200 bg-zinc-100 text-zinc-600 hover:bg-zinc-200'
                }`}
                aria-label="Toggle menu"
            >
                {open ? (
                    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                ) : (
                    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 9h16.5m-16.5 6.75h16.5" />
                    </svg>
                )}
            </button>
            {open && (
                <div className={`absolute top-full left-0 right-0 border-b p-4 flex flex-col gap-3 ${
                    theme === 'dark'
                        ? 'bg-[#0a0a0b]/95 backdrop-blur-xl border-white/5'
                        : 'bg-white/95 backdrop-blur-xl border-zinc-200'
                }`}>
                    <a href="#code" onClick={(e) => { scrollToSection(e, 'code'); setOpen(false); }}
                       className={`text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Code</a>
                    <a href="#features" onClick={(e) => { scrollToSection(e, 'features'); setOpen(false); }}
                       className={`text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Features</a>
                    <a href="#get-started" onClick={(e) => { scrollToSection(e, 'get-started'); setOpen(false); }}
                       className={`text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Get Started</a>
                    <a href="https://docs.pyxle.dev" target="_blank" rel="noreferrer"
                       className={`text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Docs</a>
                    <a href="https://github.com/shivamsn97/pyxle" target="_blank" rel="noreferrer"
                       className={`text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>GitHub</a>
                </div>
            )}
        </div>
    );
}

/* ── nav ──────────────────────────────────────────────────── */

function Nav({ version }) {
    const [scrolled, setScrolled] = useState(false);
    const { theme } = useTheme();

    useEffect(() => {
        const onScroll = () => setScrolled(window.scrollY > 20);
        window.addEventListener('scroll', onScroll, { passive: true });
        return () => window.removeEventListener('scroll', onScroll);
    }, []);

    return (
        <nav
            className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
                scrolled
                    ? theme === 'dark'
                        ? 'bg-[#0a0a0b]/80 backdrop-blur-xl border-b border-white/5'
                        : 'bg-white/80 backdrop-blur-xl border-b border-zinc-200'
                    : ''
            }`}
        >
            <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
                <div className="flex items-center gap-3">
                    <a
                        href="#"
                        onClick={(e) => { e.preventDefault(); window.scrollTo({ top: 0, behavior: 'smooth' }); window.history.replaceState(null, '', window.location.pathname); }}
                        className="flex items-center gap-3 cursor-pointer"
                    >
                        <img src="/branding/pyxle-mark.svg" alt="Pyxle" className="h-8 w-8" />
                        <span className="text-lg font-semibold tracking-tight">Pyxle</span>
                    </a>
                    <span className={`hidden xs:inline rounded-full px-2 py-0.5 text-xs font-medium text-emerald-400 border ${
                        theme === 'dark' ? 'bg-emerald-500/10 border-emerald-500/20' : 'bg-emerald-50 border-emerald-200'
                    }`}>
                        v{version}
                    </span>
                </div>
                <div className="flex items-center gap-4">
                    <a href="#code" onClick={(e) => scrollToSection(e, 'code')}
                       className={`hidden sm:block text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Code</a>
                    <a href="#features" onClick={(e) => scrollToSection(e, 'features')}
                       className={`hidden sm:block text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Features</a>
                    <a href="#get-started" onClick={(e) => scrollToSection(e, 'get-started')}
                       className={`hidden sm:block text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Get Started</a>
                    <a href="https://docs.pyxle.dev" target="_blank" rel="noreferrer"
                       className={`hidden sm:block text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Docs</a>
                    <a
                        href="https://github.com/shivamsn97/pyxle"
                        target="_blank"
                        rel="noreferrer"
                        className={`hidden sm:inline-flex items-center gap-2 rounded-lg border px-4 py-2 text-sm font-medium transition ${
                            theme === 'dark'
                                ? 'border-white/10 bg-white/5 text-white hover:bg-white/10'
                                : 'border-zinc-200 bg-zinc-100 text-zinc-900 hover:bg-zinc-200'
                        }`}
                    >
                        <svg className="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
                        </svg>
                        GitHub
                    </a>
                    <ThemeToggle />
                    <MobileMenu />
                </div>
            </div>
        </nav>
    );
}

/* ── hero ─────────────────────────────────────────────────── */

function HeroBackground() {
    const canvasRef = useRef(null);
    const mouseRef = useRef({ x: 0.5, y: 0.5, tx: 0.5, ty: 0.5 });
    const animRef = useRef(null);
    const { theme } = useTheme();

    useEffect(() => {
        const canvas = canvasRef.current;
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        let w, h;

        const isDark = theme === 'dark';
        /* Aurora ribbon config — each ribbon is a flowing sine-wave band */
        const ribbons = isDark ? [
            { y: 0.20, amp: 0.12, freq: 1.2, speed: 0.15, width: 0.35, color: [16, 185, 129], opacity: 0.04 },
            { y: 0.32, amp: 0.10, freq: 0.9, speed: -0.12, width: 0.30, color: [6, 182, 212], opacity: 0.035 },
            { y: 0.42, amp: 0.14, freq: 1.5, speed: 0.18, width: 0.25, color: [37, 99, 235], opacity: 0.03 },
            { y: 0.28, amp: 0.08, freq: 0.7, speed: -0.09, width: 0.40, color: [139, 92, 246], opacity: 0.025 },
            { y: 0.50, amp: 0.11, freq: 1.1, speed: 0.14, width: 0.20, color: [16, 185, 129], opacity: 0.02 },
        ] : [
            { y: 0.20, amp: 0.12, freq: 1.2, speed: 0.15, width: 0.35, color: [16, 185, 129], opacity: 0.07 },
            { y: 0.32, amp: 0.10, freq: 0.9, speed: -0.12, width: 0.30, color: [6, 182, 212], opacity: 0.06 },
            { y: 0.42, amp: 0.14, freq: 1.5, speed: 0.18, width: 0.25, color: [37, 99, 235], opacity: 0.05 },
            { y: 0.28, amp: 0.08, freq: 0.7, speed: -0.09, width: 0.40, color: [139, 92, 246], opacity: 0.04 },
            { y: 0.50, amp: 0.11, freq: 1.1, speed: 0.14, width: 0.20, color: [16, 185, 129], opacity: 0.035 },
        ];

        function resize() {
            const dpr = Math.min(window.devicePixelRatio || 1, 2);
            w = canvas.offsetWidth;
            h = canvas.offsetHeight;
            canvas.width = w * dpr;
            canvas.height = h * dpr;
            ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        }

        function draw(t) {
            ctx.clearRect(0, 0, w, h);

            /* smooth mouse lerp */
            const m = mouseRef.current;
            m.x += (m.tx - m.x) * 0.05;
            m.y += (m.ty - m.y) * 0.05;
            const mx = m.x - 0.5;  /* -0.5 to 0.5 */
            const my = m.y - 0.5;

            const time = t * 0.001;
            const cols = Math.max(60, Math.floor(w / 12));

            for (const r of ribbons) {
                ctx.beginPath();
                const baseY = r.y * h;

                /* Draw top edge of ribbon */
                for (let i = 0; i <= cols; i++) {
                    const px = (i / cols) * w;
                    const nx = i / cols;  /* 0-1 */

                    /* layered sine waves for organic motion */
                    const wave1 = Math.sin(nx * Math.PI * 2 * r.freq + time * r.speed) * r.amp * h;
                    const wave2 = Math.sin(nx * Math.PI * 3.7 + time * r.speed * 0.7 + 1.3) * r.amp * h * 0.3;
                    const wave3 = Math.cos(nx * Math.PI * 1.3 + time * r.speed * 1.3 + 2.7) * r.amp * h * 0.15;

                    /* mouse influence — gentle displacement toward pointer */
                    const distFactor = 1 - Math.abs(nx - (m.x)) * 1.5;
                    const mouseOffset = Math.max(0, distFactor) * my * h * 0.08;

                    const py = baseY + wave1 + wave2 + wave3 + mouseOffset;
                    if (i === 0) ctx.moveTo(px, py);
                    else ctx.lineTo(px, py);
                }

                /* Draw bottom edge in reverse to close the ribbon shape */
                for (let i = cols; i >= 0; i--) {
                    const px = (i / cols) * w;
                    const nx = i / cols;

                    const wave1 = Math.sin(nx * Math.PI * 2 * r.freq + time * r.speed + 0.5) * r.amp * h * 0.6;
                    const wave2 = Math.sin(nx * Math.PI * 2.9 + time * r.speed * 0.5 + 0.8) * r.amp * h * 0.2;

                    const distFactor = 1 - Math.abs(nx - (m.x)) * 1.5;
                    const mouseOffset = Math.max(0, distFactor) * my * h * 0.06;

                    const py = baseY + r.width * h + wave1 + wave2 + mouseOffset;
                    ctx.lineTo(px, py);
                }

                ctx.closePath();

                /* Gradient fill along the ribbon */
                const [cr, cg, cb] = r.color;
                const grad = ctx.createLinearGradient(0, baseY - r.amp * h, 0, baseY + r.width * h + r.amp * h);
                grad.addColorStop(0, `rgba(${cr},${cg},${cb},0)`);
                grad.addColorStop(0.3, `rgba(${cr},${cg},${cb},${r.opacity})`);
                grad.addColorStop(0.5, `rgba(${cr},${cg},${cb},${r.opacity * 1.5})`);
                grad.addColorStop(0.7, `rgba(${cr},${cg},${cb},${r.opacity})`);
                grad.addColorStop(1, `rgba(${cr},${cg},${cb},0)`);
                ctx.fillStyle = grad;
                ctx.fill();
            }

            /* central glow that subtly follows mouse */
            const glowX = w * 0.5 + mx * w * 0.15;
            const glowY = h * 0.35 + my * h * 0.1;
            const glowR = Math.min(w, h) * 0.45;
            const glow = ctx.createRadialGradient(glowX, glowY, 0, glowX, glowY, glowR);
            if (isDark) {
                glow.addColorStop(0, 'rgba(16,185,129,0.06)');
                glow.addColorStop(0.5, 'rgba(6,182,212,0.03)');
            } else {
                glow.addColorStop(0, 'rgba(16,185,129,0.1)');
                glow.addColorStop(0.5, 'rgba(6,182,212,0.05)');
            }
            glow.addColorStop(1, 'rgba(0,0,0,0)');
            ctx.fillStyle = glow;
            ctx.fillRect(0, 0, w, h);

            animRef.current = requestAnimationFrame(draw);
        }

        resize();
        animRef.current = requestAnimationFrame(draw);
        window.addEventListener('resize', resize, { passive: true });

        function handleMouse(e) {
            const rect = canvas.getBoundingClientRect();
            mouseRef.current.tx = (e.clientX - rect.left) / rect.width;
            mouseRef.current.ty = (e.clientY - rect.top) / rect.height;
        }
        canvas.addEventListener('mousemove', handleMouse, { passive: true });

        return () => {
            if (animRef.current) cancelAnimationFrame(animRef.current);
            window.removeEventListener('resize', resize);
            canvas.removeEventListener('mousemove', handleMouse);
        };
    }, [theme]);

    return (
        <canvas
            ref={canvasRef}
            className="pointer-events-auto absolute inset-0 h-full w-full"
            aria-hidden="true"
        />
    );
}

function Hero() {
    const { theme } = useTheme();
    return (
        <section className="relative flex min-h-[90vh] flex-col items-center justify-center px-6 pt-24 text-center overflow-hidden">
            <HeroBackground />

            <div className="relative z-10 max-w-4xl">
                <div className={`mb-6 inline-flex items-center gap-2 rounded-full border px-4 py-1.5 text-sm ${
                    theme === 'dark'
                        ? 'border-white/10 bg-white/5 text-zinc-400'
                        : 'border-zinc-200 bg-zinc-100 text-zinc-600'
                }`}>
                    <span className="h-2 w-2 rounded-full bg-emerald-400 animate-pulse" />
                    Now in public beta
                </div>

                <h1 className="text-4xl font-bold leading-[1.1] tracking-tight sm:text-5xl md:text-7xl">
                    Build full-stack with{' '}
                    <span className="bg-gradient-to-r from-emerald-400 via-cyan-400 to-blue-500 bg-clip-text text-transparent">
                        Python + React
                    </span>
                </h1>

                <p className={`mx-auto mt-6 max-w-2xl text-base leading-relaxed sm:text-lg md:text-xl ${
                    theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'
                }`}>
                    Pyxle colocates server logic and UI in one{' '}
                    <code className={`rounded px-1.5 py-0.5 text-sm font-mono text-emerald-500 ${
                        theme === 'dark' ? 'bg-white/5' : 'bg-emerald-50'
                    }`}>.pyx</code>{' '}
                    file. Write async loaders in Python, render with React, ship with zero config.
                </p>

                <div className="mt-10 flex flex-col items-center gap-4 sm:flex-row sm:justify-center">
                    <a
                        href="#get-started"
                        onClick={(e) => scrollToSection(e, 'get-started')}
                        className={`group inline-flex items-center gap-2 rounded-xl px-6 py-3 text-sm font-semibold transition ${
                            theme === 'dark'
                                ? 'bg-white text-black hover:bg-zinc-200'
                                : 'bg-zinc-900 text-white hover:bg-zinc-700'
                        }`}
                    >
                        Get started
                        <svg
                            className="h-4 w-4 transition group-hover:translate-x-0.5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                            strokeWidth="2"
                        >
                            <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                        </svg>
                    </a>
                    <a
                        href="https://github.com/shivamsn97/pyxle"
                        target="_blank"
                        rel="noreferrer"
                        className={`inline-flex items-center gap-2 rounded-xl border px-6 py-3 text-sm font-semibold transition ${
                            theme === 'dark'
                                ? 'border-white/10 text-white hover:bg-white/5'
                                : 'border-zinc-300 text-zinc-900 hover:bg-zinc-50'
                        }`}
                    >
                        View on GitHub
                    </a>
                </div>
            </div>

            <a
                href="#code"
                onClick={(e) => scrollToSection(e, 'code')}
                className="absolute bottom-8 left-1/2 -translate-x-1/2 animate-bounce cursor-pointer"
                aria-label="Scroll to content"
            >
                <svg className={`h-5 w-5 transition ${theme === 'dark' ? 'text-zinc-500 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
                </svg>
            </a>
        </section>
    );
}

/* ── code showcase ────────────────────────────────────────── */

const DEMO_CODE = `# pages/dashboard.pyx

from pyxle.runtime import server

HEAD = '<title>Dashboard</title>'

@server
async def load_dashboard(request):
    user = await db.get_user(request.state.user_id)
    stats = await db.get_stats(user.id)
    return {"user": user, "stats": stats}


import React from 'react';
import { Head, Link } from 'pyxle/client';

export default function Dashboard({ data }) {
    const { user, stats } = data;
    return (
        <main className="p-8">
            <Head>
                <meta name="robots" content="noindex" />
            </Head>
            <h1>Welcome back, {user.name}</h1>
            <div className="grid grid-cols-3 gap-4">
                {stats.map(s => (
                    <div key={s.label} className="card">
                        <span>{s.value}</span>
                        <span>{s.label}</span>
                    </div>
                ))}
            </div>
            <Link href="/settings">Settings</Link>
        </main>
    );
}`;

/* Simple token-based syntax highlighter for .pyx code */
function HighlightedCode({ code }) {
    const lines = code.split('\n');
    let mode = 'python'; /* python or jsx */

    const pyKeywords = new Set(['from', 'import', 'async', 'def', 'await', 'return', 'class', 'if', 'else', 'for', 'in', 'with', 'as', 'try', 'except', 'raise', 'not', 'and', 'or', 'True', 'False', 'None']);
    const jsKeywords = new Set(['import', 'from', 'export', 'default', 'function', 'const', 'let', 'var', 'return', 'if', 'else', 'for', 'of', 'in', 'new', 'this', 'true', 'false', 'null', 'undefined', 'typeof', 'instanceof']);

    function highlightPython(line) {
        const parts = [];
        /* comment */
        if (line.trimStart().startsWith('#')) {
            parts.push(<span key="c" className="text-zinc-500 italic">{line}</span>);
            return parts;
        }
        /* decorator */
        if (line.trimStart().startsWith('@')) {
            parts.push(<span key="d" className="text-yellow-400">{line}</span>);
            return parts;
        }
        /* tokenize */
        const tokens = line.split(/(\b|(?=['"{}(),:\[\]])|(?<=['"{}(),:\[\]]))/);
        let i = 0;
        let result = '';
        const flush = (cls) => {
            if (result) {
                parts.push(<span key={parts.length} className={cls}>{result}</span>);
                result = '';
            }
        };
        for (let j = 0; j < line.length;) {
            /* strings */
            if (line[j] === "'" || line[j] === '"') {
                flush("text-zinc-300");
                const q = line[j];
                let s = q;
                j++;
                while (j < line.length && line[j] !== q) {
                    if (line[j] === '\\') { s += line[j]; j++; }
                    s += line[j]; j++;
                }
                if (j < line.length) { s += line[j]; j++; }
                parts.push(<span key={parts.length} className="text-emerald-300">{s}</span>);
                continue;
            }
            /* words */
            const wordMatch = line.slice(j).match(/^[a-zA-Z_]\w*/);
            if (wordMatch) {
                flush("text-zinc-300");
                const w = wordMatch[0];
                if (pyKeywords.has(w)) {
                    parts.push(<span key={parts.length} className="text-purple-400">{w}</span>);
                } else if (j > 0 && line.slice(0, j).match(/(def|class)\s+$/)) {
                    parts.push(<span key={parts.length} className="text-blue-400">{w}</span>);
                } else {
                    parts.push(<span key={parts.length} className="text-zinc-300">{w}</span>);
                }
                j += w.length;
                continue;
            }
            result += line[j];
            j++;
        }
        flush("text-zinc-300");
        return parts;
    }

    function highlightJSX(line) {
        const parts = [];
        /* JSX tags */
        const tagPattern = /(<\/?)([\w.]+)([^>]*?)(\/?>)/g;
        let lastIdx = 0;
        let match;
        const raw = line;

        /* inline comment */
        if (line.trimStart().startsWith('//')) {
            parts.push(<span key="c" className="text-zinc-500 italic">{line}</span>);
            return parts;
        }

        /* simple token walk */
        for (let j = 0; j < line.length;) {
            /* strings */
            if (line[j] === "'" || line[j] === '"' || line[j] === '`') {
                const q = line[j];
                let s = q;
                j++;
                while (j < line.length && line[j] !== q) {
                    if (line[j] === '\\') { s += line[j]; j++; }
                    s += line[j]; j++;
                }
                if (j < line.length) { s += line[j]; j++; }
                parts.push(<span key={parts.length} className="text-emerald-300">{s}</span>);
                continue;
            }
            /* JSX angle brackets and tag names */
            if (line[j] === '<') {
                let tag = '<';
                j++;
                if (j < line.length && line[j] === '/') { tag += '/'; j++; }
                parts.push(<span key={parts.length} className="text-zinc-500">{tag}</span>);
                /* tag name */
                const nameMatch = line.slice(j).match(/^[\w.]+/);
                if (nameMatch) {
                    const isComponent = nameMatch[0][0] === nameMatch[0][0].toUpperCase();
                    parts.push(<span key={parts.length} className={isComponent ? "text-cyan-400" : "text-red-400"}>{nameMatch[0]}</span>);
                    j += nameMatch[0].length;
                }
                continue;
            }
            if (line[j] === '>' || (line[j] === '/' && j + 1 < line.length && line[j + 1] === '>')) {
                const closing = line[j] === '/' ? '/>' : '>';
                parts.push(<span key={parts.length} className="text-zinc-500">{closing}</span>);
                j += closing.length;
                continue;
            }
            /* keywords */
            const wordMatch = line.slice(j).match(/^[a-zA-Z_$]\w*/);
            if (wordMatch) {
                const w = wordMatch[0];
                if (jsKeywords.has(w)) {
                    parts.push(<span key={parts.length} className="text-purple-400">{w}</span>);
                } else if (w === 'className') {
                    parts.push(<span key={parts.length} className="text-yellow-300">{w}</span>);
                } else if (j > 0 && line[j - 1] === '<') {
                    parts.push(<span key={parts.length} className="text-cyan-400">{w}</span>);
                } else {
                    parts.push(<span key={parts.length} className="text-zinc-300">{w}</span>);
                }
                j += w.length;
                continue;
            }
            /* braces in JSX */
            if (line[j] === '{' || line[j] === '}') {
                parts.push(<span key={parts.length} className="text-yellow-400">{line[j]}</span>);
                j++;
                continue;
            }
            parts.push(<span key={parts.length} className="text-zinc-300">{line[j]}</span>);
            j++;
        }
        return parts;
    }

    const rendered = lines.map((line, i) => {
        /* switch mode at the blank line before JS imports */
        if (mode === 'python' && line.match(/^import React/)) {
            mode = 'jsx';
        }
        const highlighted = mode === 'python' ? highlightPython(line) : highlightJSX(line);
        return <React.Fragment key={i}>{highlighted}{'\n'}</React.Fragment>;
    });

    return <>{rendered}</>;
}

function CodeShowcase() {
    const { theme } = useTheme();
    return (
        <section id="code" className="relative px-6 py-24">
            <div className="mx-auto max-w-6xl">
                <div className="text-center mb-16">
                    <p className="text-sm font-semibold uppercase tracking-widest text-emerald-400">
                        One file. Full stack.
                    </p>
                    <h2 className="mt-3 text-3xl font-bold tracking-tight sm:text-4xl">
                        Server + Client in a single <code className="text-emerald-400">.pyx</code>
                    </h2>
                    <p className={`mx-auto mt-4 max-w-xl ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>
                        Your async Python loader and React component live together. No API wiring, no boilerplate.
                    </p>
                </div>

                <div className="relative mx-auto max-w-3xl">
                    <div className="absolute -inset-4 rounded-2xl bg-gradient-to-r from-emerald-500/10 via-cyan-500/10 to-blue-500/10 blur-xl" />
                    <div className={`relative rounded-xl border overflow-hidden ${
                        theme === 'dark' ? 'border-white/10 bg-[#111113]' : 'border-zinc-200 bg-[#1a1a2e]'
                    }`}>
                        <div className={`flex items-center gap-2 border-b px-4 py-3 ${
                            theme === 'dark' ? 'border-white/5' : 'border-zinc-700/30'
                        }`}>
                            <div className="flex gap-1.5">
                                <span className="h-3 w-3 rounded-full bg-red-500/60" />
                                <span className="h-3 w-3 rounded-full bg-yellow-500/60" />
                                <span className="h-3 w-3 rounded-full bg-green-500/60" />
                            </div>
                            <span className="ml-2 text-xs text-zinc-500 font-mono">pages/dashboard.pyx</span>
                        </div>
                        <div className="relative">
                            <CopyButton text={DEMO_CODE} />
                            <pre className="overflow-x-auto p-4 sm:p-6 text-xs sm:text-sm leading-relaxed font-mono">
                                <code><HighlightedCode code={DEMO_CODE} /></code>
                            </pre>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    );
}

/* ── features ─────────────────────────────────────────────── */

const FEATURES = [
    {
        title: "File-based routing",
        desc: "Drop .pyx files into pages/ and get routes instantly. Dynamic segments, catch-all routes, layouts, and route groups.",
        icon: "M3.75 9.776c.112-.017.227-.026.344-.026h15.812c.117 0 .232.009.344.026m-16.5 0a2.25 2.25 0 00-1.883 2.542l.857 6a2.25 2.25 0 002.227 1.932H19.05a2.25 2.25 0 002.227-1.932l.857-6a2.25 2.25 0 00-1.883-2.542m-16.5 0V6A2.25 2.25 0 016 3.75h3.879a1.5 1.5 0 011.06.44l2.122 2.12a1.5 1.5 0 001.06.44H18A2.25 2.25 0 0120.25 9v.776",
    },
    {
        title: "Async server loaders",
        desc: "Fetch data with @server functions on Starlette. Return a dict and it becomes React props automatically.",
        icon: "M5.25 14.25h13.5m-13.5 0a3 3 0 01-3-3m3 3a3 3 0 100 6h13.5a3 3 0 100-6m-16.5-3a3 3 0 013-3h13.5a3 3 0 013 3m-19.5 0a4.5 4.5 0 01.9-2.7L5.737 5.1a3.375 3.375 0 012.7-1.35h7.126c1.062 0 2.062.5 2.7 1.35l2.587 3.45a4.5 4.5 0 01.9 2.7m0 0a3 3 0 01-3 3m0 3h.008v.008h-.008v-.008zm0-6h.008v.008h-.008v-.008zm-3 6h.008v.008h-.008v-.008zm0-6h.008v.008h-.008v-.008z",
    },
    {
        title: "Server-side rendering",
        desc: "Every page is server-rendered then hydrated. Fast first paint, great SEO, smooth interactivity.",
        icon: "M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.455 2.456L21.75 6l-1.036.259a3.375 3.375 0 00-2.455 2.456zM16.894 20.567L16.5 21.75l-.394-1.183a2.25 2.25 0 00-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 001.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 001.423 1.423l1.183.394-1.183.394a2.25 2.25 0 00-1.423 1.423z",
    },
    {
        title: "Vite-powered dev",
        desc: "Instant hot module reloading via Vite. Tailwind CSS built in. Sub-second feedback loop.",
        icon: "M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z",
    },
    {
        title: "Server actions",
        desc: "Mutate data with @action decorators. Call from React via useAction() \u2014 forms that work with or without JS.",
        icon: "M7.5 21L3 16.5m0 0L7.5 12M3 16.5h13.5m0-13.5L21 7.5m0 0L16.5 12M21 7.5H7.5",
    },
    {
        title: "Production ready",
        desc: "CSRF protection, CORS, middleware, and hashed asset builds. Deploy anywhere Python runs.",
        icon: "M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z",
    },
];

function FeatureIcon({ d }) {
    return (
        <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="1.5">
            <path strokeLinecap="round" strokeLinejoin="round" d={d} />
        </svg>
    );
}

function Features() {
    const { theme } = useTheme();
    return (
        <section id="features" className="relative px-6 py-24">
            <GradientOrb className="h-[500px] w-[500px] top-0 right-0 bg-emerald-600" />
            <div className="relative z-10 mx-auto max-w-6xl">
                <div className="text-center mb-16">
                    <p className="text-sm font-semibold uppercase tracking-widest text-emerald-400">Features</p>
                    <h2 className="mt-3 text-3xl font-bold tracking-tight sm:text-4xl">
                        Everything you need to ship
                    </h2>
                    <p className={`mx-auto mt-4 max-w-xl ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>
                        Pyxle gives you the full stack in one cohesive toolkit. No glue code needed.
                    </p>
                </div>
                <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                    {FEATURES.map((f) => (
                        <div
                            key={f.title}
                            className={`group rounded-xl border p-6 transition ${
                                theme === 'dark'
                                    ? 'border-white/5 bg-white/[0.02] hover:border-emerald-500/20 hover:bg-emerald-500/[0.03]'
                                    : 'border-zinc-200 bg-white hover:border-emerald-500/30 hover:bg-emerald-50/50'
                            }`}
                        >
                            <div className={`mb-4 inline-flex rounded-lg border p-2.5 text-emerald-400 transition ${
                                theme === 'dark'
                                    ? 'border-white/10 bg-white/5 group-hover:border-emerald-500/30 group-hover:bg-emerald-500/10'
                                    : 'border-zinc-200 bg-zinc-50 group-hover:border-emerald-500/30 group-hover:bg-emerald-50'
                            }`}>
                                <FeatureIcon d={f.icon} />
                            </div>
                            <h3 className="text-lg font-semibold">{f.title}</h3>
                            <p className={`mt-2 text-sm leading-relaxed ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>{f.desc}</p>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
}

/* ── how it works ─────────────────────────────────────────── */

const STEPS = [
    { num: "01", title: "Write a .pyx file", desc: "Python server logic on top, React component below. One file per route." },
    { num: "02", title: "Pyxle compiles it", desc: "The compiler splits your code into a server module (.py) and a client component (.jsx)." },
    { num: "03", title: "SSR + Hydration", desc: "Starlette runs your loader, Node.js renders React to HTML, then the client hydrates." },
];

function HowItWorks() {
    const { theme } = useTheme();
    return (
        <section className="relative px-6 py-24">
            <div className="mx-auto max-w-6xl">
                <div className="text-center mb-16">
                    <p className="text-sm font-semibold uppercase tracking-widest text-emerald-400">How it works</p>
                    <h2 className="mt-3 text-3xl font-bold tracking-tight sm:text-4xl">
                        Three steps to production
                    </h2>
                </div>
                <div className="grid gap-8 sm:grid-cols-3">
                    {STEPS.map((s) => (
                        <div key={s.num} className="relative">
                            <span className={`text-6xl font-bold ${theme === 'dark' ? 'text-white/[0.04]' : 'text-zinc-900/[0.06]'}`}>{s.num}</span>
                            <h3 className="mt-2 text-lg font-semibold">{s.title}</h3>
                            <p className={`mt-2 text-sm leading-relaxed ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>{s.desc}</p>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
}

/* ── get started ──────────────────────────────────────────── */

const INSTALL_STEPS = [
    { label: "Install Pyxle", cmd: "pip install git+https://github.com/shivamsn97/pyxle.git" },
    { label: "Create a project", cmd: "pyxle init my-app && cd my-app" },
    { label: "Install dependencies", cmd: "pyxle install" },
    { label: "Start building", cmd: "pyxle dev" },
];

function GetStarted() {
    const { theme } = useTheme();
    return (
        <section id="get-started" className="relative px-6 py-24">
            <GradientOrb className="h-[500px] w-[500px] bottom-0 left-1/2 -translate-x-1/2 bg-blue-600" />
            <div className="relative z-10 mx-auto max-w-3xl text-center">
                <p className="text-sm font-semibold uppercase tracking-widest text-emerald-400">Get started</p>
                <h2 className="mt-3 text-3xl font-bold tracking-tight sm:text-4xl">
                    Up and running in seconds
                </h2>
                <p className={`mx-auto mt-4 max-w-xl ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>
                    Install from git, scaffold a project, and start the dev server.
                </p>
                <div className="mt-10 space-y-4 text-left">
                    {INSTALL_STEPS.map((step) => (
                        <div key={step.cmd} className={`relative rounded-lg border p-4 ${
                            theme === 'dark' ? 'border-white/10 bg-[#111113]' : 'border-zinc-200 bg-[#1a1a2e]'
                        }`}>
                            <CopyButton text={step.cmd} />
                            <p className="mb-1 text-xs font-medium text-zinc-500 uppercase tracking-wider">
                                {step.label}
                            </p>
                            <code className="text-sm font-mono text-emerald-400 break-all">$ {step.cmd}</code>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
}

/* ── newsletter ────────────────────────────────────────────── */

function Newsletter() {
    const { theme } = useTheme();
    const subscribe = useAction("subscribe_newsletter");
    const [email, setEmail] = useState('');
    const [status, setStatus] = useState(null); // 'success' | 'error'
    const [message, setMessage] = useState('');

    const handleSubmit = useCallback(async (e) => {
        e.preventDefault();
        setStatus(null);
        setMessage('');

        const result = await subscribe({ email });
        if (result.ok) {
            setStatus('success');
            setMessage(result.message);
            setEmail('');
        } else {
            setStatus('error');
            setMessage(result.error);
        }
    }, [email, subscribe]);

    return (
        <section className="relative px-6 py-24">
            <div className="mx-auto max-w-2xl text-center">
                <div className="inline-flex items-center gap-2 mb-6">
                    <span className="relative flex h-2 w-2">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
                        <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500" />
                    </span>
                    <span className={`text-sm font-medium ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-500'}`}>
                        Actively shipping
                    </span>
                </div>
                <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
                    Stay in the loop
                </h2>
                <p className={`mt-4 text-lg leading-relaxed ${theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'}`}>
                    Get notified about new releases, features, and the occasional deep dive into building with Pyxle.
                </p>

                <form onSubmit={handleSubmit} className="mt-8 flex flex-col sm:flex-row items-center gap-3 justify-center">
                    <div className="relative w-full sm:w-auto sm:flex-1 max-w-sm">
                        <input
                            type="email"
                            value={email}
                            onChange={(e) => { setEmail(e.target.value); setStatus(null); }}
                            placeholder="you@example.com"
                            required
                            className={`w-full rounded-lg border px-4 py-3 text-sm outline-none transition placeholder:text-zinc-500 focus:ring-2 focus:ring-emerald-500/40 ${
                                theme === 'dark'
                                    ? 'border-white/10 bg-white/5 text-white'
                                    : 'border-zinc-300 bg-white text-zinc-900'
                            }`}
                        />
                    </div>
                    <button
                        type="submit"
                        disabled={subscribe.pending}
                        className={`shrink-0 rounded-lg px-6 py-3 text-sm font-semibold transition ${
                            subscribe.pending
                                ? 'opacity-60 cursor-not-allowed'
                                : 'hover:opacity-90'
                        } bg-emerald-500 text-white`}
                    >
                        {subscribe.pending ? (
                            <span className="flex items-center gap-2">
                                <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                                </svg>
                                Subscribing...
                            </span>
                        ) : 'Subscribe'}
                    </button>
                </form>

                {status && (
                    <p className={`mt-4 text-sm font-medium transition-opacity ${
                        status === 'success' ? 'text-emerald-400' : 'text-red-400'
                    }`}>
                        {message}
                    </p>
                )}

                <p className={`mt-6 text-xs ${theme === 'dark' ? 'text-zinc-600' : 'text-zinc-400'}`}>
                    No spam, ever. Unsubscribe anytime.
                </p>
            </div>
        </section>
    );
}

/* ── footer ───────────────────────────────────────────────── */

function Footer() {
    const { theme } = useTheme();
    return (
        <footer className={`border-t px-6 py-12 ${theme === 'dark' ? 'border-white/5' : 'border-zinc-200'}`}>
            <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-6 sm:flex-row">
                <div className="flex items-center gap-3">
                    <img src="/branding/pyxle-mark.svg" alt="Pyxle" className="h-6 w-6 opacity-50" />
                    <span className={`text-sm ${theme === 'dark' ? 'text-zinc-500' : 'text-zinc-400'}`}>Pyxle Framework</span>
                </div>
                <div className="flex items-center gap-6">
                    <a href="https://docs.pyxle.dev" target="_blank" rel="noreferrer"
                       className={`text-sm transition ${theme === 'dark' ? 'text-zinc-500 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'}`}>
                        Docs
                    </a>
                    <a href="https://github.com/shivamsn97/pyxle" target="_blank" rel="noreferrer"
                       className={`text-sm transition ${theme === 'dark' ? 'text-zinc-500 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'}`}>
                        GitHub
                    </a>
                    <a href="https://github.com/shivamsn97/pyxle/issues" target="_blank" rel="noreferrer"
                       className={`text-sm transition ${theme === 'dark' ? 'text-zinc-500 hover:text-white' : 'text-zinc-400 hover:text-zinc-900'}`}>
                        Issues
                    </a>
                </div>
            </div>
        </footer>
    );
}

/* ── page ─────────────────────────────────────────────────── */

export const slots = {};
export const createSlots = () => slots;

export default function Page({ data }) {
    const { version } = data;
    return (
        <>
            <Nav version={version} />
            <Hero />
            <CodeShowcase />
            <Features />
            <HowItWorks />
            <GetStarted />
            <Newsletter />
            <Footer />
        </>
    );
}
