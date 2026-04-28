'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { VITAL_UNITS, VITAL_LABELS } from '@/lib/types'
import type { Vital, VitalType, FamilyMember } from '@/lib/types'

const schema = z.object({
  family_member_id: z.string().min(1, 'Veuillez choisir un membre'),
  type: z.string().min(1, 'Le type est requis'),
  value: z.string().min(1, 'La valeur est requise'),
  notes: z.string().optional(),
  measured_at: z.string().min(1, 'La date est requise'),
})

type FormData = z.infer<typeof schema>

interface VitalFormProps {
  defaultValues?: Partial<Vital>
  members: FamilyMember[]
  onSubmit: (data: Partial<Vital>) => Promise<void>
  onCancel?: () => void
}

function nowLocalDatetime() {
  const d = new Date()
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

export function VitalForm({ defaultValues, members, onSubmit, onCancel }: VitalFormProps) {
  const [loading, setLoading] = useState(false)

  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      family_member_id: defaultValues?.family_member_id || '',
      type: defaultValues?.type || '',
      value: defaultValues?.value || '',
      notes: defaultValues?.notes || '',
      measured_at: defaultValues?.measured_at
        ? new Date(defaultValues.measured_at).toISOString().slice(0, 16)
        : nowLocalDatetime(),
    },
  })

  const selectedType = watch('type') as VitalType | ''
  const unit = selectedType ? VITAL_UNITS[selectedType] : ''
  const placeholder = selectedType === 'blood_pressure' ? '120/80' : selectedType === 'temperature' ? '37.2' : ''

  const handleFormSubmit = async (data: FormData) => {
    setLoading(true)
    try {
      await onSubmit({
        ...data,
        type: data.type as VitalType,
        notes: data.notes || null,
        measured_at: new Date(data.measured_at).toISOString(),
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
      <Select
        value={watch('family_member_id')}
        onValueChange={(v) => setValue('family_member_id', v, { shouldValidate: true })}
      >
        <SelectTrigger label="Membre de la famille *" error={errors.family_member_id?.message}>
          <SelectValue placeholder="Sélectionner un membre" />
        </SelectTrigger>
        <SelectContent>
          {members.map((m) => (
            <SelectItem key={m.id} value={m.id}>{m.name}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Select
        value={watch('type')}
        onValueChange={(v) => setValue('type', v, { shouldValidate: true })}
      >
        <SelectTrigger label="Type de constante *" error={errors.type?.message}>
          <SelectValue placeholder="Sélectionner" />
        </SelectTrigger>
        <SelectContent>
          {(Object.keys(VITAL_LABELS) as VitalType[]).map((t) => (
            <SelectItem key={t} value={t}>{VITAL_LABELS[t]}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Input
        label={`Valeur${unit ? ` (${unit})` : ''} *`}
        placeholder={placeholder || 'Entrer la valeur'}
        error={errors.value?.message}
        {...register('value')}
      />

      <Input
        label="Date et heure *"
        type="datetime-local"
        error={errors.measured_at?.message}
        {...register('measured_at')}
      />

      <Textarea
        label="Notes"
        placeholder="Observations, contexte..."
        rows={2}
        {...register('notes')}
      />

      <div className="flex gap-3 pt-2">
        {onCancel && (
          <Button type="button" variant="outline" className="flex-1" onClick={onCancel}>
            Annuler
          </Button>
        )}
        <Button type="submit" loading={loading} className="flex-1">
          {defaultValues?.id ? 'Enregistrer' : 'Ajouter la mesure'}
        </Button>
      </div>
    </form>
  )
}
