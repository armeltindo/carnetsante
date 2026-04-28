'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { X, Plus } from 'lucide-react'
import type { FamilyMember } from '@/lib/types'
import { BLOOD_TYPES } from '@/lib/types'
import { toInputDate } from '@/lib/utils/date'

const schema = z.object({
  name: z.string().min(1, 'Le nom est requis'),
  date_of_birth: z.string().optional(),
  blood_type: z.string().optional(),
  medical_notes: z.string().optional(),
  is_main: z.boolean().default(false),
})

type FormData = z.infer<typeof schema>

interface MemberFormProps {
  defaultValues?: Partial<FamilyMember>
  onSubmit: (data: Partial<FamilyMember>) => Promise<void>
  onCancel?: () => void
}

export function MemberForm({ defaultValues, onSubmit, onCancel }: MemberFormProps) {
  const [allergies, setAllergies] = useState<string[]>(defaultValues?.allergies || [])
  const [allergyInput, setAllergyInput] = useState('')
  const [loading, setLoading] = useState(false)

  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: defaultValues?.name || '',
      date_of_birth: toInputDate(defaultValues?.date_of_birth),
      blood_type: defaultValues?.blood_type || '',
      medical_notes: defaultValues?.medical_notes || '',
      is_main: defaultValues?.is_main || false,
    },
  })

  const isMain = watch('is_main')

  const addAllergy = () => {
    const text = allergyInput.trim()
    if (text && !allergies.includes(text)) {
      setAllergies([...allergies, text])
      setAllergyInput('')
    }
  }

  const handleFormSubmit = async (data: FormData) => {
    setLoading(true)
    try {
      await onSubmit({
        ...data,
        blood_type: (data.blood_type as FamilyMember['blood_type']) || null,
        allergies,
        date_of_birth: data.date_of_birth || null,
        medical_notes: data.medical_notes || null,
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
      <Input
        label="Nom complet *"
        placeholder="Jean Dupont"
        error={errors.name?.message}
        {...register('name')}
      />

      <div className="grid grid-cols-2 gap-4">
        <Input
          label="Date de naissance"
          type="date"
          {...register('date_of_birth')}
        />

        <Select
          value={watch('blood_type') || ''}
          onValueChange={(v) => setValue('blood_type', v)}
        >
          <SelectTrigger label="Groupe sanguin">
            <SelectValue placeholder="Sélectionner" />
          </SelectTrigger>
          <SelectContent>
            {BLOOD_TYPES.map((bt) => (
              <SelectItem key={bt} value={bt}>{bt}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Allergies */}
      <div className="space-y-2">
        <label className="text-sm font-medium text-foreground">Allergies</label>
        <div className="flex gap-2">
          <input
            value={allergyInput}
            onChange={(e) => setAllergyInput(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addAllergy() } }}
            placeholder="Pénicilline, lactose..."
            className="flex-1 h-10 rounded-xl border border-border bg-card px-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
          <Button type="button" size="icon" onClick={addAllergy}>
            <Plus className="w-4 h-4" />
          </Button>
        </div>
        {allergies.length > 0 && (
          <div className="flex flex-wrap gap-2">
            {allergies.map((a) => (
              <span
                key={a}
                className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-red-50 text-red-600 text-xs font-medium border border-red-100"
              >
                {a}
                <button type="button" onClick={() => setAllergies(allergies.filter((x) => x !== a))}>
                  <X className="w-3 h-3" />
                </button>
              </span>
            ))}
          </div>
        )}
      </div>

      <Textarea
        label="Antécédents médicaux"
        placeholder="Hypertension, asthme, opérations..."
        rows={3}
        {...register('medical_notes')}
      />

      <label className="flex items-center gap-3 cursor-pointer">
        <div
          className={`w-10 h-6 rounded-full transition-colors ${isMain ? 'bg-primary-500' : 'bg-gray-200'}`}
          onClick={() => setValue('is_main', !isMain)}
        >
          <div className={`w-5 h-5 rounded-full bg-white shadow-sm m-0.5 transition-transform ${isMain ? 'translate-x-4' : ''}`} />
        </div>
        <span className="text-sm font-medium text-foreground">Membre principal</span>
      </label>

      <div className="flex gap-3 pt-2">
        {onCancel && (
          <Button type="button" variant="outline" className="flex-1" onClick={onCancel}>
            Annuler
          </Button>
        )}
        <Button type="submit" loading={loading} className="flex-1">
          {defaultValues?.id ? 'Enregistrer' : 'Ajouter le membre'}
        </Button>
      </div>
    </form>
  )
}
