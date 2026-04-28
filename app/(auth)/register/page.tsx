'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

const schema = z.object({
  email: z.string().email('Email invalide'),
  password: z.string().min(8, 'Minimum 8 caractères'),
  confirmPassword: z.string(),
}).refine((d) => d.password === d.confirmPassword, {
  message: 'Les mots de passe ne correspondent pas',
  path: ['confirmPassword'],
})

type FormData = z.infer<typeof schema>

export default function RegisterPage() {
  const router = useRouter()
  const [loading, setLoading] = useState(false)

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: FormData) => {
    setLoading(true)
    const supabase = createClient()
    const { error } = await supabase.auth.signUp({
      email: data.email,
      password: data.password,
    })
    if (error) {
      toast.error(error.message)
      setLoading(false)
      return
    }
    toast.success('Compte créé ! Vérifiez votre email.')
    router.push('/login')
  }

  return (
    <div className="bg-card rounded-3xl border border-border shadow-card p-6 space-y-5">
      <div className="text-center">
        <h1 className="text-xl font-bold text-foreground">Créer un compte</h1>
        <p className="text-sm text-muted-foreground mt-1">Commencez votre carnet de santé familial</p>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <Input
          label="Email"
          type="email"
          placeholder="jean@exemple.fr"
          error={errors.email?.message}
          {...register('email')}
        />
        <Input
          label="Mot de passe"
          type="password"
          placeholder="Minimum 8 caractères"
          error={errors.password?.message}
          {...register('password')}
        />
        <Input
          label="Confirmer le mot de passe"
          type="password"
          placeholder="••••••••"
          error={errors.confirmPassword?.message}
          {...register('confirmPassword')}
        />
        <Button type="submit" loading={loading} className="w-full">
          Créer mon compte
        </Button>
      </form>

      <p className="text-center text-sm text-muted-foreground">
        Déjà un compte ?{' '}
        <Link href="/login" className="text-primary-600 font-medium hover:underline">
          Se connecter
        </Link>
      </p>
    </div>
  )
}
