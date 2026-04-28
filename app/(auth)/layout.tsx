import { Heart } from 'lucide-react'

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 via-background to-secondary-50 flex items-center justify-center p-4">
      <div className="w-full max-w-sm">
        {/* Logo */}
        <div className="flex items-center gap-3 justify-center mb-8">
          <div className="w-11 h-11 rounded-2xl bg-primary-500 flex items-center justify-center shadow-lg">
            <Heart className="w-6 h-6 text-white fill-white" />
          </div>
          <div>
            <p className="font-bold text-foreground text-lg leading-tight">Carnet Santé</p>
            <p className="text-xs text-muted-foreground">Santé familiale</p>
          </div>
        </div>
        {children}
      </div>
    </div>
  )
}
