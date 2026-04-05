HEAD = [
    '<title>404 - Page Not Found | Pyxle</title>',
    '<meta name="description" content="The page you are looking for does not exist." />',
    '<meta name="viewport" content="width=device-width, initial-scale=1" />',
    '<link rel="icon" href="/favicon.ico" />',
    '<link rel="preconnect" href="https://fonts.googleapis.com" />',
    '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />',
    '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap" rel="stylesheet" />',
    '<link rel="stylesheet" href="/styles/tailwind.css?v=2" />',
]


# --- client ---
import React from 'react';
import { Link } from 'pyxle/client';
import { useTheme } from './layout.jsx';
import { ThemeToggle } from './components/theme-toggle.jsx';
import NotFoundContent from './components/not-found-content.jsx';

export const slots = {};
export const createSlots = () => slots;

export default function NotFoundPage() {
    const { theme } = useTheme();

    return (
        <div className="min-h-screen flex flex-col">
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
