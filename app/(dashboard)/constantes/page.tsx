'use client'

import { useState, useMemo } from 'react'
import { Plus, Stethoscope, Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import { PageHeader } from '@/components/layout/header'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { VitalsChart } from '@/components/vitals/vitals-chart'
import { VitalForm } from '@/components/vitals/vital-form'
import { EmptyState } from '@/components/shared/empty-state'
import { SkeletonList } from '@/components/shared/loading'
import { ConfirmDialog } from '@/components/shared/confirm-dialog'
import { Badge } from '@/components/ui/badge'
import { useVitals, useCreateVital, useDeleteVital } from '@/lib/hooks/use-vitals'
import { useFamilyMembers } from '@/lib/hooks/use-family-members'
import { VITAL_UNITS, VITAL_COLORS } from '@/lib/types'
import type { Vital, VitalType } from '@/lib/types'
import { formatDateTime } from '@/lib/utils/date'

const VITAL_LABELS: Record<VitalType, string> = {
  temperature: 'Température',
  blood_pressure: 'Tension artérielle',
  glucose: 'Glycémie',
  weight: 'Poids',
  height: 'Taille',
  oxygen: 'Saturation O₂',
  heart_rate: 'Fréquence cardiaque',
  other: 'Autre',
}

export default function ConstantesPage() {
  const [open, setOpen] = useState(false)
  const [selectedMember, setSelectedMember] = useState<string>('all')
  const [selectedType, setSelectedType] = useState<VitalType | 'all'>('all')

  const { data: vitals = [], isLoading } = useVitals(selectedMember === 'all' ? undefined : selectedMember)
  const { data: members = [] } = useFamilyMembers()
  const create = useCreateVital()
  const remove = useDeleteVital()

  const filtered = useMemo(() => {
    if (selectedType === 'all') return vitals
    return vitals.filter((v) => v.type === selectedType)
  }, [vitals, selectedType])

  const groupedByType = useMemo(() => {
    const groups: Record<string, Vital[]> = {}
    filtered.forEach((v) => {
      if (!groups[v.type]) groups[v.type] = []
      groups[v.type].push(v)
    })
    return groups
  }, [filtered])

  const handleSubmit = async (data: Partial<Vital>) => {
    await create.mutateAsync(data)
    toast.success('Mesure ajoutée')
    setOpen(false)
  }

  return (
    <>
      <PageHeader
        title="Constantes vitales"
        description="Suivi des mesures de santé"
        action={
          <Button size="sm" onClick={() => setOpen(true)}>
            <Plus className="w-4 h-4 mr-1" /> Ajouter
          </Button>
        }
      />

      <div className="p-4 lg:p-6 max-w-2xl mx-auto space-y-4">
        {/* Filters */}
        <div className="grid grid-cols-2 gap-3">
          <Select value={selectedMember} onValueChange={setSelectedMember}>
            <SelectTrigger>
              <SelectValue placeholder="Tous les membres" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tous les membres</SelectItem>
              {members.map((m) => <SelectItem key={m.id} value={m.id}>{m.name}</SelectItem>)}
            </SelectContent>
          </Select>
          <Select value={selectedType} onValueChange={(v) => setSelectedType(v as VitalType | 'all')}>
            <SelectTrigger>
              <SelectValue placeholder="Tous les types" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tous les types</SelectItem>
              {(Object.keys(VITAL_LABELS) as VitalType[]).map((t) => (
                <SelectItem key={t} value={t}>{VITAL_LABELS[t]}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {isLoading ? (
          <SkeletonList count={2} />
        ) : Object.keys(groupedByType).length === 0 ? (
          <EmptyState
            icon={Stethoscope}
            title="Aucune mesure"
            description="Enregistrez les constantes vitales de votre famille."
            action={<Button onClick={() => setOpen(true)}><Plus className="w-4 h-4 mr-2" /> Ajouter</Button>}
          />
        ) : (
          Object.entries(groupedByType).map(([type, typeVitals]) => (
            <div key={type} className="bg-card border border-border rounded-2xl p-4 shadow-card">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-3 h-3 rounded-full" style={{ background: VITAL_COLORS[type as VitalType] }} />
                <h3 className="font-semibold text-foreground">{VITAL_LABELS[type as VitalType]}</h3>
                <Badge variant="secondary">{typeVitals.length} mesure{typeVitals.length > 1 ? 's' : ''}</Badge>
              </div>

              {typeVitals.length >= 2 && (
                <div className="mb-4">
                  <VitalsChart vitals={typeVitals} type={type as VitalType} />
                </div>
              )}

              <div className="space-y-2">
                {[...typeVitals]
                  .sort((a, b) => new Date(b.measured_at).getTime() - new Date(a.measured_at).getTime())
                  .slice(0, 5)
                  .map((v) => {
                    const member = members.find((m) => m.id === v.family_member_id)
                    return (
                      <div key={v.id} className="flex items-center gap-3 py-1.5 border-b border-border last:border-0">
                        <div className="flex-1">
                          <span className="text-sm font-medium text-foreground">
                            {v.value} {VITAL_UNITS[v.type as VitalType]}
                          </span>
                          <span className="text-xs text-muted-foreground ml-2">{formatDateTime(v.measured_at)}</span>
                          {member && <span className="text-xs text-muted-foreground ml-2">· {member.name}</span>}
                          {v.notes && <p className="text-xs text-muted-foreground mt-0.5">{v.notes}</p>}
                        </div>
                        <ConfirmDialog
                          title="Supprimer la mesure"
                          description="Supprimer cette mesure ?"
                          onConfirm={async () => { await remove.mutateAsync(v.id); toast.success('Supprimée') }}
                        >
                          <Button size="icon-sm" variant="ghost" className="text-muted-foreground hover:text-destructive">
                            <Trash2 className="w-3.5 h-3.5" />
                          </Button>
                        </ConfirmDialog>
                      </div>
                    )
                  })}
              </div>
            </div>
          ))
        )}
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Nouvelle mesure</DialogTitle>
          </DialogHeader>
          <VitalForm members={members} onSubmit={handleSubmit} onCancel={() => setOpen(false)} />
        </DialogContent>
      </Dialog>
    </>
  )
}
