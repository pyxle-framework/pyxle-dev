import './styles/tailwind.css';
import React, { useState, useEffect, createContext, useContext } from 'react';

const ThemeContext = createContext({ theme: 'dark', toggle: () => {} });

export function useTheme() {
    return useContext(ThemeContext);
}

export const slots = {};
export const createSlots = () => slots;

export default function RootLayout({ children }) {
    const [theme, setTheme] = useState('dark');

    useEffect(() => {
        const stored = typeof localStorage !== 'undefined' ? localStorage.getItem('pyxle-theme') : null;
        if (stored === 'light' || stored === 'dark') setTheme(stored);
    }, []);

    useEffect(() => {
        document.documentElement.classList.remove('light', 'dark');
        document.documentElement.classList.add(theme);
        // Use `overflow-x: clip` (NOT `hidden`) so that descendants with
        // `position: sticky` keep working. `hidden` creates a new scroll
        // container which breaks sticky; `clip` prevents horizontal
        // overflow the same way visually without breaking sticky.
        document.documentElement.style.overflowX = 'clip';
        if (typeof localStorage !== 'undefined') localStorage.setItem('pyxle-theme', theme);
    }, [theme]);

    const toggle = () => setTheme(t => t === 'dark' ? 'light' : 'dark');

    return (
        <ThemeContext.Provider value={{ theme, toggle }}>
            <div className={`min-h-screen overflow-x-clip antialiased transition-colors duration-300 ${theme === 'dark' ? 'bg-[#0a0a0b] text-white' : 'bg-white text-zinc-900'}`}>
                {children}
            </div>
        </ThemeContext.Provider>
    );
}
