'use client'

import { use } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import { Pencil, Trash2, Pill, Activity, FileText, Stethoscope } from 'lucide-react'
import { PageHeader } from '@/components/layout/header'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { MemberAvatar } from '@/components/family/member-avatar'
import { ConfirmDialog } from '@/components/shared/confirm-dialog'
import { PageLoader } from '@/components/shared/loading'
import { useFamilyMember, useDeleteFamilyMember } from '@/lib/hooks/use-family-members'
import { useTreatments, usePeriodicTreatments } from '@/lib/hooks/use-treatments'
import { useMedicalRecords, useVitals } from '@/lib/hooks/use-vitals'
import { formatAge, formatDate } from '@/lib/utils/date'

export default function MembrePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const router = useRouter()
  const { data: member, isLoading } = useFamilyMember(id)
  const deleteMember = useDeleteFamilyMember()
  const { data: treatments = [] } = useTreatments(id)
  const { data: periodics = [] } = usePeriodicTreatments(id)
  const { data: records = [] } = useMedicalRecords(id)
  const { data: vitals = [] } = useVitals(id)

  const activeTreatments = treatments.filter((t) => t.is_active)

  const handleDelete = async () => {
    await deleteMember.mutateAsync(id)
    toast.success('Membre supprimé')
    router.push('/famille')
  }

  if (isLoading) return <PageLoader />
  if (!member) return null

  return (
    <>
      <PageHeader
        title={member.name}
        action={
          <div className="flex gap-2">
            <Link href={`/famille/${id}/modifier`}>
              <Button size="sm" variant="outline">
                <Pencil className="w-4 h-4 mr-1" /> Modifier
              </Button>
            </Link>
            <ConfirmDialog
              title="Supprimer le membre"
              description={`Supprimer "${member.name}" et toutes ses données ? Cette action est irréversible.`}
              onConfirm={handleDelete}
            >
              <Button size="sm" variant="destructive">
                <Trash2 className="w-4 h-4" />
              </Button>
            </ConfirmDialog>
          </div>
        }
      />

      <div className="p-4 lg:p-6 max-w-2xl mx-auto space-y-4">
        {/* Profile */}
        <div className="bg-card border border-border rounded-2xl p-5 shadow-card">
          <div className="flex items-center gap-4">
            <MemberAvatar name={member.name} avatarUrl={member.avatar_url} size="xl" />
            <div className="flex-1">
              <div className="flex items-center gap-2 flex-wrap">
                <h2 className="text-lg font-bold text-foreground">{member.name}</h2>
                {member.is_main && <Badge>Principal</Badge>}
              </div>
              {member.date_of_birth && (
                <p className="text-sm text-muted-foreground mt-0.5">{formatAge(member.date_of_birth)}</p>
              )}
              {member.blood_type && (
                <p className="text-sm text-muted-foreground">Groupe sanguin : <span className="font-medium text-foreground">{member.blood_type}</span></p>
              )}
            </div>
          </div>

          {member.allergies.length > 0 && (
            <div className="mt-4">
              <p className="text-xs font-medium text-muted-foreground mb-1.5">Allergies</p>
              <div className="flex flex-wrap gap-1.5">
                {member.allergies.map((a) => (
                  <span key={a} className="px-2.5 py-1 rounded-full bg-red-50 text-red-600 text-xs font-medium border border-red-100">{a}</span>
                ))}
              </div>
            </div>
          )}

          {member.medical_notes && (
            <div className="mt-4">
              <p className="text-xs font-medium text-muted-foreground mb-1">Antécédents</p>
              <p className="text-sm text-foreground">{member.medical_notes}</p>
            </div>
          )}
        </div>

        {/* Quick stats */}
        <div className="grid grid-cols-2 gap-3">
          {[
            { icon: Pill, label: 'Traitements actifs', count: activeTreatments.length, href: '/traitements', color: 'bg-primary-50 text-primary-500' },
            { icon: Activity, label: 'Traitements périodiques', count: periodics.length, href: '/periodiques', color: 'bg-orange-50 text-orange-500' },
            { icon: FileText, label: 'Antécédents', count: records.length, href: '/historique', color: 'bg-purple-50 text-purple-500' },
            { icon: Stethoscope, label: 'Constantes', count: vitals.length, href: '/constantes', color: 'bg-secondary-50 text-secondary-500' },
          ].map(({ icon: Icon, label, count, href, color }) => (
            <Link key={label} href={href}>
              <div className="bg-card border border-border rounded-2xl p-4 shadow-card hover:shadow-md transition-shadow flex items-center gap-3">
                <div className={`w-9 h-9 rounded-xl ${color} flex items-center justify-center flex-shrink-0`}>
                  <Icon className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-xl font-bold text-foreground">{count}</p>
                  <p className="text-xs text-muted-foreground leading-tight">{label}</p>
                </div>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </>
  )
}
