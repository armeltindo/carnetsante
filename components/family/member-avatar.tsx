import { cn } from '@/lib/utils/cn'

interface MemberAvatarProps {
  name: string
  avatarUrl?: string | null
  size?: 'sm' | 'md' | 'lg' | 'xl'
  className?: string
}

const sizeClasses = {
  sm: 'w-8 h-8 text-xs',
  md: 'w-10 h-10 text-sm',
  lg: 'w-14 h-14 text-lg',
  xl: 'w-20 h-20 text-2xl',
}

export function MemberAvatar({ name, avatarUrl, size = 'md', className }: MemberAvatarProps) {
  const initials = name
    .split(' ')
    .map((p) => p[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()

  if (avatarUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={avatarUrl}
        alt={name}
        className={cn('rounded-full object-cover', sizeClasses[size], className)}
      />
    )
  }

  return (
    <div
      className={cn(
        'rounded-full bg-primary-100 flex items-center justify-center font-bold text-primary-600 flex-shrink-0',
        sizeClasses[size],
        className
      )}
    >
      {initials}
    </div>
  )
}
