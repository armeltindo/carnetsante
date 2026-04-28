'use client'

import { useState, useMemo } from 'react'
import { Plus, Pill } from 'lucide-react'
import { toast } from 'sonner'
import { PageHeader } from '@/components/layout/header'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { TreatmentCard } from '@/components/treatments/treatment-card'
import { TreatmentForm } from '@/components/treatments/treatment-form'
import { EmptyState } from '@/components/shared/empty-state'
import { SkeletonList } from '@/components/shared/loading'
import { useTreatments, useCreateTreatment, useUpdateTreatment, useDeleteTreatment } from '@/lib/hooks/use-treatments'
import { useFamilyMembers } from '@/lib/hooks/use-family-members'
import type { Treatment } from '@/lib/types'

export default function TraitementsPage() {
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<Treatment | null>(null)
  const [filter, setFilter] = useState<'all' | 'active' | 'done'>('active')

  const { data: treatments = [], isLoading } = useTreatments()
  const { data: members = [] } = useFamilyMembers()
  const createTreatment = useCreateTreatment()
  const updateTreatment = useUpdateTreatment()
  const deleteTreatment = useDeleteTreatment()

  const filtered = useMemo(() => {
    if (filter === 'active') return treatments.filter((t) => t.is_active)
    if (filter === 'done') return treatments.filter((t) => !t.is_active)
    return treatments
  }, [treatments, filter])

  const handleSubmit = async (data: Partial<Treatment>) => {
    if (editing) {
      await updateTreatment.mutateAsync({ id: editing.id, data })
      toast.success('Traitement mis à jour')
    } else {
      await createTreatment.mutateAsync(data)
      toast.success('Traitement ajouté')
    }
    setOpen(false)
    setEditing(null)
  }

  const handleEdit = (t: Treatment) => {
    setEditing(t)
    setOpen(true)
  }

  const handleToggle = async (t: Treatment) => {
    await updateTreatment.mutateAsync({ id: t.id, data: { is_active: !t.is_active } })
    toast.success(t.is_active ? 'Traitement terminé' : 'Traitement réactivé')
  }

  const handleDelete = async (id: string) => {
    await deleteTreatment.mutateAsync(id)
    toast.success('Traitement supprimé')
  }

  return (
    <>
      <PageHeader
        title="Traitements"
        description={`${treatments.filter((t) => t.is_active).length} traitement${treatments.filter((t) => t.is_active).length !== 1 ? 's' : ''} actif${treatments.filter((t) => t.is_active).length !== 1 ? 's' : ''}`}
        action={
          <Button size="sm" onClick={() => { setEditing(null); setOpen(true) }}>
            <Plus className="w-4 h-4 mr-1" /> Ajouter
          </Button>
        }
      />

      <div className="p-4 lg:p-6 max-w-2xl mx-auto space-y-4">
        {/* Filter tabs */}
        <div className="flex gap-1 bg-muted p-1 rounded-xl">
          {(['active', 'all', 'done'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`flex-1 text-sm py-1.5 rounded-lg font-medium transition-colors ${filter === f ? 'bg-card text-foreground shadow-sm' : 'text-muted-foreground'}`}
            >
              {f === 'active' ? 'Actifs' : f === 'all' ? 'Tous' : 'Terminés'}
            </button>
          ))}
        </div>

        {isLoading ? (
          <SkeletonList count={3} />
        ) : filtered.length === 0 ? (
          <EmptyState
            icon={Pill}
            title="Aucun traitement"
            description="Ajoutez un traitement pour commencer le suivi."
            action={
              <Button onClick={() => setOpen(true)}><Plus className="w-4 h-4 mr-2" /> Ajouter</Button>
            }
          />
        ) : (
          <div className="space-y-3">
            {filtered.map((t) => (
              <TreatmentCard
                key={t.id}
                treatment={t}
                memberName={members.find((m) => m.id === t.family_member_id)?.name}
                onEdit={handleEdit}
                onDelete={handleDelete}
                onToggleActive={handleToggle}
              />
            ))}
          </div>
        )}
      </div>

      <Dialog open={open} onOpenChange={(v) => { setOpen(v); if (!v) setEditing(null) }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editing ? 'Modifier le traitement' : 'Nouveau traitement'}</DialogTitle>
          </DialogHeader>
          <TreatmentForm
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
