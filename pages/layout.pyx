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
        if (typeof localStorage !== 'undefined') localStorage.setItem('pyxle-theme', theme);
    }, [theme]);

    const toggle = () => setTheme(t => t === 'dark' ? 'light' : 'dark');

    return (
        <ThemeContext.Provider value={{ theme, toggle }}>
            <div className={`min-h-screen overflow-x-hidden antialiased transition-colors duration-300 ${theme === 'dark' ? 'bg-[#0a0a0b] text-white' : 'bg-white text-zinc-900'}`}>
                {children}
            </div>
        </ThemeContext.Provider>
    );
}
