'use client'

import { useState, useEffect, useCallback } from 'react'

export type NotificationPermission = 'default' | 'granted' | 'denied'

export function useNotifications() {
  const [permission, setPermission] = useState<NotificationPermission>('default')
  const supported = typeof window !== 'undefined' && 'Notification' in window

  useEffect(() => {
    if (supported) setPermission(Notification.permission as NotificationPermission)
  }, [supported])

  const requestPermission = useCallback(async () => {
    if (!supported) return false
    const result = await Notification.requestPermission()
    setPermission(result as NotificationPermission)
    return result === 'granted'
  }, [supported])

  const scheduleReminder = useCallback((title: string, body: string, remindAt: Date) => {
    if (permission !== 'granted') return
    const delay = remindAt.getTime() - Date.now()
    if (delay <= 0) return

    const id = window.setTimeout(() => {
      new Notification(title, {
        body,
        icon: '/icons/icon-192.png',
        tag: `reminder-${Date.now()}`,
      })
    }, delay)

    return id
  }, [permission])

  const notify = useCallback((title: string, body: string) => {
    if (permission !== 'granted') return
    new Notification(title, {
      body,
      icon: '/icons/icon-192.png',
    })
  }, [permission])

  return { supported, permission, requestPermission, scheduleReminder, notify }
}
