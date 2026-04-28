'use client'

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { createClient } from '@/lib/supabase/client'
import type { Vital, MedicalRecord, Document } from '@/lib/types'

// ─── Constantes vitales ───────────────────────────────────────────────────────
const VITALS_KEY = ['vitals']

export function useVitals(memberId?: string) {
  const supabase = createClient()

  return useQuery({
    queryKey: [...VITALS_KEY, memberId],
    queryFn: async () => {
      let query = supabase
        .from('vitals')
        .select('*')
        .is('deleted_at', null)
        .order('measured_at', { ascending: false })

      if (memberId) query = query.eq('family_member_id', memberId)

      const { data, error } = await query.limit(200)
      if (error) throw error
      return data as Vital[]
    },
  })
}

export function useCreateVital() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (vital: Partial<Vital>) => {
      const { data: { user } } = await supabase.auth.getUser()
      const { data, error } = await supabase
        .from('vitals')
        .insert({ ...vital, user_id: user!.id })
        .select()
        .single()
      if (error) throw error
      return data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: VITALS_KEY }),
  })
}

export function useDeleteVital() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('vitals')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: VITALS_KEY }),
  })
}

// ─── Dossiers médicaux ────────────────────────────────────────────────────────
const RECORDS_KEY = ['medical-records']

export function useMedicalRecords(memberId?: string) {
  const supabase = createClient()

  return useQuery({
    queryKey: [...RECORDS_KEY, memberId],
    queryFn: async () => {
      let query = supabase
        .from('medical_records')
        .select('*')
        .is('deleted_at', null)
        .order('date', { ascending: false })

      if (memberId) query = query.eq('family_member_id', memberId)

      const { data, error } = await query
      if (error) throw error
      return data as MedicalRecord[]
    },
  })
}

export function useCreateMedicalRecord() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (record: Partial<MedicalRecord>) => {
      const { data: { user } } = await supabase.auth.getUser()
      const { data, error } = await supabase
        .from('medical_records')
        .insert({ ...record, user_id: user!.id })
        .select()
        .single()
      if (error) throw error
      return data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: RECORDS_KEY }),
  })
}

export function useDeleteMedicalRecord() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('medical_records')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: RECORDS_KEY }),
  })
}

// ─── Documents ────────────────────────────────────────────────────────────────
const DOCUMENTS_KEY = ['documents']

export function useDocuments(memberId?: string) {
  const supabase = createClient()

  return useQuery({
    queryKey: [...DOCUMENTS_KEY, memberId],
    enabled: !!memberId,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('documents')
        .select('*')
        .is('deleted_at', null)
        .eq('family_member_id', memberId!)
        .order('created_at', { ascending: false })

      if (error) throw error

      const docs = data as Document[]
      const docsWithUrls = await Promise.all(
        docs.map(async (doc) => {
          const { data: signed } = await supabase.storage
            .from('medical-documents')
            .createSignedUrl(doc.storage_path, 3600)
          return { ...doc, url: signed?.signedUrl }
        })
      )
      return docsWithUrls
    },
  })
}

export function useUploadDocument() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ file, memberId }: { file: File; memberId: string }) => {
      const { data: { user } } = await supabase.auth.getUser()
      const ext = file.name.split('.').pop()
      const storagePath = `${user!.id}/${memberId}/${crypto.randomUUID()}.${ext}`

      const { error: uploadError } = await supabase.storage
        .from('medical-documents')
        .upload(storagePath, file, { contentType: file.type })
      if (uploadError) throw uploadError

      const { data, error } = await supabase
        .from('documents')
        .insert({
          user_id: user!.id,
          family_member_id: memberId,
          name: file.name,
          storage_path: storagePath,
          mime_type: file.type,
          size: file.size,
        })
        .select()
        .single()
      if (error) throw error
      return data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: DOCUMENTS_KEY }),
  })
}

export function useDeleteDocument() {
  const supabase = createClient()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ id, storagePath }: { id: string; storagePath: string }) => {
      await supabase.storage.from('medical-documents').remove([storagePath])
      const { error } = await supabase
        .from('documents')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: DOCUMENTS_KEY }),
  })
}
