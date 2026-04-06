/**
 * HeroVisual — code editor + interactive browser preview, side by side,
 * with 3D tilt, gentle floating, mouse parallax, and a live click counter.
 *
 * The example demonstrates Pyxle's killer feature: a `@server` loader
 * that pulls real persisted state out of the database and an `@action`
 * that mutates it, both wired to a React component with no API
 * boilerplate.
 *
 * The container is `pointer-events: none` so the underlying aurora
 * background canvas keeps receiving cursor events. The "Click me"
 * button inside the browser preview opts back in via CSS so users
 * can actually click it.
 *
 * The structure of the rendered preview is kept faithful to the JSX
 * shown in the editor card so the two halves describe the same app.
 *
 * Used by `Hero` in `pages/index.pyx`.
 */

import React, { useEffect, useRef, useState } from 'react';
import { useAction } from 'pyxle/client';
import { useTheme } from '../layout.jsx';
import { tokenizeBlock } from './code-highlighter.jsx';

/* ── sample code shown inside the editor card ─────────────────
 *
 * The point of this example is that `clicks.get()` and `clicks.bump()`
 * are real database calls — they only run on the server. With Pyxle,
 * the React component on the client just calls `useAction("click")`
 * and the result flows back as plain JSON. Zero glue code, zero
 * fetch, zero handcrafted REST endpoint.
 */
const SAMPLE_CODE = `from pyxle import server, action
from db import get_home_clicks, increment_home_clicks


@server
async def load_home(req):
    return {"clicks": get_home_clicks()}


@action
async def click_home(req):
    return {"clicks": increment_home_clicks()}


import { useState } from 'react';
import { useAction } from 'pyxle/client';

export default function Clicker({ data }) {
    const [n, setN] = useState(data.clicks);
    const tap = useAction("click_home");

    return (
        <div className="clicker">
            <p>Global clicks worldwide</p>
            <h1>{n.toLocaleString()}</h1>
            <button onClick={async () =>
                setN((await tap()).clicks)
            }>
                Click me
            </button>
        </div>
    );
}`;

/* Tokenize once at module load, not on every render. tokenizeBlock walks
   every character of the source — we don't want it firing each time the
   counter ticks. */
const SAMPLE_TOKENS = tokenizeBlock(SAMPLE_CODE, 'pyx');

/* ── parallax (refs only — never causes re-renders) ──────── */

function useMouseParallax(containerRef, codeRef, browserRef) {
    useEffect(() => {
        const container = containerRef.current;
        if (!container || typeof window === 'undefined') return;

        const desktop = window.matchMedia('(min-width: 1024px)');
        const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
        if (!desktop.matches || reduced.matches) return;

        const target = { x: 0, y: 0 };
        const current = { x: 0, y: 0 };
        let rafId = null;
        let active = true;

        function onMove(e) {
            const rect = container.getBoundingClientRect();
            const cx = rect.left + rect.width / 2;
            const cy = rect.top + rect.height / 2;
            target.x = Math.max(-1, Math.min(1, (e.clientX - cx) / (rect.width * 0.75)));
            target.y = Math.max(-1, Math.min(1, (e.clientY - cy) / (rect.height * 0.75)));
        }

        function onLeave() {
            target.x = 0;
            target.y = 0;
        }

        function tick() {
            current.x += (target.x - current.x) * 0.08;
            current.y += (target.y - current.y) * 0.08;

            const rx = current.x * 6;   /* +/- 6deg yaw */
            const ry = -current.y * 4;  /* +/- 4deg pitch */

            if (codeRef.current) {
                codeRef.current.style.setProperty('--hv-tilt-x', rx + 'deg');
                codeRef.current.style.setProperty('--hv-tilt-y', ry + 'deg');
            }
            if (browserRef.current) {
                browserRef.current.style.setProperty('--hv-tilt-x', rx + 'deg');
                browserRef.current.style.setProperty('--hv-tilt-y', ry + 'deg');
            }

            if (active) rafId = requestAnimationFrame(tick);
        }

        window.addEventListener('mousemove', onMove, { passive: true });
        window.addEventListener('mouseleave', onLeave);
        rafId = requestAnimationFrame(tick);

        return () => {
            active = false;
            if (rafId) cancelAnimationFrame(rafId);
            window.removeEventListener('mousemove', onMove);
            window.removeEventListener('mouseleave', onLeave);
        };
    }, [containerRef, codeRef, browserRef]);
}

/* ── code editor card body — pure render, never changes ──── */

const TokenizedCode = React.memo(function TokenizedCode() {
    return SAMPLE_TOKENS.map((lineTokens, i) => (
        <React.Fragment key={i}>
            {lineTokens.map((tok, j) => (
                <span key={j} className={tok.cls}>{tok.text}</span>
            ))}
            {'\n'}
        </React.Fragment>
    ));
});

/* ── browser preview body — owns its own counter state ────
 *
 * Lives in its own component so each click that mutates the count only
 * re-renders this small subtree, not the whole HeroVisual (which would
 * also force the syntax-highlighted code editor to re-render). The DOM
 * structure mirrors the JSX in SAMPLE_CODE.
 *
 * The count is sourced from the @server load_home loader (passed in as
 * `initialClicks`) and each click fires the real @action click_home,
 * which atomically increments a persistent SQLite counter. Every
 * visitor sees the same global total and contributes to it.
 */

function ClickerPreview({ initialClicks = 0 }) {
    const [n, setN] = useState(initialClicks);
    const inFlightRef = useRef(false);
    const tap = useAction('click_home');

    const handleClick = async () => {
        /* Optimistic update so the click feels instant; the server reply
           re-syncs against the authoritative DB total. */
        if (inFlightRef.current) return;
        inFlightRef.current = true;
        const optimistic = n + 1;
        setN(optimistic);
        try {
            const result = await tap();
            if (result && typeof result.clicks === 'number') {
                setN(result.clicks);
            }
        } catch (e) {
            /* Roll back the optimistic bump on failure (e.g. rate limit) */
            setN(v => Math.max(0, v - 1));
        } finally {
            inFlightRef.current = false;
        }
    };

    return (
        <div className="hv-clicker clicker">
            <p>Global clicks worldwide</p>
            {/* The `key` re-mounts the h1 on each value change so the pop
                animation replays. */}
            <h1 key={n}>{n.toLocaleString()}</h1>
            <button type="button" onClick={handleClick} tabIndex={-1}>
                Click me
            </button>
        </div>
    );
}

/* ── component ────────────────────────────────────────────── */

export function HeroVisual({ initialClicks = 0 }) {
    const { theme } = useTheme();
    const containerRef = useRef(null);
    const codeRef = useRef(null);
    const browserRef = useRef(null);
    useMouseParallax(containerRef, codeRef, browserRef);

    return (
        <div
            ref={containerRef}
            className="relative mx-auto mt-12 w-full max-w-5xl hv-stage"
            style={{ pointerEvents: 'none' }}
        >
            {/* Soft gradient glow underneath both windows */}
            <div className="hv-glow" aria-hidden="true" />

            {/* Layout swap:
                  • On mobile: a vertical flex stack so the cards sit one
                    above the other at full width.
                  • On sm+:    an aspect-ratio "stage" where the children
                    are absolutely positioned to overlap. */}
            <div className="relative flex flex-col gap-5 sm:block sm:pb-[52%]">

                {/* ── Code editor card ── */}
                <div className="hv-float-a relative w-full sm:absolute sm:left-0 sm:top-[2%] sm:w-[58%] sm:z-20" aria-hidden="true">
                    <div ref={codeRef} className="hv-card hv-card-code">
                        <div className={`rounded-xl border overflow-hidden shadow-2xl text-left ${
                            theme === 'dark'
                                ? 'border-white/10 bg-[#0c0c10] shadow-black/70 ring-1 ring-emerald-500/10'
                                : 'border-zinc-300 bg-[#0c0c14] shadow-zinc-500/40 ring-1 ring-emerald-500/15'
                        }`}>
                            {/* Title bar */}
                            <div className="flex items-center gap-2 border-b border-white/5 bg-white/[0.02] px-4 py-2.5">
                                <div className="flex gap-1.5">
                                    <span className="h-2.5 w-2.5 rounded-full bg-red-500/80" />
                                    <span className="h-2.5 w-2.5 rounded-full bg-yellow-500/80" />
                                    <span className="h-2.5 w-2.5 rounded-full bg-green-500/80" />
                                </div>
                                <span className="ml-2 text-[10px] sm:text-xs text-zinc-400 font-mono">pages/index.pyx</span>
                                <span className="ml-auto inline-flex items-center gap-1 rounded-md border border-emerald-500/20 bg-emerald-500/10 px-1.5 py-0.5 text-[8px] sm:text-[9px] font-semibold uppercase tracking-wider text-emerald-400">
                                    .pyx
                                </span>
                            </div>
                            {/* Code body — horizontally scrollable on small screens
                                so long lines aren't clipped. */}
                            <pre className="p-4 sm:p-5 text-[10px] sm:text-[9px] md:text-[10px] leading-[1.6] font-mono overflow-x-auto whitespace-pre">
                                <code><TokenizedCode /></code>
                            </pre>
                        </div>
                    </div>
                </div>

                {/* ── Browser card ── */}
                <div className="hv-float-b relative w-full sm:absolute sm:right-0 sm:top-[26%] sm:w-[58%] sm:z-10">
                    <div ref={browserRef} className="hv-card hv-card-browser">
                        <div className="rounded-xl border border-zinc-200 bg-white overflow-hidden shadow-2xl shadow-black/50 ring-1 ring-cyan-500/15">
                            {/* Browser chrome */}
                            <div className="flex items-center gap-2 border-b border-zinc-200 px-3 py-2 bg-zinc-50">
                                <div className="flex gap-1.5">
                                    <span className="h-2 w-2 rounded-full bg-red-400" />
                                    <span className="h-2 w-2 rounded-full bg-yellow-400" />
                                    <span className="h-2 w-2 rounded-full bg-green-400" />
                                </div>
                                <div className="ml-2 flex gap-0.5 text-zinc-400">
                                    <svg className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
                                        <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
                                    </svg>
                                    <svg className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
                                        <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                                    </svg>
                                </div>
                                {/* Address bar */}
                                <div className="ml-1 flex flex-1 items-center gap-1.5 rounded-md bg-white border border-zinc-200 px-2 py-0.5 text-[9px] sm:text-[10px] text-zinc-500 font-mono truncate">
                                    <svg className="h-2.5 w-2.5 text-emerald-500 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                                        <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd" />
                                    </svg>
                                    pyxle.dev
                                </div>
                            </div>
                            {/* Clicker app — DOM structure matches the JSX in SAMPLE_CODE */}
                            <ClickerPreview initialClicks={initialClicks} />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default HeroVisual;
