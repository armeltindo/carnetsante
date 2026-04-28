'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import type { Treatment, FamilyMember } from '@/lib/types'
import { toInputDate } from '@/lib/utils/date'

const schema = z.object({
  family_member_id: z.string().min(1, 'Veuillez choisir un membre'),
  medication_name: z.string().min(1, 'Le nom du médicament est requis'),
  dosage: z.string().optional(),
  frequency: z.string().optional(),
  start_date: z.string().min(1, 'La date de début est requise'),
  end_date: z.string().optional(),
  instructions: z.string().optional(),
  is_active: z.boolean().default(true),
})

type FormData = z.infer<typeof schema>

interface TreatmentFormProps {
  defaultValues?: Partial<Treatment>
  members: FamilyMember[]
  onSubmit: (data: Partial<Treatment>) => Promise<void>
  onCancel?: () => void
}

const FREQUENCY_OPTIONS = [
  '1 fois par jour',
  '2 fois par jour',
  '3 fois par jour',
  '4 fois par jour',
  'Toutes les 8 heures',
  'Toutes les 12 heures',
  'Un jour sur deux',
  'Une fois par semaine',
  'Selon besoin',
]

export function TreatmentForm({ defaultValues, members, onSubmit, onCancel }: TreatmentFormProps) {
  const [loading, setLoading] = useState(false)

  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      family_member_id: defaultValues?.family_member_id || '',
      medication_name: defaultValues?.medication_name || '',
      dosage: defaultValues?.dosage || '',
      frequency: defaultValues?.frequency || '',
      start_date: toInputDate(defaultValues?.start_date) || toInputDate(new Date().toISOString()),
      end_date: toInputDate(defaultValues?.end_date),
      instructions: defaultValues?.instructions || '',
      is_active: defaultValues?.is_active ?? true,
    },
  })

  const handleFormSubmit = async (data: FormData) => {
    setLoading(true)
    try {
      await onSubmit({
        ...data,
        dosage: data.dosage || null,
        frequency: data.frequency || null,
        end_date: data.end_date || null,
        instructions: data.instructions || null,
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

      <Input
        label="Médicament *"
        placeholder="Amoxicilline 500mg"
        error={errors.medication_name?.message}
        {...register('medication_name')}
      />

      <div className="grid grid-cols-2 gap-4">
        <Input
          label="Dosage"
          placeholder="500mg"
          {...register('dosage')}
        />

        <Select
          value={watch('frequency') || ''}
          onValueChange={(v) => setValue('frequency', v)}
        >
          <SelectTrigger label="Fréquence">
            <SelectValue placeholder="Sélectionner" />
          </SelectTrigger>
          <SelectContent>
            {FREQUENCY_OPTIONS.map((f) => (
              <SelectItem key={f} value={f}>{f}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <Input
          label="Date de début *"
          type="date"
          error={errors.start_date?.message}
          {...register('start_date')}
        />
        <Input
          label="Date de fin"
          type="date"
          {...register('end_date')}
        />
      </div>

      <Textarea
        label="Instructions"
        placeholder="Prendre avec de la nourriture, éviter le soleil..."
        rows={3}
        {...register('instructions')}
      />

      <div className="flex gap-3 pt-2">
        {onCancel && (
          <Button type="button" variant="outline" className="flex-1" onClick={onCancel}>
            Annuler
          </Button>
        )}
        <Button type="submit" loading={loading} className="flex-1">
          {defaultValues?.id ? 'Enregistrer' : 'Ajouter le traitement'}
        </Button>
      </div>
    </form>
  )
}
