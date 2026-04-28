'use client'

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { createClient } from '@/lib/supabase/client'
import type { FamilyMember } from '@/lib/types'
import { toast } from 'sonner'

const QUERY_KEY = ['family-members']

export function useFamilyMembers() {
  const supabase = createClient()

  return useQuery({
    queryKey: QUERY_KEY,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('family_members')
        .select('*')
        .is('deleted_at', null)
        .order('created_at')
      if (error) throw error
      return data as FamilyMember[]
    },
  })
}

export function useFamilyMember(id: string) {
  const supabase = createClient()

  return useQuery({
    queryKey: [...QUERY_KEY, id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('family_members')
        .select('*')
        .eq('id', id)
        .single()
      if (error) throw error
      return data as FamilyMember
    },
    enabled: !!id,
  })
}

export function useCreateFamilyMember() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (member: Partial<FamilyMember>) => {
      const { data: { user } } = await supabase.auth.getUser()
      const { data, error } = await supabase
        .from('family_members')
        .insert({ ...member, user_id: user!.id })
        .select()
        .single()
      if (error) throw error
      return data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: QUERY_KEY }),
    onError: (err: Error) => toast.error(`Erreur: ${err.message}`),
  })
}

export function useUpdateFamilyMember() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ id, data }: { id: string; data: Partial<FamilyMember> }) => {
      const { data: result, error } = await supabase
        .from('family_members')
        .update(data)
        .eq('id', id)
        .select()
        .single()
      if (error) throw error
      return result
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: QUERY_KEY }),
    onError: (err: Error) => toast.error(`Erreur: ${err.message}`),
  })
}

export function useDeleteFamilyMember() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('family_members')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: QUERY_KEY })
      toast.success('Membre supprimé')
    },
    onError: (err: Error) => toast.error(`Erreur: ${err.message}`),
  })
}
