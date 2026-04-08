import React from 'react';
import { Link, Head } from 'pyxle/client';
import { useTheme } from './layout.jsx';
import { ThemeToggle } from './components/theme-toggle.jsx';
import NotFoundContent from './components/not-found-content.jsx';

export const slots = {};
export const createSlots = () => slots;

export default function NotFoundPage() {
    const { theme } = useTheme();

    return (
        <div className="min-h-screen flex flex-col">
            <Head>
                <title>404 - Page Not Found | Pyxle</title>
                <meta name="description" content="The page you are looking for does not exist." />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <link rel="icon" href="/favicon.svg" type="image/svg+xml" />
                <link rel="preconnect" href="https://fonts.googleapis.com" />
                <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
                <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet" />
            </Head>
            <nav className={`relative z-20 border-b backdrop-blur-xl ${
                theme === 'dark' ? 'bg-[#0a0a0b]/80 border-white/5' : 'bg-white/80 border-zinc-200'
            }`}>
                <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
                    <Link href="/" className="flex items-center gap-3">
                        <img src="/branding/pyxle-mark.svg" alt="Pyxle" className="h-7 w-7" />
                        <span className="text-lg font-semibold tracking-tight">Pyxle</span>
                    </Link>
                    <div className="flex items-center gap-2 sm:gap-4">
                        <Link href="/docs" className={`hidden sm:block text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>Docs</Link>
                        <a href="https://github.com/pyxle-framework/pyxle" target="_blank" rel="noreferrer"
                           className={`hidden sm:block text-sm transition ${theme === 'dark' ? 'text-zinc-400 hover:text-white' : 'text-zinc-600 hover:text-zinc-900'}`}>GitHub</a>
                        <a
                            href="https://github.com/pyxle-framework/pyxle-dev/blob/main/pages/not-found.pyx"
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

            <NotFoundContent
                sourceUrl="https://github.com/pyxle-framework/pyxle-dev/blob/main/pages/components/not-found-content.jsx"
            />
        </div>
    );
}
