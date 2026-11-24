'use client'

import { TaskList } from '@/components/TaskList'
import { AuthScreen } from '@/components/AuthScreen'
import { useAuthStore } from '@/lib/auth-store'

export default function Home() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  
  if (!isAuthenticated) {
    return <AuthScreen />
  }
  
  return <TaskList />
}
