import { MobileSidebar } from './sidebar'
import { Bell } from 'lucide-react'
import Link from 'next/link'

interface PageHeaderProps {
  title: string
  description?: string
  action?: React.ReactNode
}

export function PageHeader({ title, description, action }: PageHeaderProps) {
  return (
    <header className="sticky top-0 z-30 bg-background/80 backdrop-blur-sm border-b border-border px-4 lg:px-6 py-3.5">
      <div className="flex items-center gap-3">
        <MobileSidebar />
        <div className="flex-1 min-w-0">
          <h1 className="text-lg font-bold text-foreground truncate">{title}</h1>
          {description && (
            <p className="text-xs text-muted-foreground truncate">{description}</p>
          )}
        </div>
        <div className="flex items-center gap-2">
          {action}
          <Link
            href="/rappels"
            className="p-2 rounded-lg hover:bg-muted transition-colors text-muted-foreground hover:text-foreground"
          >
            <Bell className="w-5 h-5" />
          </Link>
        </div>
      </div>
    </header>
  )
}
