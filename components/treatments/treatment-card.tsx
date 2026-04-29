'use client'

import { Pill, Clock, User, MoreVertical, Pencil, Trash2, CheckCircle, XCircle } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { ConfirmDialog } from '@/components/shared/confirm-dialog'
import { formatDate, formatShortDate } from '@/lib/utils/date'
import type { Treatment } from '@/lib/types'

interface TreatmentCardProps {
  treatment: Treatment
  memberName?: string
  onEdit?: (treatment: Treatment) => void
  onDelete?: (id: string) => Promise<void>
  onToggleActive?: (treatment: Treatment) => Promise<void>
}

export function TreatmentCard({ treatment, memberName, onEdit, onDelete, onToggleActive }: TreatmentCardProps) {
  return (
    <div className="bg-card rounded-2xl border border-border p-4 shadow-card">
      <div className="flex items-start gap-3">
        <div className="w-10 h-10 rounded-xl bg-primary-50 flex items-center justify-center flex-shrink-0">
          <Pill className="w-5 h-5 text-primary-500" />
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0">
              <h3 className="font-semibold text-foreground truncate">{treatment.medication_name}</h3>
              {treatment.dosage && (
                <p className="text-sm text-muted-foreground">{treatment.dosage}</p>
              )}
            </div>
            <div className="flex items-center gap-1.5 flex-shrink-0">
              <Badge variant={treatment.is_active ? 'success' : 'secondary'}>
                {treatment.is_active ? 'Actif' : 'Terminé'}
              </Badge>
              {(onEdit || onDelete || onToggleActive) && (
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="icon-sm">
                      <MoreVertical className="w-4 h-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    {onToggleActive && (
                      <DropdownMenuItem onClick={() => onToggleActive(treatment)}>
                        {treatment.is_active ? (
                          <><XCircle className="w-4 h-4 mr-2 text-muted-foreground" /> Marquer terminé</>
                        ) : (
                          <><CheckCircle className="w-4 h-4 mr-2 text-success-500" /> Réactiver</>
                        )}
                      </DropdownMenuItem>
                    )}
                    {onEdit && (
                      <DropdownMenuItem onClick={() => onEdit(treatment)}>
                        <Pencil className="w-4 h-4 mr-2 text-muted-foreground" /> Modifier
                      </DropdownMenuItem>
                    )}
                    {onDelete && (
                      <ConfirmDialog
                        title="Supprimer le traitement"
                        description={`Supprimer "${treatment.medication_name}" ? Cette action est irréversible.`}
                        onConfirm={() => onDelete(treatment.id)}
                      >
                        <DropdownMenuItem onSelect={(e) => e.preventDefault()} className="text-destructive focus:text-destructive">
                          <Trash2 className="w-4 h-4 mr-2" /> Supprimer
                        </DropdownMenuItem>
                      </ConfirmDialog>
                    )}
                  </DropdownMenuContent>
                </DropdownMenu>
              )}
            </div>
          </div>

          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
            {treatment.frequency && (
              <span className="flex items-center gap-1">
                <Clock className="w-3.5 h-3.5" />
                {treatment.frequency}
              </span>
            )}
            {memberName && (
              <span className="flex items-center gap-1">
                <User className="w-3.5 h-3.5" />
                {memberName}
              </span>
            )}
          </div>

          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
            <span>Début : {formatShortDate(treatment.start_date)}</span>
            {treatment.end_date && (
              <span>Fin : {formatShortDate(treatment.end_date)}</span>
            )}
          </div>

          {treatment.instructions && (
            <p className="mt-2 text-xs text-muted-foreground line-clamp-2">{treatment.instructions}</p>
          )}
        </div>
      </div>
    </div>
  )
}
