import type { Metadata, Viewport } from 'next'
import './globals.css'
import { QueryProvider } from '@/components/providers/query-provider'
import { PWAProvider } from '@/components/providers/pwa-provider'
import { Toaster } from 'sonner'

export const metadata: Metadata = {
  title: 'Carnet Santé',
  description: 'Votre carnet de santé familial numérique',
  manifest: '/manifest.json',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'default',
    title: 'Carnet Santé',
  },
}

export const viewport: Viewport = {
  themeColor: '#2D7DD2',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body>
        <QueryProvider>
          <PWAProvider />
          {children}
          <Toaster position="top-center" richColors closeButton />
        </QueryProvider>
      </body>
    </html>
  )
}
