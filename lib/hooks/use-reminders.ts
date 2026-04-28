'use client'

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { createClient } from '@/lib/supabase/client'
import type { Reminder } from '@/lib/types'

const REMINDERS_KEY = ['reminders']

export function useReminders() {
  const supabase = createClient()
  return useQuery({
    queryKey: REMINDERS_KEY,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('reminders')
        .select('*')
        .is('deleted_at', null)
        .order('remind_at', { ascending: true })
      if (error) throw error
      return data as Reminder[]
    },
  })
}

export function useCreateReminder() {
  const supabase = createClient()
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (reminder: Partial<Reminder>) => {
      const { data: { user } } = await supabase.auth.getUser()
      const { data, error } = await supabase
        .from('reminders')
        .insert({ ...reminder, user_id: user!.id })
        .select()
        .single()
      if (error) throw error
      return data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: REMINDERS_KEY }),
  })
}

export function useToggleReminder() {
  const supabase = createClient()
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, is_done }: { id: string; is_done: boolean }) => {
      const { error } = await supabase.from('reminders').update({ is_done }).eq('id', id)
      if (error) throw error
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: REMINDERS_KEY }),
  })
}

export function useDeleteReminder() {
  const supabase = createClient()
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('reminders')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: REMINDERS_KEY }),
  })
}
