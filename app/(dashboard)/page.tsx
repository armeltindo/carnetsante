'use client'

import { useMemo } from 'react'
import Link from 'next/link'
import { Users, Pill, Activity, FileText, Stethoscope, ArrowRight, AlertCircle, Clock } from 'lucide-react'
import { PageHeader } from '@/components/layout/header'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { MemberAvatar } from '@/components/family/member-avatar'
import { SkeletonCard } from '@/components/shared/loading'
import { useFamilyMembers } from '@/lib/hooks/use-family-members'
import { useTreatments, usePeriodicTreatments } from '@/lib/hooks/use-treatments'
import { useMedicalRecords } from '@/lib/hooks/use-vitals'
import { formatDaysUntil, isOverdue, isDueSoon } from '@/lib/utils/date'

function StatCard({ label, value, icon: Icon, href, color }: {
  label: string; value: number; icon: React.ElementType; href: string; color: string
}) {
  return (
    <Link href={href}>
      <Card className="hover:shadow-md transition-shadow cursor-pointer">
        <CardContent className="p-4 flex items-center gap-3">
          <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${color}`}>
            <Icon className="w-5 h-5" />
          </div>
          <div>
            <p className="text-2xl font-bold text-foreground">{value}</p>
            <p className="text-xs text-muted-foreground">{label}</p>
          </div>
        </CardContent>
      </Card>
    </Link>
  )
}

export default function DashboardPage() {
  const { data: members = [], isLoading: loadingMembers } = useFamilyMembers()
  const { data: treatments = [], isLoading: loadingTreatments } = useTreatments()
  const { data: periodics = [], isLoading: loadingPeriodics } = usePeriodicTreatments()
  const { data: records = [], isLoading: loadingRecords } = useMedicalRecords()

  const activeTreatments = useMemo(() => treatments.filter((t) => t.is_active), [treatments])

  const urgentPeriodics = useMemo(
    () => periodics.filter((p) => p.next_date && (isOverdue(p.next_date) || isDueSoon(p.next_date))),
    [periodics]
  )

  const isLoading = loadingMembers || loadingTreatments || loadingPeriodics || loadingRecords

  return (
    <>
      <PageHeader title="Tableau de bord" description="Vue d'ensemble de la santé familiale" />

      <div className="p-4 lg:p-6 space-y-6 max-w-2xl mx-auto lg:max-w-none">
        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {isLoading ? (
            Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)
          ) : (
            <>
              <StatCard label="Membres" value={members.length} icon={Users} href="/famille" color="bg-primary-50 text-primary-500" />
              <StatCard label="Traitements actifs" value={activeTreatments.length} icon={Pill} href="/traitements" color="bg-secondary-50 text-secondary-500" />
              <StatCard label="Traitements périodiques" value={periodics.length} icon={Activity} href="/periodiques" color="bg-orange-50 text-orange-500" />
              <StatCard label="Antécédents" value={records.length} icon={FileText} href="/historique" color="bg-purple-50 text-purple-500" />
            </>
          )}
        </div>

        {/* Périodiques urgents */}
        {urgentPeriodics.length > 0 && (
          <div>
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-bold text-foreground flex items-center gap-2">
                <AlertCircle className="w-4 h-4 text-orange-500" />
                Traitements périodiques à faire
              </h2>
              <Link href="/periodiques" className="text-xs text-primary-600 font-medium flex items-center gap-0.5">
                Voir tout <ArrowRight className="w-3 h-3" />
              </Link>
            </div>
            <div className="space-y-2">
              {urgentPeriodics.slice(0, 3).map((p) => {
                const member = members.find((m) => m.id === p.family_member_id)
                const overdue = isOverdue(p.next_date!)
                return (
                  <Link key={p.id} href="/periodiques">
                    <Card className="hover:shadow-md transition-shadow">
                      <CardContent className="p-3 flex items-center gap-3">
                        <div className={`w-2 h-2 rounded-full flex-shrink-0 ${overdue ? 'bg-red-500' : 'bg-orange-400'}`} />
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-foreground truncate">{p.treatment_name}</p>
                          {member && <p className="text-xs text-muted-foreground">{member.name}</p>}
                        </div>
                        <Badge variant={overdue ? 'destructive' : 'warning'}>
                          {formatDaysUntil(p.next_date!)}
                        </Badge>
                      </CardContent>
                    </Card>
                  </Link>
                )
              })}
            </div>
          </div>
        )}

        {/* Membres de la famille */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-bold text-foreground">Ma famille</h2>
            <Link href="/famille" className="text-xs text-primary-600 font-medium flex items-center gap-0.5">
              Gérer <ArrowRight className="w-3 h-3" />
            </Link>
          </div>
          {loadingMembers ? (
            <SkeletonCard />
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {members.slice(0, 4).map((m) => (
                <Link key={m.id} href={`/famille/${m.id}`}>
                  <Card className="hover:shadow-md transition-shadow cursor-pointer">
                    <CardContent className="p-3 flex items-center gap-3">
                      <MemberAvatar name={m.name} avatarUrl={m.avatar_url} size="md" />
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-foreground truncate">{m.name}</p>
                        {m.blood_type && <p className="text-xs text-muted-foreground">Groupe {m.blood_type}</p>}
                      </div>
                      {m.is_main && <Badge variant="default">Principal</Badge>}
                    </CardContent>
                  </Card>
                </Link>
              ))}
              <Link href="/famille/nouveau">
                <Card className="border-dashed hover:shadow-md transition-shadow cursor-pointer">
                  <CardContent className="p-3 flex items-center gap-3 text-muted-foreground">
                    <div className="w-10 h-10 rounded-full border-2 border-dashed border-border flex items-center justify-center">
                      <Users className="w-4 h-4" />
                    </div>
                    <p className="text-sm">Ajouter un membre</p>
                  </CardContent>
                </Card>
              </Link>
            </div>
          )}
        </div>

        {/* Traitements actifs */}
        {activeTreatments.length > 0 && (
          <div>
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-bold text-foreground flex items-center gap-2">
                <Pill className="w-4 h-4 text-primary-500" />
                Traitements en cours
              </h2>
              <Link href="/traitements" className="text-xs text-primary-600 font-medium flex items-center gap-0.5">
                Voir tout <ArrowRight className="w-3 h-3" />
              </Link>
            </div>
            <div className="space-y-2">
              {activeTreatments.slice(0, 3).map((t) => {
                const member = members.find((m) => m.id === t.family_member_id)
                return (
                  <Card key={t.id}>
                    <CardContent className="p-3 flex items-center gap-3">
                      <div className="w-8 h-8 rounded-lg bg-primary-50 flex items-center justify-center">
                        <Pill className="w-4 h-4 text-primary-500" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-foreground truncate">{t.medication_name}</p>
                        <p className="text-xs text-muted-foreground">{t.frequency || member?.name}</p>
                      </div>
                      <Badge variant="success">Actif</Badge>
                    </CardContent>
                  </Card>
                )
              })}
            </div>
          </div>
        )}
      </div>
    </>
  )
}
