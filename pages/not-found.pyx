HEAD = [
    '<title>404 - Page Not Found | Pyxle</title>',
    '<meta name="description" content="The page you are looking for does not exist." />',
    '<meta name="viewport" content="width=device-width, initial-scale=1" />',
    '<link rel="icon" href="/favicon.ico" />',
    '<link rel="preconnect" href="https://fonts.googleapis.com" />',
    '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />',
    '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap" rel="stylesheet" />',
    '<link rel="stylesheet" href="/styles/tailwind.css" />',
]


# --- client ---
import React, { useState, useEffect, useRef } from 'react';
import { useTheme } from './layout.jsx';

const PHRASES = [
    "You've wandered into the void.",
    "This page is on a coffee break.",
    "404: File not found. Meaning not found either.",
    "Looks like this route took a wrong turn.",
    "The page you seek does not exist. Yet.",
    "Nothing here but cosmic dust.",
    "This page has been abducted by aliens.",
    "Error 404: Reality not found.",
    "You've reached the edge of the internet.",
    "This page went out for milk and never came back.",
    "The bits are all there. Just not in the right order.",
    "Lost? Even GPS can't help you here.",
    "This page is playing hide and seek. It's winning.",
    "404: The page has left the building.",
    "Congratulations, you found nothing.",
    "This page exists in a parallel universe.",
    "The server looked everywhere. Twice.",
    "Page not found. But you found this, so that's something.",
    "This URL is a dead end. Like a cul-de-sac, but digital.",
    "Somewhere, a developer forgot to create this page.",
];

function GlitchText({ text }) {
    const { theme } = useTheme();
    const [glitchIndex, setGlitchIndex] = useState(-1);

    useEffect(() => {
        const interval = setInterval(() => {
            setGlitchIndex(Math.floor(Math.random() * text.length));
            setTimeout(() => setGlitchIndex(-1), 100);
        }, 3000);
        return () => clearInterval(interval);
    }, [text]);

    return (
        <span className="inline-block">
            {text.split('').map((char, i) => (
                <span
                    key={i}
                    className={i === glitchIndex ? 'text-emerald-400 inline-block translate-y-[1px]' : ''}
                >
                    {i === glitchIndex ? String.fromCharCode(char.charCodeAt(0) + Math.floor(Math.random() * 3)) : char}
                </span>
            ))}
        </span>
    );
}

function FloatingParticles() {
    const canvasRef = useRef(null);
    const { theme } = useTheme();

    useEffect(() => {
        const canvas = canvasRef.current;
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        let w, h, animId;

        const particles = Array.from({ length: 40 }, () => ({
            x: Math.random(),
            y: Math.random(),
            vx: (Math.random() - 0.5) * 0.0003,
            vy: (Math.random() - 0.5) * 0.0003,
            size: Math.random() * 2 + 0.5,
            opacity: Math.random() * 0.3 + 0.1,
        }));

        function resize() {
            const dpr = Math.min(window.devicePixelRatio || 1, 2);
            w = canvas.offsetWidth;
            h = canvas.offsetHeight;
            canvas.width = w * dpr;
            canvas.height = h * dpr;
            ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        }

        function draw() {
            ctx.clearRect(0, 0, w, h);
            const isDark = theme === 'dark';

            for (const p of particles) {
                p.x += p.vx;
                p.y += p.vy;
                if (p.x < 0 || p.x > 1) p.vx *= -1;
                if (p.y < 0 || p.y > 1) p.vy *= -1;

                ctx.beginPath();
                ctx.arc(p.x * w, p.y * h, p.size, 0, Math.PI * 2);
                ctx.fillStyle = isDark
                    ? `rgba(16, 185, 129, ${p.opacity})`
                    : `rgba(16, 185, 129, ${p.opacity * 1.5})`;
                ctx.fill();
            }

            /* Draw faint connections between nearby particles */
            for (let i = 0; i < particles.length; i++) {
                for (let j = i + 1; j < particles.length; j++) {
                    const dx = (particles[i].x - particles[j].x) * w;
                    const dy = (particles[i].y - particles[j].y) * h;
                    const dist = Math.sqrt(dx * dx + dy * dy);
                    if (dist < 120) {
                        ctx.beginPath();
                        ctx.moveTo(particles[i].x * w, particles[i].y * h);
                        ctx.lineTo(particles[j].x * w, particles[j].y * h);
                        const alpha = (1 - dist / 120) * 0.08;
                        ctx.strokeStyle = isDark
                            ? `rgba(16, 185, 129, ${alpha})`
                            : `rgba(16, 185, 129, ${alpha * 2})`;
                        ctx.lineWidth = 0.5;
                        ctx.stroke();
                    }
                }
            }

            animId = requestAnimationFrame(draw);
        }

        resize();
        animId = requestAnimationFrame(draw);
        window.addEventListener('resize', resize, { passive: true });

        return () => {
            cancelAnimationFrame(animId);
            window.removeEventListener('resize', resize);
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

export const slots = {};
export const createSlots = () => slots;

export default function NotFoundPage() {
    const { theme } = useTheme();
    const [phrase, setPhrase] = useState('');
    const [counter, setCounter] = useState(0);

    useEffect(() => {
        setPhrase(PHRASES[Math.floor(Math.random() * PHRASES.length)]);
    }, []);

    const shufflePhrase = () => {
        setPhrase(PHRASES[Math.floor(Math.random() * PHRASES.length)]);
        setCounter(c => c + 1);
    };

    return (
        <div className="relative min-h-screen flex flex-col items-center justify-center px-6 overflow-hidden">
            <FloatingParticles />

            <div className="relative z-10 max-w-2xl text-center">
                <div className="mb-8">
                    <span className="font-mono text-8xl sm:text-9xl font-bold bg-gradient-to-b from-emerald-400 to-emerald-400/20 bg-clip-text text-transparent select-none">
                        <GlitchText text="404" />
                    </span>
                </div>

                <h1 className="text-2xl sm:text-3xl font-bold tracking-tight mb-4">
                    Page not found
                </h1>

                <p className={`text-base sm:text-lg mb-2 min-h-[2em] transition-all duration-300 ${
                    theme === 'dark' ? 'text-zinc-400' : 'text-zinc-600'
                }`}>
                    {phrase}
                </p>

                <button
                    onClick={shufflePhrase}
                    className={`text-xs mb-8 transition ${
                        theme === 'dark'
                            ? 'text-zinc-600 hover:text-zinc-400'
                            : 'text-zinc-400 hover:text-zinc-600'
                    }`}
                >
                    {counter > 4 ? "You really like clicking this, huh?" : "Click for another one"}
                </button>

                <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mt-4">
                    <a
                        href="/"
                        className={`group inline-flex items-center gap-2 rounded-xl px-6 py-3 text-sm font-semibold transition ${
                            theme === 'dark'
                                ? 'bg-white text-black hover:bg-zinc-200'
                                : 'bg-zinc-900 text-white hover:bg-zinc-700'
                        }`}
                    >
                        <svg className="h-4 w-4 transition group-hover:-translate-x-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M11 17l-5-5m0 0l5-5m-5 5h12" />
                        </svg>
                        Back to home
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
                        Report an issue
                    </a>
                </div>

                <div className={`mt-16 font-mono text-xs space-y-1 ${
                    theme === 'dark' ? 'text-zinc-700' : 'text-zinc-300'
                }`}>
                    <p>GET {typeof window !== 'undefined' ? window.location.pathname : '/unknown'} HTTP/1.1</p>
                    <p>Status: 404 Not Found</p>
                    <p>X-Powered-By: Pyxle</p>
                </div>
            </div>
        </div>
    );
}
