'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Plus, Users } from 'lucide-react'
import { PageHeader } from '@/components/layout/header'
import { Button } from '@/components/ui/button'
import { MemberAvatar } from '@/components/family/member-avatar'
import { Badge } from '@/components/ui/badge'
import { EmptyState } from '@/components/shared/empty-state'
import { SkeletonList } from '@/components/shared/loading'
import { useFamilyMembers } from '@/lib/hooks/use-family-members'
import { formatAge } from '@/lib/utils/date'
import { ChevronRight } from 'lucide-react'

export default function FamillePage() {
  const { data: members = [], isLoading } = useFamilyMembers()

  return (
    <>
      <PageHeader
        title="Ma famille"
        description={`${members.length} membre${members.length !== 1 ? 's' : ''}`}
        action={
          <Link href="/famille/nouveau">
            <Button size="sm">
              <Plus className="w-4 h-4 mr-1" /> Ajouter
            </Button>
          </Link>
        }
      />

      <div className="p-4 lg:p-6 max-w-2xl mx-auto">
        {isLoading ? (
          <SkeletonList count={3} />
        ) : members.length === 0 ? (
          <EmptyState
            icon={Users}
            title="Aucun membre"
            description="Ajoutez les membres de votre famille pour gérer leur santé."
            action={
              <Link href="/famille/nouveau">
                <Button><Plus className="w-4 h-4 mr-2" /> Ajouter un membre</Button>
              </Link>
            }
          />
        ) : (
          <div className="space-y-3">
            {members.map((m) => (
              <Link key={m.id} href={`/famille/${m.id}`}>
                <div className="bg-card border border-border rounded-2xl p-4 flex items-center gap-4 shadow-card hover:shadow-md transition-shadow cursor-pointer">
                  <MemberAvatar name={m.name} avatarUrl={m.avatar_url} size="lg" />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <h3 className="font-semibold text-foreground truncate">{m.name}</h3>
                      {m.is_main && <Badge variant="default">Principal</Badge>}
                    </div>
                    <div className="flex flex-wrap gap-x-3 gap-y-0.5 mt-0.5">
                      {m.date_of_birth && (
                        <span className="text-xs text-muted-foreground">{formatAge(m.date_of_birth)}</span>
                      )}
                      {m.blood_type && (
                        <span className="text-xs text-muted-foreground">Groupe {m.blood_type}</span>
                      )}
                      {m.allergies.length > 0 && (
                        <span className="text-xs text-destructive-500">{m.allergies.length} allergie{m.allergies.length > 1 ? 's' : ''}</span>
                      )}
                    </div>
                  </div>
                  <ChevronRight className="w-4 h-4 text-muted-foreground flex-shrink-0" />
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </>
  )
}
