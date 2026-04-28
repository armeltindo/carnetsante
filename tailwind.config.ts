import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: ['class'],
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#2D7DD2',
          50: '#EBF4FF',
          100: '#D6E9FF',
          500: '#2D7DD2',
          600: '#1A5CA8',
          foreground: '#FFFFFF',
        },
        secondary: {
          DEFAULT: '#3BB273',
          foreground: '#FFFFFF',
        },
        accent: {
          DEFAULT: '#FF6B35',
          foreground: '#FFFFFF',
        },
        destructive: {
          DEFAULT: '#E53E3E',
          foreground: '#FFFFFF',
        },
        warning: {
          DEFAULT: '#D69E2E',
          foreground: '#FFFFFF',
        },
        success: {
          DEFAULT: '#38A169',
          foreground: '#FFFFFF',
        },
        muted: {
          DEFAULT: '#F8FAFC',
          foreground: '#718096',
        },
        border: '#E2E8F0',
        input: '#E2E8F0',
        ring: '#2D7DD2',
        background: '#F8FAFC',
        foreground: '#1A202C',
        card: {
          DEFAULT: '#FFFFFF',
          foreground: '#1A202C',
        },
        popover: {
          DEFAULT: '#FFFFFF',
          foreground: '#1A202C',
        },
      },
      borderRadius: {
        lg: '12px',
        md: '8px',
        sm: '6px',
        xl: '16px',
        '2xl': '20px',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        card: '0 1px 3px 0 rgba(0, 0, 0, 0.08)',
        'card-hover': '0 4px 12px 0 rgba(0, 0, 0, 0.1)',
        sidebar: '2px 0 8px 0 rgba(0, 0, 0, 0.06)',
      },
      keyframes: {
        'fade-in': {
          '0%': { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'slide-in': {
          '0%': { transform: 'translateX(-100%)' },
          '100%': { transform: 'translateX(0)' },
        },
      },
      animation: {
        'fade-in': 'fade-in 0.2s ease-out',
        'slide-in': 'slide-in 0.2s ease-out',
      },
    },
  },
  plugins: [],
}

export default config
