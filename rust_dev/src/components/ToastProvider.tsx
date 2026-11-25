import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import Toast from '@/components/arc/toast/toast'

type ShowToast = (title: string, description?: string) => void

const ToastContext = createContext<ShowToast>(() => {})

interface ToastState {
  id: number
  title: string
  description?: string
}

/**
 * 全局轻提示：操作成功/失败用 Toast 表达，不再往页面里塞一排提示文字。
 * 位置固定在底部导航上方，避免被遮挡。
 */
export function ToastProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<ToastState | null>(null)
  const [open, setOpen] = useState(false)

  const show = useCallback<ShowToast>((title, description) => {
    setState({ id: Date.now(), title, description })
    setOpen(true)
  }, [])

  // 关闭动画结束后再卸载节点
  useEffect(() => {
    if (open || !state) return
    const timer = window.setTimeout(() => setState(null), 320)
    return () => window.clearTimeout(timer)
  }, [open, state])

  const value = useMemo(() => show, [show])

  return (
    <ToastContext.Provider value={value}>
      {children}
      {state ? (
        <div className="toast-host" role="status" aria-live="polite">
          <Toast
            key={state.id}
            title={state.title}
            description={state.description}
            open={open}
            onOpenChange={setOpen}
          />
        </div>
      ) : null}
    </ToastContext.Provider>
  )
}

export function useToast(): ShowToast {
  return useContext(ToastContext)
}
