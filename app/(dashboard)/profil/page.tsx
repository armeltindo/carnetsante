'use client'

import { useState, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { Camera, LogOut, Trash2 } from 'lucide-react'
import { PageHeader } from '@/components/layout/header'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { MemberAvatar } from '@/components/family/member-avatar'
import { ConfirmDialog } from '@/components/shared/confirm-dialog'
import { useFamilyMembers, useUpdateFamilyMember, useDeleteFamilyMember } from '@/lib/hooks/use-family-members'
import { createClient } from '@/lib/supabase/client'

const passwordSchema = z.object({
  password: z.string().min(8, 'Minimum 8 caractères'),
  confirm: z.string(),
}).refine((d) => d.password === d.confirm, {
  message: 'Les mots de passe ne correspondent pas',
  path: ['confirm'],
})

type PasswordForm = z.infer<typeof passwordSchema>

export default function ProfilPage() {
  const router = useRouter()
  const supabase = createClient()
  const { data: members = [] } = useFamilyMembers()
  const updateMember = useUpdateFamilyMember()
  const deleteMember = useDeleteFamilyMember()
  const mainMember = members.find((m) => m.is_main) || members[0]

  const [uploadingFor, setUploadingFor] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [targetMemberId, setTargetMemberId] = useState<string>('')

  const { register, handleSubmit, reset, formState: { errors } } = useForm<PasswordForm>({
    resolver: zodResolver(passwordSchema),
  })

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  const triggerAvatarUpload = (memberId: string) => {
    setTargetMemberId(memberId)
    fileInputRef.current?.click()
  }

  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file || !targetMemberId) return

    setUploadingFor(targetMemberId)
    try {
      const { data: { user } } = await supabase.auth.getUser()
      const ext = file.name.split('.').pop()
      const path = `avatars/${user!.id}/${targetMemberId}.${ext}`

      const { error: uploadError } = await supabase.storage
        .from('medical-documents')
        .upload(path, file, { upsert: true, contentType: file.type })
      if (uploadError) throw uploadError

      const { data } = await supabase.storage
        .from('medical-documents')
        .createSignedUrl(path, 60 * 60 * 24 * 365)

      await updateMember.mutateAsync({
        id: targetMemberId,
        data: { avatar_url: data?.signedUrl || null },
      })
      toast.success('Photo mise à jour')
    } catch (err) {
      toast.error('Erreur lors du téléversement')
    } finally {
      setUploadingFor(null)
      if (fileInputRef.current) fileInputRef.current.value = ''
    }
  }

  const handlePasswordChange = async (data: PasswordForm) => {
    const { error } = await supabase.auth.updateUser({ password: data.password })
    if (error) {
      toast.error(error.message)
      return
    }
    toast.success('Mot de passe mis à jour')
    reset()
  }

  return (
    <>
      <PageHeader title="Mon profil" />

      <div className="p-4 lg:p-6 max-w-lg mx-auto space-y-5">
        {/* Avatars des membres */}
        <div className="bg-card border border-border rounded-2xl p-5 shadow-card">
          <h2 className="font-semibold text-foreground mb-4">Photos des membres</h2>
          <div className="space-y-3">
            {members.map((m) => (
              <div key={m.id} className="flex items-center gap-4">
                <div className="relative">
                  <MemberAvatar name={m.name} avatarUrl={m.avatar_url} size="lg" />
                  <button
                    onClick={() => triggerAvatarUpload(m.id)}
                    disabled={uploadingFor === m.id}
                    className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-primary-500 text-white flex items-center justify-center shadow-sm hover:bg-primary-600 transition-colors disabled:opacity-50"
                  >
                    <Camera className="w-3 h-3" />
                  </button>
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-foreground">{m.name}</p>
                  {m.is_main && <p className="text-xs text-muted-foreground">Membre principal</p>}
                </div>
                {uploadingFor === m.id && (
                  <p className="text-xs text-primary-600 animate-pulse">Upload...</p>
                )}
              </div>
            ))}
          </div>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleAvatarChange}
          />
        </div>

        {/* Changer mot de passe */}
        <div className="bg-card border border-border rounded-2xl p-5 shadow-card">
          <h2 className="font-semibold text-foreground mb-4">Changer le mot de passe</h2>
          <form onSubmit={handleSubmit(handlePasswordChange)} className="space-y-3">
            <Input
              label="Nouveau mot de passe"
              type="password"
              placeholder="Minimum 8 caractères"
              error={errors.password?.message}
              {...register('password')}
            />
            <Input
              label="Confirmer le mot de passe"
              type="password"
              placeholder="••••••••"
              error={errors.confirm?.message}
              {...register('confirm')}
            />
            <Button type="submit" className="w-full">Mettre à jour</Button>
          </form>
        </div>

        {/* Déconnexion */}
        <div className="bg-card border border-border rounded-2xl p-5 shadow-card space-y-3">
          <h2 className="font-semibold text-foreground">Compte</h2>
          <Button
            variant="outline"
            className="w-full text-muted-foreground"
            onClick={handleLogout}
          >
            <LogOut className="w-4 h-4 mr-2" /> Se déconnecter
          </Button>
        </div>
      </div>
    </>
  )
}
