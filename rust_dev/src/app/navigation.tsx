/**
 * 轻量导航栈：只有「首页 / 我的」两个主 Tab，其余页面都是压栈的二级页面。
 * 不引入路由库，但导航栈与 WebView 的 History API 保持同步：
 * 安卓的返回手势 / 返回键走的是 WebView 历史（WryActivity 里 canGoBack → goBack），
 * 历史为空时原生会直接结束 Activity。不同步的话，用户从屏幕边缘滑动会直接退出应用。
 */
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
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
  | { name: 'data' }

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

/** History state 的标记字段，用来区分「我们压入的历史」和初始条目 */
const STATE_FLAG = 'mm-route'

export function NavProvider({ children }: { children: ReactNode }) {
  const [stack, setStack] = useState<Route[]>([{ name: 'home' }])
  const [version, setVersion] = useState(0)

  // 原生返回（goBack）触发的 popstate 是唯一的弹栈入口，
  // 应用内返回按钮同样通过 history.back() 走这条路，保证两侧行为一致
  useEffect(() => {
    const onPop = () => {
      setStack((prev) => (prev.length > 1 ? prev.slice(0, -1) : prev))
    }
    window.addEventListener('popstate', onPop)
    return () => window.removeEventListener('popstate', onPop)
  }, [])

  const push = useCallback((route: Route) => {
    history.pushState({ [STATE_FLAG]: route.name }, '')
    setStack((prev) => [...prev, route])
  }, [])

  const replace = useCallback((route: Route) => {
    history.replaceState({ [STATE_FLAG]: route.name }, '')
    setStack((prev) => [...prev.slice(0, -1), route])
  }, [])

  const back = useCallback(() => {
    // 当前历史条目是我们压入的 → 交给 popstate 弹栈；
    // 已经在初始条目（栈底）时不再回退，避免把历史退穿
    if (history.state?.[STATE_FLAG] !== undefined) {
      history.back()
    } else {
      setStack((prev) => (prev.length > 1 ? prev.slice(0, -1) : prev))
    }
  }, [])

  const switchTab = useCallback((tab: Tab) => {
    // 切换主 Tab 不新增历史（replaceState），返回手势仍然回到上一条
    history.replaceState({ [STATE_FLAG]: tab }, '')
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
