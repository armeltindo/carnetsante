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
  password: z.string().min(6, 'Mot de passe trop court'),
})

type FormData = z.infer<typeof schema>

export default function LoginPage() {
  const router = useRouter()
  const [loading, setLoading] = useState(false)

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: FormData) => {
    setLoading(true)
    const supabase = createClient()
    const { error } = await supabase.auth.signInWithPassword(data)
    if (error) {
      toast.error('Identifiants invalides')
      setLoading(false)
      return
    }
    router.push('/')
    router.refresh()
  }

  return (
    <div className="bg-card rounded-3xl border border-border shadow-card p-6 space-y-5">
      <div className="text-center">
        <h1 className="text-xl font-bold text-foreground">Connexion</h1>
        <p className="text-sm text-muted-foreground mt-1">Accédez à votre carnet de santé</p>
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
          placeholder="••••••••"
          error={errors.password?.message}
          {...register('password')}
        />
        <Button type="submit" loading={loading} className="w-full">
          Se connecter
        </Button>
      </form>

      <p className="text-center text-sm text-muted-foreground">
        Pas encore de compte ?{' '}
        <Link href="/register" className="text-primary-600 font-medium hover:underline">
          Créer un compte
        </Link>
      </p>
    </div>
  )
}
