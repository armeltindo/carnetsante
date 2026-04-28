'use client'

import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import { PageHeader } from '@/components/layout/header'
import { MemberForm } from '@/components/family/member-form'
import { useCreateFamilyMember } from '@/lib/hooks/use-family-members'
import type { FamilyMember } from '@/lib/types'

export default function NouveauMembrePage() {
  const router = useRouter()
  const createMember = useCreateFamilyMember()

  const handleSubmit = async (data: Partial<FamilyMember>) => {
    await createMember.mutateAsync(data)
    toast.success('Membre ajouté')
    router.push('/famille')
  }

  return (
    <>
      <PageHeader title="Nouveau membre" />
      <div className="p-4 lg:p-6 max-w-lg mx-auto">
        <div className="bg-card border border-border rounded-2xl p-5 shadow-card">
          <MemberForm onSubmit={handleSubmit} onCancel={() => router.back()} />
        </div>
      </div>
    </>
  )
}
