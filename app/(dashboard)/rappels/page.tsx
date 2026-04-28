'use client'

import { useState } from 'react'
import { Plus, Bell, CheckCircle, Clock } from 'lucide-react'
import { toast } from 'sonner'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { PageHeader } from '@/components/layout/header'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Badge } from '@/components/ui/badge'
import { EmptyState } from '@/components/shared/empty-state'
import { SkeletonList } from '@/components/shared/loading'
import { ConfirmDialog } from '@/components/shared/confirm-dialog'
import { useFamilyMembers } from '@/lib/hooks/use-family-members'
import { createClient } from '@/lib/supabase/client'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { formatDateTime, isOverdue } from '@/lib/utils/date'
import type { Reminder } from '@/lib/types'

function useReminders() {
  const supabase = createClient()
  return useQuery({
    queryKey: ['reminders'],
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

const schema = z.object({
  family_member_id: z.string().optional(),
  title: z.string().min(1, 'Le titre est requis'),
  description: z.string().optional(),
  remind_at: z.string().min(1, 'La date est requise'),
  recurrence: z.string().optional(),
})

type FormData = z.infer<typeof schema>

const RECURRENCE_OPTIONS = [
  { value: 'none', label: 'Pas de récurrence' },
  { value: 'daily', label: 'Quotidien' },
  { value: 'weekly', label: 'Hebdomadaire' },
  { value: 'monthly', label: 'Mensuel' },
]

function ReminderForm({ members, onSubmit, onCancel }: {
  members: { id: string; name: string }[]
  onSubmit: (data: Partial<Reminder>) => Promise<void>
  onCancel?: () => void
}) {
  const [loading, setLoading] = useState(false)
  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const submit = async (data: FormData) => {
    setLoading(true)
    try {
      await onSubmit({
        family_member_id: data.family_member_id || null,
        title: data.title,
        description: data.description || null,
        remind_at: new Date(data.remind_at).toISOString(),
        recurrence: (data.recurrence === 'none' ? null : data.recurrence) as Reminder['recurrence'],
        is_done: false,
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit(submit)} className="space-y-4">
      <Input label="Titre *" placeholder="Rendez-vous cardiologue..." error={errors.title?.message} {...register('title')} />

      <Select value={watch('family_member_id') || ''} onValueChange={(v) => setValue('family_member_id', v)}>
        <SelectTrigger label="Membre (optionnel)">
          <SelectValue placeholder="Toute la famille" />
        </SelectTrigger>
        <SelectContent>
          {members.map((m) => <SelectItem key={m.id} value={m.id}>{m.name}</SelectItem>)}
        </SelectContent>
      </Select>

      <Input label="Date et heure *" type="datetime-local" error={errors.remind_at?.message} {...register('remind_at')} />

      <Select value={watch('recurrence') || 'none'} onValueChange={(v) => setValue('recurrence', v)}>
        <SelectTrigger label="Récurrence">
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {RECURRENCE_OPTIONS.map((o) => <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>)}
        </SelectContent>
      </Select>

      <Textarea label="Description" rows={2} {...register('description')} />

      <div className="flex gap-3 pt-2">
        {onCancel && <Button type="button" variant="outline" className="flex-1" onClick={onCancel}>Annuler</Button>}
        <Button type="submit" loading={loading} className="flex-1">Ajouter</Button>
      </div>
    </form>
  )
}

export default function RappelsPage() {
  const [open, setOpen] = useState(false)
  const { data: reminders = [], isLoading } = useReminders()
  const { data: members = [] } = useFamilyMembers()
  const queryClient = useQueryClient()
  const supabase = createClient()

  const createReminder = useMutation({
    mutationFn: async (data: Partial<Reminder>) => {
      const { error } = await supabase.from('reminders').insert(data)
      if (error) throw error
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['reminders'] }),
  })

  const toggleDone = useMutation({
    mutationFn: async ({ id, is_done }: { id: string; is_done: boolean }) => {
      const { error } = await supabase.from('reminders').update({ is_done }).eq('id', id)
      if (error) throw error
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['reminders'] }),
  })

  const deleteReminder = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from('reminders').update({ deleted_at: new Date().toISOString() }).eq('id', id)
      if (error) throw error
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['reminders'] }),
  })

  const handleSubmit = async (data: Partial<Reminder>) => {
    await createReminder.mutateAsync(data)
    toast.success('Rappel ajouté')
    setOpen(false)
  }

  const pending = reminders.filter((r) => !r.is_done)
  const done = reminders.filter((r) => r.is_done)

  return (
    <>
      <PageHeader
        title="Rappels"
        description={`${pending.length} rappel${pending.length !== 1 ? 's' : ''} en attente`}
        action={
          <Button size="sm" onClick={() => setOpen(true)}>
            <Plus className="w-4 h-4 mr-1" /> Ajouter
          </Button>
        }
      />

      <div className="p-4 lg:p-6 max-w-2xl mx-auto space-y-4">
        {isLoading ? (
          <SkeletonList count={3} />
        ) : reminders.length === 0 ? (
          <EmptyState
            icon={Bell}
            title="Aucun rappel"
            description="Ajoutez des rappels pour vos rendez-vous médicaux et traitements."
            action={<Button onClick={() => setOpen(true)}><Plus className="w-4 h-4 mr-2" /> Ajouter</Button>}
          />
        ) : (
          <>
            {pending.length > 0 && (
              <div className="space-y-2">
                <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">À venir</h2>
                {pending.map((r) => {
                  const member = members.find((m) => m.id === r.family_member_id)
                  const overdue = isOverdue(r.remind_at)
                  return (
                    <div key={r.id} className="bg-card border border-border rounded-2xl p-4 shadow-card flex items-start gap-3">
                      <button
                        onClick={() => toggleDone.mutateAsync({ id: r.id, is_done: true }).then(() => toast.success('Marqué fait'))}
                        className="mt-0.5 text-muted-foreground hover:text-secondary-500 transition-colors flex-shrink-0"
                      >
                        <CheckCircle className="w-5 h-5" />
                      </button>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <h3 className="font-semibold text-foreground">{r.title}</h3>
                          {overdue && <Badge variant="destructive">En retard</Badge>}
                        </div>
                        <div className="flex flex-wrap gap-x-3 gap-y-0.5 mt-0.5 text-xs text-muted-foreground">
                          <span className="flex items-center gap-1">
                            <Clock className="w-3.5 h-3.5" />
                            {formatDateTime(r.remind_at)}
                          </span>
                          {member && <span>{member.name}</span>}
                          {r.recurrence && r.recurrence !== 'none' && (
                            <span>{RECURRENCE_OPTIONS.find((o) => o.value === r.recurrence)?.label}</span>
                          )}
                        </div>
                        {r.description && <p className="mt-1 text-xs text-muted-foreground">{r.description}</p>}
                      </div>
                      <ConfirmDialog
                        title="Supprimer le rappel"
                        description={`Supprimer "${r.title}" ?`}
                        onConfirm={() => deleteReminder.mutateAsync(r.id).then(() => toast.success('Supprimé'))}
                      >
                        <Button size="icon-sm" variant="ghost" className="text-muted-foreground hover:text-destructive flex-shrink-0">
                          ×
                        </Button>
                      </ConfirmDialog>
                    </div>
                  )
                })}
              </div>
            )}

            {done.length > 0 && (
              <div className="space-y-2">
                <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Effectués</h2>
                {done.map((r) => (
                  <div key={r.id} className="bg-muted/50 border border-border rounded-2xl p-4 flex items-start gap-3 opacity-60">
                    <button
                      onClick={() => toggleDone.mutateAsync({ id: r.id, is_done: false })}
                      className="mt-0.5 text-secondary-500 flex-shrink-0"
                    >
                      <CheckCircle className="w-5 h-5 fill-secondary-500" />
                    </button>
                    <div className="flex-1 min-w-0">
                      <h3 className="font-medium text-foreground line-through">{r.title}</h3>
                      <p className="text-xs text-muted-foreground">{formatDateTime(r.remind_at)}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </>
        )}
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Nouveau rappel</DialogTitle>
          </DialogHeader>
          <ReminderForm members={members} onSubmit={handleSubmit} onCancel={() => setOpen(false)} />
        </DialogContent>
      </Dialog>
    </>
  )
}
