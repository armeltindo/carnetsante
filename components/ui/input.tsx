import * as React from 'react'
import { cn } from '@/lib/utils/cn'

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  icon?: React.ReactNode
  suffix?: string
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, label, error, icon, suffix, id, ...props }, ref) => {
    const inputId = id || label?.toLowerCase().replace(/\s+/g, '-')

    return (
      <div className="flex flex-col gap-1.5">
        {label && (
          <label htmlFor={inputId} className="text-sm font-medium text-foreground">
            {label}
          </label>
        )}
        <div className="relative">
          {icon && (
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground">
              {icon}
            </div>
          )}
          <input
            id={inputId}
            type={type}
            className={cn(
              'flex h-10 w-full rounded-xl border border-border bg-card px-3 py-2 text-sm ring-offset-background',
              'placeholder:text-muted-foreground',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500 focus-visible:border-primary-500',
              'disabled:cursor-not-allowed disabled:opacity-50',
              'transition-colors',
              icon && 'pl-10',
              suffix && 'pr-12',
              error && 'border-destructive focus-visible:ring-destructive',
              className
            )}
            ref={ref}
            {...props}
          />
          {suffix && (
            <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">
              {suffix}
            </span>
          )}
        </div>
        {error && <p className="text-xs text-destructive">{error}</p>}
      </div>
    )
  }
)
Input.displayName = 'Input'

export { Input }
