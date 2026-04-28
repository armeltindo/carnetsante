'use client'

import { use } from 'react'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import { PageHeader } from '@/components/layout/header'
import { MemberForm } from '@/components/family/member-form'
import { PageLoader } from '@/components/shared/loading'
import { useFamilyMember, useUpdateFamilyMember } from '@/lib/hooks/use-family-members'
import type { FamilyMember } from '@/lib/types'

export default function ModifierMembrePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const router = useRouter()
  const { data: member, isLoading } = useFamilyMember(id)
  const updateMember = useUpdateFamilyMember()

  const handleSubmit = async (data: Partial<FamilyMember>) => {
    await updateMember.mutateAsync({ id, data })
    toast.success('Membre mis à jour')
    router.push(`/famille/${id}`)
  }

  if (isLoading) return <PageLoader />
  if (!member) return null

  return (
    <>
      <PageHeader title="Modifier le membre" />
      <div className="p-4 lg:p-6 max-w-lg mx-auto">
        <div className="bg-card border border-border rounded-2xl p-5 shadow-card">
          <MemberForm
            defaultValues={member}
            onSubmit={handleSubmit}
            onCancel={() => router.back()}
          />
        </div>
      </div>
    </>
  )
}
