'use client'

import { useState } from 'react'
import { Plus, Activity, CheckCircle } from 'lucide-react'
import { toast } from 'sonner'
import { PageHeader } from '@/components/layout/header'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { EmptyState } from '@/components/shared/empty-state'
import { SkeletonList } from '@/components/shared/loading'
import { ConfirmDialog } from '@/components/shared/confirm-dialog'
import { usePeriodicTreatments, useCreatePeriodicTreatment, useUpdatePeriodicTreatment, useMarkPeriodicTaken, useDeletePeriodicTreatment } from '@/lib/hooks/use-treatments'
import { useFamilyMembers } from '@/lib/hooks/use-family-members'
import { formatDaysUntil, isOverdue, isDueSoon, formatShortDate } from '@/lib/utils/date'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { toInputDate } from '@/lib/utils/date'
import type { PeriodicTreatment } from '@/lib/types'

const schema = z.object({
  family_member_id: z.string().min(1, 'Veuillez choisir un membre'),
  treatment_name: z.string().min(1, 'Le nom est requis'),
  frequency_days: z.coerce.number().min(1, 'La fréquence doit être positive'),
  last_date: z.string().optional(),
  notes: z.string().optional(),
})

type FormData = z.infer<typeof schema>

const FREQUENCY_PRESETS = [
  { label: 'Tous les mois (30j)', days: 30 },
  { label: 'Tous les 3 mois (90j)', days: 90 },
  { label: 'Tous les 6 mois (180j)', days: 180 },
  { label: 'Chaque année (365j)', days: 365 },
]

function PeriodicForm({ defaultValues, members, onSubmit, onCancel }: {
  defaultValues?: Partial<PeriodicTreatment>
  members: { id: string; name: string }[]
  onSubmit: (data: Partial<PeriodicTreatment>) => Promise<void>
  onCancel?: () => void
}) {
  const [loading, setLoading] = useState(false)
  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      family_member_id: defaultValues?.family_member_id || '',
      treatment_name: defaultValues?.treatment_name || '',
      frequency_days: defaultValues?.frequency_days || 30,
      last_date: toInputDate(defaultValues?.last_date),
      notes: defaultValues?.notes || '',
    },
  })

  const submit = async (data: FormData) => {
    setLoading(true)
    try {
      await onSubmit({ ...data, notes: data.notes || null, last_date: data.last_date || null })
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit(submit)} className="space-y-4">
      <Select value={watch('family_member_id')} onValueChange={(v) => setValue('family_member_id', v, { shouldValidate: true })}>
        <SelectTrigger label="Membre *" error={errors.family_member_id?.message}>
          <SelectValue placeholder="Sélectionner" />
        </SelectTrigger>
        <SelectContent>
          {members.map((m) => <SelectItem key={m.id} value={m.id}>{m.name}</SelectItem>)}
        </SelectContent>
      </Select>

      <Input label="Traitement *" placeholder="Antipaludéen, vermifuge..." error={errors.treatment_name?.message} {...register('treatment_name')} />

      <div>
        <p className="text-xs font-medium text-muted-foreground mb-2">Fréquence rapide</p>
        <div className="grid grid-cols-2 gap-2 mb-3">
          {FREQUENCY_PRESETS.map((p) => (
            <button
              key={p.days}
              type="button"
              onClick={() => setValue('frequency_days', p.days)}
              className={`text-xs py-1.5 px-2 rounded-lg border transition-colors ${watch('frequency_days') === p.days ? 'bg-primary-500 text-white border-primary-500' : 'border-border text-muted-foreground hover:border-primary-400'}`}
            >
              {p.label}
            </button>
          ))}
        </div>
        <Input label="Fréquence (jours) *" type="number" min={1} error={errors.frequency_days?.message} {...register('frequency_days')} />
      </div>

      <Input label="Dernière prise" type="date" {...register('last_date')} />
      <Textarea label="Notes" rows={2} {...register('notes')} />

      <div className="flex gap-3 pt-2">
        {onCancel && <Button type="button" variant="outline" className="flex-1" onClick={onCancel}>Annuler</Button>}
        <Button type="submit" loading={loading} className="flex-1">
          {defaultValues?.id ? 'Enregistrer' : 'Ajouter'}
        </Button>
      </div>
    </form>
  )
}

export default function PeriodiquesPage() {
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<PeriodicTreatment | null>(null)
  const { data: periodics = [], isLoading } = usePeriodicTreatments()
  const { data: members = [] } = useFamilyMembers()
  const create = useCreatePeriodicTreatment()
  const update = useUpdatePeriodicTreatment()
  const markTaken = useMarkPeriodicTaken()
  const remove = useDeletePeriodicTreatment()

  const handleSubmit = async (data: Partial<PeriodicTreatment>) => {
    if (editing) {
      await update.mutateAsync({ id: editing.id, data })
      toast.success('Traitement mis à jour')
    } else {
      await create.mutateAsync(data)
      toast.success('Traitement ajouté')
    }
    setOpen(false)
    setEditing(null)
  }

  const handleMarkTaken = async (p: PeriodicTreatment) => {
    await markTaken.mutateAsync({ id: p.id, frequency_days: p.frequency_days })
    toast.success('Prise enregistrée')
  }

  return (
    <>
      <PageHeader
        title="Traitements périodiques"
        description="Antipaludéens, vermifuges, vaccins..."
        action={
          <Button size="sm" onClick={() => { setEditing(null); setOpen(true) }}>
            <Plus className="w-4 h-4 mr-1" /> Ajouter
          </Button>
        }
      />

      <div className="p-4 lg:p-6 max-w-2xl mx-auto space-y-3">
        {isLoading ? (
          <SkeletonList count={3} />
        ) : periodics.length === 0 ? (
          <EmptyState
            icon={Activity}
            title="Aucun traitement périodique"
            description="Ajoutez vos traitements récurrents comme les antipaludéens ou vermifuges."
            action={<Button onClick={() => setOpen(true)}><Plus className="w-4 h-4 mr-2" /> Ajouter</Button>}
          />
        ) : (
          periodics.map((p) => {
            const member = members.find((m) => m.id === p.family_member_id)
            const overdue = p.next_date ? isOverdue(p.next_date) : false
            const dueSoon = p.next_date ? isDueSoon(p.next_date) : false

            return (
              <div key={p.id} className="bg-card border border-border rounded-2xl p-4 shadow-card">
                <div className="flex items-start gap-3">
                  <div className={`w-2.5 h-2.5 rounded-full mt-1.5 flex-shrink-0 ${overdue ? 'bg-destructive-500' : dueSoon ? 'bg-warning-400' : 'bg-secondary-500'}`} />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <h3 className="font-semibold text-foreground">{p.treatment_name}</h3>
                        {member && <p className="text-xs text-muted-foreground">{member.name}</p>}
                      </div>
                      {p.next_date && (
                        <Badge variant={overdue ? 'destructive' : dueSoon ? 'warning' : 'success'}>
                          {formatDaysUntil(p.next_date)}
                        </Badge>
                      )}
                    </div>
                    <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
                      <span>Tous les {p.frequency_days} jours</span>
                      {p.last_date && <span>Dernière prise : {formatShortDate(p.last_date)}</span>}
                      {p.next_date && <span>Prochaine : {formatShortDate(p.next_date)}</span>}
                    </div>
                    {p.notes && <p className="mt-1.5 text-xs text-muted-foreground">{p.notes}</p>}
                  </div>
                </div>
                <div className="mt-3 flex gap-2">
                  <Button size="sm" variant="outline" className="flex-1 text-secondary-600 border-secondary-200 hover:bg-secondary-50 hover:border-secondary-400" onClick={() => handleMarkTaken(p)}>
                    <CheckCircle className="w-3.5 h-3.5 mr-1.5" /> Marquer pris
                  </Button>
                  <Button size="sm" variant="ghost" onClick={() => { setEditing(p); setOpen(true) }}>Modifier</Button>
                  <ConfirmDialog
                    title="Supprimer"
                    description={`Supprimer "${p.treatment_name}" ?`}
                    onConfirm={async () => { await remove.mutateAsync(p.id); toast.success('Supprimé') }}
                  >
                    <Button size="sm" variant="ghost" className="text-destructive hover:text-destructive">Supprimer</Button>
                  </ConfirmDialog>
                </div>
              </div>
            )
          })
        )}
      </div>

      <Dialog open={open} onOpenChange={(v) => { setOpen(v); if (!v) setEditing(null) }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editing ? 'Modifier' : 'Nouveau traitement périodique'}</DialogTitle>
          </DialogHeader>
          <PeriodicForm
            defaultValues={editing || undefined}
            members={members}
            onSubmit={handleSubmit}
            onCancel={() => { setOpen(false); setEditing(null) }}
          />
        </DialogContent>
      </Dialog>
    </>
  )
}
