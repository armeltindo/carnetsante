import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils/cn'

const badgeVariants = cva(
  'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-primary-50 text-primary-500 border border-primary-100',
        success: 'bg-green-50 text-green-700 border border-green-100',
        warning: 'bg-amber-50 text-amber-700 border border-amber-100',
        destructive: 'bg-red-50 text-red-600 border border-red-100',
        secondary: 'bg-gray-100 text-gray-600 border border-gray-200',
        outline: 'border border-border text-foreground',
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
