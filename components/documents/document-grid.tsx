'use client'

import { useState, useRef } from 'react'
import { FileText, Image, Download, Trash2, Upload, Eye } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { ConfirmDialog } from '@/components/shared/confirm-dialog'
import { EmptyState } from '@/components/shared/empty-state'
import { formatDate } from '@/lib/utils/date'
import type { Document } from '@/lib/types'

interface DocumentGridProps {
  documents: Document[]
  onUpload?: (file: File, memberId: string) => Promise<void>
  onDelete?: (doc: Document) => Promise<void>
  memberId?: string
  uploading?: boolean
}

function isImage(mimeType: string) {
  return mimeType.startsWith('image/')
}

function formatFileSize(bytes: number) {
  if (bytes < 1024) return `${bytes} o`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} Ko`
  return `${(bytes / (1024 * 1024)).toFixed(1)} Mo`
}

function DocumentCard({ doc, onDelete }: { doc: Document; onDelete?: (doc: Document) => Promise<void> }) {
  const img = isImage(doc.mime_type || '')

  return (
    <div className="bg-card border border-border rounded-2xl overflow-hidden shadow-card group">
      {/* Preview */}
      <div className="h-32 bg-muted flex items-center justify-center relative">
        {img && doc.url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={doc.url} alt={doc.name} className="w-full h-full object-cover" />
        ) : (
          <FileText className="w-10 h-10 text-muted-foreground" />
        )}
        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors flex items-center justify-center gap-2 opacity-0 group-hover:opacity-100">
          {doc.url && (
            <a href={doc.url} target="_blank" rel="noopener noreferrer">
              <Button size="icon-sm" variant="secondary">
                <Eye className="w-3.5 h-3.5" />
              </Button>
            </a>
          )}
          {doc.url && (
            <a href={doc.url} download={doc.name}>
              <Button size="icon-sm" variant="secondary">
                <Download className="w-3.5 h-3.5" />
              </Button>
            </a>
          )}
        </div>
      </div>

      {/* Info */}
      <div className="p-3">
        <p className="text-sm font-medium text-foreground truncate">{doc.name}</p>
        <div className="flex items-center justify-between mt-1">
          <p className="text-xs text-muted-foreground">{formatDate(doc.created_at)}</p>
          {doc.size && <p className="text-xs text-muted-foreground">{formatFileSize(doc.size)}</p>}
        </div>
        {onDelete && (
          <ConfirmDialog
            title="Supprimer le document"
            description={`Supprimer "${doc.name}" ? Cette action est irréversible.`}
            onConfirm={() => onDelete(doc)}
          >
            <Button variant="ghost" size="sm" className="mt-2 w-full text-destructive hover:text-destructive hover:bg-red-50">
              <Trash2 className="w-3.5 h-3.5 mr-1.5" /> Supprimer
            </Button>
          </ConfirmDialog>
        )}
      </div>
    </div>
  )
}

export function DocumentGrid({ documents, onUpload, onDelete, memberId, uploading }: DocumentGridProps) {
  const inputRef = useRef<HTMLInputElement>(null)

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file || !memberId || !onUpload) return
    await onUpload(file, memberId)
    if (inputRef.current) inputRef.current.value = ''
  }

  return (
    <div className="space-y-4">
      {onUpload && memberId && (
        <div>
          <input
            ref={inputRef}
            type="file"
            className="hidden"
            accept=".pdf,.jpg,.jpeg,.png,.webp,.doc,.docx"
            onChange={handleFileChange}
          />
          <Button
            variant="outline"
            onClick={() => inputRef.current?.click()}
            loading={uploading}
            className="w-full border-dashed"
          >
            <Upload className="w-4 h-4 mr-2" />
            Ajouter un document
          </Button>
        </div>
      )}

      {documents.length === 0 ? (
        <EmptyState
          icon={FileText}
          title="Aucun document"
          description="Ajoutez des ordonnances, résultats d'analyses ou comptes-rendus."
        />
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
          {documents.map((doc) => (
            <DocumentCard key={doc.id} doc={doc} onDelete={onDelete} />
          ))}
        </div>
      )}
    </div>
  )
}
