'use client'

import { useState } from 'react'
import { toast } from 'sonner'
import { PageHeader } from '@/components/layout/header'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { DocumentGrid } from '@/components/documents/document-grid'
import { SkeletonList } from '@/components/shared/loading'
import { useDocuments, useUploadDocument, useDeleteDocument } from '@/lib/hooks/use-vitals'
import { useFamilyMembers } from '@/lib/hooks/use-family-members'
import type { Document } from '@/lib/types'

export default function DocumentsPage() {
  const [selectedMember, setSelectedMember] = useState<string>('')
  const { data: members = [], isLoading: loadingMembers } = useFamilyMembers()

  const mainMember = members.find((m) => m.is_main) || members[0]
  const memberId = selectedMember || mainMember?.id || ''

  const { data: documents = [], isLoading } = useDocuments(memberId)
  const upload = useUploadDocument()
  const remove = useDeleteDocument()

  const handleUpload = async (file: File, mid: string) => {
    try {
      await upload.mutateAsync({ file, memberId: mid })
      toast.success('Document ajouté')
    } catch {
      toast.error('Erreur lors du téléversement')
    }
  }

  const handleDelete = async (doc: Document) => {
    await remove.mutateAsync({ id: doc.id, storagePath: doc.storage_path })
    toast.success('Document supprimé')
  }

  return (
    <>
      <PageHeader title="Documents médicaux" description="Ordonnances, analyses, comptes-rendus" />

      <div className="p-4 lg:p-6 max-w-2xl mx-auto space-y-4">
        {!loadingMembers && members.length > 1 && (
          <Select value={memberId} onValueChange={setSelectedMember}>
            <SelectTrigger>
              <SelectValue placeholder="Sélectionner un membre" />
            </SelectTrigger>
            <SelectContent>
              {members.map((m) => <SelectItem key={m.id} value={m.id}>{m.name}</SelectItem>)}
            </SelectContent>
          </Select>
        )}

        {isLoading ? (
          <SkeletonList count={4} />
        ) : (
          <DocumentGrid
            documents={documents}
            onUpload={handleUpload}
            onDelete={handleDelete}
            memberId={memberId}
            uploading={upload.isPending}
          />
        )}
      </div>
    </>
  )
}
