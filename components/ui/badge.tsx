import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils/cn'

const badgeVariants = cva(
  'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors',
  {
    variants: {
      variant: {
        default:     'bg-primary-50 text-primary-600 border border-primary-100',
        success:     'bg-success-50 text-success-700 border border-success-100',
        warning:     'bg-warning-50 text-warning-700 border border-warning-100',
        destructive: 'bg-destructive-50 text-destructive-600 border border-destructive-100',
        secondary:   'bg-muted text-muted-foreground border border-border',
        outline:     'border border-border text-foreground',
        violet:      'bg-violet-50 text-violet-600 border border-violet-100',
      },
    },
    defaultVariants: { variant: 'default' },
  }
)

interface BadgeProps extends React.HTMLAttributes<HTMLDivElement>, VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />
}

export { Badge, badgeVariants }
