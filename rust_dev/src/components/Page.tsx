import { ArrowLeft, Home, UserRound } from 'lucide-react'
import type { ReactNode } from 'react'
import { useNav } from '@/app/navigation'

interface PageProps {
  title: string
  subtitle?: string
  /** 大标题样式（首页 / 我的），二级页面用普通标题 + 返回按钮 */
  hero?: boolean
  actions?: ReactNode
  children: ReactNode
  /** 是否显示底部主导航（只有两个主页面需要） */
  tabBar?: boolean
  padded?: boolean
}

export function Page({
  title,
  subtitle,
  hero = false,
  actions,
  children,
  tabBar = false,
  padded = true,
}: PageProps) {
  const { canBack, back, tab, switchTab } = useNav()

  return (
    <div className="app-shell">
      {hero ? (
        <div className="page-top">
          <div className="hero-title" style={{ flex: 1 }}>
            <h1>{title}</h1>
            {subtitle ? <p>{subtitle}</p> : null}
          </div>
          {actions}
        </div>
      ) : (
        <div className="page-top">
          {canBack ? (
            <button className="icon-button" onClick={back} aria-label="返回">
              <ArrowLeft size={20} strokeWidth={1.9} />
            </button>
          ) : null}
          <h1>{title}</h1>
          {actions}
        </div>
      )}

      <div
        className={`app-scroll page-enter ${tabBar ? '' : 'no-tabbar'}`}
        style={padded ? undefined : { paddingLeft: 0, paddingRight: 0 }}
      >
        {children}
      </div>

      {tabBar ? (
        <nav className="tabbar" aria-label="主导航">
          <button
            className={`tab ${tab === 'home' ? 'active' : ''}`}
            onClick={() => switchTab('home')}
            aria-current={tab === 'home' ? 'page' : undefined}
          >
            <span className="tab-dot" aria-hidden="true" />
            <Home size={20} strokeWidth={tab === 'home' ? 2.2 : 1.8} />
            首页
          </button>
          <button
            className={`tab ${tab === 'settings' ? 'active' : ''}`}
            onClick={() => switchTab('settings')}
            aria-current={tab === 'settings' ? 'page' : undefined}
          >
            <span className="tab-dot" aria-hidden="true" />
            <UserRound size={20} strokeWidth={tab === 'settings' ? 2.2 : 1.8} />
            我的
          </button>
        </nav>
      ) : null}
    </div>
  )
}
