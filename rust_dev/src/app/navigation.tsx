/**
 * 轻量导航栈：只有「首页 / 我的」两个主 Tab，其余页面都是压栈的二级页面。
 * 不引入路由库，避免在 Tauri 移动端出现 URL/历史栈不一致的问题。
 */
import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react'

export type Tab = 'home' | 'settings'

export type Route =
  | { name: 'home' }
  | { name: 'settings' }
  | { name: 'lens'; id: number }
  | { name: 'lens-form'; id?: number }
  | { name: 'expiring' }
  | { name: 'notifications' }
  | { name: 'reminders' }
  | { name: 'care' }
  | { name: 'cycles' }
  | { name: 'update' }

interface NavValue {
  route: Route
  tab: Tab
  canBack: boolean
  version: number
  push: (route: Route) => void
  replace: (route: Route) => void
  back: () => void
  switchTab: (tab: Tab) => void
  /** 数据变更后调用，让已挂载的页面重新拉取数据 */
  refresh: () => void
}

const NavContext = createContext<NavValue | null>(null)

export function NavProvider({ children }: { children: ReactNode }) {
  const [stack, setStack] = useState<Route[]>([{ name: 'home' }])
  const [version, setVersion] = useState(0)

  const push = useCallback((route: Route) => {
    setStack((prev) => [...prev, route])
  }, [])

  const replace = useCallback((route: Route) => {
    setStack((prev) => [...prev.slice(0, -1), route])
  }, [])

  const back = useCallback(() => {
    setStack((prev) => (prev.length > 1 ? prev.slice(0, -1) : prev))
  }, [])

  const switchTab = useCallback((tab: Tab) => {
    setStack([{ name: tab }])
  }, [])

  const refresh = useCallback(() => setVersion((value) => value + 1), [])

  const route = stack[stack.length - 1]
  const tab: Tab = route.name === 'settings' ? 'settings' : 'home'

  const value = useMemo<NavValue>(
    () => ({
      route,
      tab,
      canBack: stack.length > 1,
      version,
      push,
      replace,
      back,
      switchTab,
      refresh,
    }),
    [route, tab, stack.length, version, push, replace, back, switchTab, refresh],
  )

  return <NavContext.Provider value={value}>{children}</NavContext.Provider>
}

export function useNav(): NavValue {
  const value = useContext(NavContext)
  if (!value) throw new Error('useNav 必须在 NavProvider 内使用')
  return value
}
