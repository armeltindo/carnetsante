'use client'

import { useState } from 'react'
import { Plus, FileText, Stethoscope } from 'lucide-react'
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
import { useMedicalRecords, useCreateMedicalRecord, useDeleteMedicalRecord } from '@/lib/hooks/use-vitals'
import { useFamilyMembers } from '@/lib/hooks/use-family-members'
import { formatDate, toInputDate } from '@/lib/utils/date'
import type { MedicalRecord } from '@/lib/types'

const RECORD_TYPE_LABELS: Record<string, string> = {
  consultation: 'Consultation',
  hospitalization: 'Hospitalisation',
  surgery: 'Chirurgie',
  vaccination: 'Vaccination',
  lab_result: 'Analyse',
  imaging: 'Imagerie',
  other: 'Autre',
}

const schema = z.object({
  family_member_id: z.string().min(1, 'Veuillez choisir un membre'),
  title: z.string().min(1, 'Le titre est requis'),
  type: z.string().optional(),
  description: z.string().optional(),
  date: z.string().min(1, 'La date est requise'),
  doctor: z.string().optional(),
  facility: z.string().optional(),
})

type FormData = z.infer<typeof schema>

function RecordForm({ members, onSubmit, onCancel }: {
  members: { id: string; name: string }[]
  onSubmit: (data: Partial<MedicalRecord>) => Promise<void>
  onCancel?: () => void
}) {
  const [loading, setLoading] = useState(false)
  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { date: toInputDate(new Date().toISOString()) },
  })

  const submit = async (data: FormData) => {
    setLoading(true)
    try {
      await onSubmit({
        ...data,
        type: (data.type as MedicalRecord['type']) || null,
        description: data.description || null,
        doctor: data.doctor || null,
        facility: data.facility || null,
      })
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

      <Input label="Titre *" placeholder="Visite chez le médecin, appendicite..." error={errors.title?.message} {...register('title')} />

      <div className="grid grid-cols-2 gap-4">
        <Select value={watch('type') || ''} onValueChange={(v) => setValue('type', v)}>
          <SelectTrigger label="Type">
            <SelectValue placeholder="Type" />
          </SelectTrigger>
          <SelectContent>
            {Object.entries(RECORD_TYPE_LABELS).map(([k, v]) => <SelectItem key={k} value={k}>{v}</SelectItem>)}
          </SelectContent>
        </Select>
        <Input label="Date *" type="date" error={errors.date?.message} {...register('date')} />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <Input label="Médecin" placeholder="Dr. Martin" {...register('doctor')} />
        <Input label="Établissement" placeholder="CHU..." {...register('facility')} />
      </div>

      <Textarea label="Description" rows={3} {...register('description')} />

      <div className="flex gap-3 pt-2">
        {onCancel && <Button type="button" variant="outline" className="flex-1" onClick={onCancel}>Annuler</Button>}
        <Button type="submit" loading={loading} className="flex-1">Ajouter</Button>
      </div>
    </form>
  )
}

export default function HistoriquePage() {
  const [open, setOpen] = useState(false)
  const { data: records = [], isLoading } = useMedicalRecords()
  const { data: members = [] } = useFamilyMembers()
  const create = useCreateMedicalRecord()
  const remove = useDeleteMedicalRecord()

  const handleSubmit = async (data: Partial<MedicalRecord>) => {
    await create.mutateAsync(data)
    toast.success('Antécédent ajouté')
    setOpen(false)
  }

  return (
    <>
      <PageHeader
        title="Historique médical"
        description={`${records.length} entrée${records.length !== 1 ? 's' : ''}`}
        action={
          <Button size="sm" onClick={() => setOpen(true)}>
            <Plus className="w-4 h-4 mr-1" /> Ajouter
          </Button>
        }
      />

      <div className="p-4 lg:p-6 max-w-2xl mx-auto space-y-3">
        {isLoading ? (
          <SkeletonList count={3} />
        ) : records.length === 0 ? (
          <EmptyState
            icon={FileText}
            title="Aucun antécédent"
            description="Enregistrez les événements médicaux importants de votre famille."
            action={<Button onClick={() => setOpen(true)}><Plus className="w-4 h-4 mr-2" /> Ajouter</Button>}
          />
        ) : (
          records.map((r) => {
            const member = members.find((m) => m.id === r.family_member_id)
            return (
              <div key={r.id} className="bg-card border border-border rounded-2xl p-4 shadow-card">
                <div className="flex items-start gap-3">
                  <div className="w-9 h-9 rounded-xl bg-purple-50 flex items-center justify-center flex-shrink-0">
                    <Stethoscope className="w-4 h-4 text-purple-500" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <h3 className="font-semibold text-foreground">{r.title}</h3>
                      {r.type && <Badge variant="secondary">{RECORD_TYPE_LABELS[r.type] || r.type}</Badge>}
                    </div>
                    <div className="mt-1 flex flex-wrap gap-x-3 gap-y-0.5 text-xs text-muted-foreground">
                      <span>{formatDate(r.date)}</span>
                      {member && <span>{member.name}</span>}
                      {r.doctor && <span>Dr. {r.doctor}</span>}
                      {r.facility && <span>{r.facility}</span>}
                    </div>
                    {r.description && <p className="mt-1.5 text-sm text-muted-foreground line-clamp-2">{r.description}</p>}
                  </div>
                </div>
                <div className="mt-3 flex justify-end">
                  <ConfirmDialog
                    title="Supprimer l'antécédent"
                    description={`Supprimer "${r.title}" ?`}
                    onConfirm={() => remove.mutateAsync(r.id).then(() => toast.success('Supprimé'))}
                  >
                    <Button size="sm" variant="ghost" className="text-destructive hover:text-destructive text-xs">Supprimer</Button>
                  </ConfirmDialog>
                </div>
              </div>
            )
          })
        )}
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Nouvel antécédent médical</DialogTitle>
          </DialogHeader>
          <RecordForm members={members} onSubmit={handleSubmit} onCancel={() => setOpen(false)} />
        </DialogContent>
      </Dialog>
    </>
  )
}
