import type { Metadata } from 'next'
import './globals.css'
import { QueryProvider } from '@/components/providers/query-provider'
import { Toaster } from 'sonner'

export const metadata: Metadata = {
  title: 'Carnet Santé',
  description: 'Votre carnet de santé familial numérique',
  manifest: '/manifest.json',
  themeColor: '#2D7DD2',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body>
        <QueryProvider>
          {children}
          <Toaster position="top-center" richColors closeButton />
        </QueryProvider>
      </body>
    </html>
  )
}
