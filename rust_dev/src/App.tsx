import { NavProvider, useNav } from '@/app/navigation'
import { ToastProvider } from '@/components/ToastProvider'
import { HomePage } from '@/features/home/HomePage'
import { LensDetailPage } from '@/features/lens/LensDetailPage'
import { LensFormPage } from '@/features/lens/LensFormPage'
import { ExpiringPage } from '@/features/lens/ExpiringPage'
import { SettingsPage } from '@/features/settings/SettingsPage'
import { NotificationPage } from '@/features/settings/NotificationPage'
import { ReminderSettingsPage } from '@/features/settings/ReminderSettingsPage'
import { CareSolutionPage } from '@/features/settings/CareSolutionPage'
import { CyclePage } from '@/features/settings/CyclePage'
import { UpdatePage } from '@/features/settings/UpdatePage'
import { DataPage } from '@/features/settings/DataPage'

function CurrentPage() {
  const { route } = useNav()

  switch (route.name) {
    case 'home':
      return <HomePage />
    case 'settings':
      return <SettingsPage />
    case 'lens':
      return <LensDetailPage id={route.id} key={`lens-${route.id}`} />
    case 'lens-form':
      return <LensFormPage id={route.id} key={`form-${route.id ?? 'new'}`} />
    case 'expiring':
      return <ExpiringPage />
    case 'notifications':
      return <NotificationPage />
    case 'reminders':
      return <ReminderSettingsPage />
    case 'care':
      return <CareSolutionPage />
    case 'cycles':
      return <CyclePage />
    case 'update':
      return <UpdatePage />
    case 'data':
      return <DataPage />
    default:
      return <HomePage />
  }
}

export default function App() {
  return (
    <NavProvider>
      <ToastProvider>
        <CurrentPage />
      </ToastProvider>
    </NavProvider>
  )
}
