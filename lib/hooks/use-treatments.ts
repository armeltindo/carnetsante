'use client'

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { createClient } from '@/lib/supabase/client'
import type { Treatment, PeriodicTreatment } from '@/lib/types'
import { calculateNextDate } from '@/lib/utils/date'

const TREATMENT_KEY = ['treatments']

export function useTreatments(memberId?: string) {
  const supabase = createClient()

  return useQuery({
    queryKey: [...TREATMENT_KEY, memberId],
    queryFn: async () => {
      let query = supabase
        .from('treatments')
        .select('*')
        .is('deleted_at', null)
        .order('start_date', { ascending: false })

      if (memberId) query = query.eq('family_member_id', memberId)

      const { data, error } = await query
      if (error) throw error
      return data as Treatment[]
    },
  })
}

export function useCreateTreatment() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (treatment: Partial<Treatment>) => {
      const { data: { user } } = await supabase.auth.getUser()
      const { data, error } = await supabase
        .from('treatments')
        .insert({ ...treatment, user_id: user!.id })
        .select()
        .single()
      if (error) throw error
      return data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: TREATMENT_KEY }),
  })
}

export function useUpdateTreatment() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ id, data }: { id: string; data: Partial<Treatment> }) => {
      const { data: result, error } = await supabase
        .from('treatments')
        .update(data)
        .eq('id', id)
        .select()
        .single()
      if (error) throw error
      return result
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: TREATMENT_KEY }),
  })
}

export function useDeleteTreatment() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('treatments')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: TREATMENT_KEY }),
  })
}

// ─── Traitements périodiques ──────────────────────────────────────────────────
const PERIODIC_KEY = ['periodic-treatments']

export function usePeriodicTreatments(memberId?: string) {
  const supabase = createClient()

  return useQuery({
    queryKey: [...PERIODIC_KEY, memberId],
    queryFn: async () => {
      let query = supabase
        .from('periodic_treatments')
        .select('*')
        .is('deleted_at', null)
        .order('next_date', { ascending: true, nullsFirst: false })

      if (memberId) query = query.eq('family_member_id', memberId)

      const { data, error } = await query
      if (error) throw error
      return data as PeriodicTreatment[]
    },
  })
}

export function useCreatePeriodicTreatment() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (treatment: Partial<PeriodicTreatment>) => {
      const { data: { user } } = await supabase.auth.getUser()
      const nextDate = treatment.last_date && treatment.frequency_days
        ? calculateNextDate(treatment.last_date, treatment.frequency_days)
        : null
      const { data, error } = await supabase
        .from('periodic_treatments')
        .insert({ ...treatment, next_date: nextDate, user_id: user!.id })
        .select()
        .single()
      if (error) throw error
      return data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: PERIODIC_KEY }),
  })
}

export function useUpdatePeriodicTreatment() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ id, data }: { id: string; data: Partial<PeriodicTreatment> }) => {
      if (data.last_date && data.frequency_days) {
        data.next_date = calculateNextDate(data.last_date, data.frequency_days)
      }
      const { data: result, error } = await supabase
        .from('periodic_treatments')
        .update(data)
        .eq('id', id)
        .select()
        .single()
      if (error) throw error
      return result
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: PERIODIC_KEY }),
  })
}

export function useMarkPeriodicTaken() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ id, frequency_days }: { id: string; frequency_days: number }) => {
      const today = new Date().toISOString().slice(0, 10)
      const nextDate = calculateNextDate(today, frequency_days)
      const { error } = await supabase
        .from('periodic_treatments')
        .update({ last_date: today, next_date: nextDate })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: PERIODIC_KEY }),
  })
}

export function useDeletePeriodicTreatment() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('periodic_treatments')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: PERIODIC_KEY }),
  })
}
