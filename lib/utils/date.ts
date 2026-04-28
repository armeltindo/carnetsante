import { format, formatDistance, differenceInYears, differenceInMonths, addDays, isPast, isWithinInterval, subDays } from 'date-fns'
import { fr } from 'date-fns/locale'

export function formatDate(date: string | Date | null | undefined): string {
  if (!date) return '--'
  try {
    return format(new Date(date), 'dd/MM/yyyy')
  } catch {
    return '--'
  }
}

export function formatDateTime(date: string | Date | null | undefined): string {
  if (!date) return '--'
  try {
    return format(new Date(date), 'dd/MM/yyyy HH:mm')
  } catch {
    return '--'
  }
}

export function formatShortDate(date: string | Date | null | undefined): string {
  if (!date) return '--'
  try {
    return format(new Date(date), 'd MMM yyyy', { locale: fr })
  } catch {
    return '--'
  }
}

export function formatRelative(date: string | Date | null | undefined): string {
  if (!date) return '--'
  try {
    return formatDistance(new Date(date), new Date(), { addSuffix: true, locale: fr })
  } catch {
    return '--'
  }
}

export function formatAge(birthDate: string | null | undefined): string {
  if (!birthDate) return '--'
  try {
    const date = new Date(birthDate)
    const years = differenceInYears(new Date(), date)
    if (years === 0) {
      const months = differenceInMonths(new Date(), date)
      return `${months} mois`
    }
    return `${years} ans`
  } catch {
    return '--'
  }
}

export function formatDaysUntil(date: string | null | undefined): string {
  if (!date) return '--'
  try {
    const target = new Date(date)
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    target.setHours(0, 0, 0, 0)
    const diff = Math.round((target.getTime() - today.getTime()) / (1000 * 60 * 60 * 24))
    if (diff < 0) return `En retard de ${Math.abs(diff)} j`
    if (diff === 0) return 'Aujourd\'hui'
    if (diff === 1) return 'Demain'
    return `Dans ${diff} jours`
  } catch {
    return '--'
  }
}

export function calculateNextDate(lastDate: string, frequencyDays: number): string {
  return addDays(new Date(lastDate), frequencyDays).toISOString().split('T')[0]
}

export function isOverdue(date: string | null | undefined): boolean {
  if (!date) return false
  return isPast(new Date(date))
}

export function isDueSoon(date: string | null | undefined, daysThreshold = 7): boolean {
  if (!date) return false
  try {
    const target = new Date(date)
    const now = new Date()
    return isWithinInterval(target, { start: now, end: addDays(now, daysThreshold) })
  } catch {
    return false
  }
}

export function toInputDate(date: string | null | undefined): string {
  if (!date) return ''
  try {
    return format(new Date(date), 'yyyy-MM-dd')
  } catch {
    return ''
  }
}
