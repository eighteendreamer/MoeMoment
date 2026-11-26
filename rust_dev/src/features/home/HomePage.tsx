import { useCallback, useEffect, useMemo, useState } from 'react'
import { Plus, SlidersHorizontal } from 'lucide-react'
import { Page } from '@/components/Page'
import { Button } from '@/components/arc/button/button'
import { Dialog, DialogContent } from '@/components/arc/dialog/dialog'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { useNav } from '@/app/navigation'
import { api, imageUrl } from '@/lib/api'
import { cycleText, formatDate, remainingText, todayISO } from '@/lib/format'
import type { Cycle, HomeOverview, Lens, LensState } from '@/lib/types'

const STATE_FILTERS: { value: LensState | 'all'; label: string }[] = [
  { value: 'all', label: '全部' },
  { value: 'in_use', label: '使用中' },
  { value: 'unopened', label: '未开封' },
  { value: 'expired', label: '已过期' },
  { value: 'discarded', label: '已丢弃' },
]

interface FilterState {
  state: LensState | 'all'
  cycleId: number | 'all'
  color: string | null
}

const EMPTY_FILTER: FilterState = { state: 'all', cycleId: 'all', color: null }

export function HomePage() {
  const { push, version, refresh } = useNav()
  const [overview, setOverview] = useState<HomeOverview | null>(null)
  const [lenses, setLenses] = useState<Lens[]>([])
  const [cycles, setCycles] = useState<Cycle[]>([])
  const [colors, setColors] = useState<string[]>([])
  const [keyword, setKeyword] = useState('')
  const [filters, setFilters] = useState<FilterState>(EMPTY_FILTER)
  const [draft, setDraft] = useState<FilterState>(EMPTY_FILTER)
  const [filterOpen, setFilterOpen] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [action, setAction] = useState<{ kind: 'discard' | 'open'; lens: Lens } | null>(null)
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    Promise.all([
      api.homeOverview(),
      api.listLenses({
        keyword: keyword.trim() || undefined,
        state: filters.state,
        cycleId: filters.cycleId === 'all' ? undefined : filters.cycleId,
        colorScheme: filters.color ?? undefined,
      }),
      api.listCycles(),
      api.lensColors(),
    ])
      .then(([nextOverview, nextLenses, nextCycles, nextColors]) => {
        if (cancelled) return
        setOverview(nextOverview)
        setLenses(nextLenses)
        setCycles(nextCycles)
        setColors(nextColors)
        setError(null)
      })
      .catch((err: Error) => {
        if (!cancelled) setError(err.message)
      })
      .finally(() => {
        if (!cancelled) {
          setLoading(false)
          // 启动动画播完（或数据先就绪）即收起启动屏
          ;(window as unknown as { __mmSplashReady?: () => void }).__mmSplashReady?.()
        }
      })
    return () => {
      cancelled = true
    }
  }, [version, keyword, filters])

  /** 需要处理：已过期在前（最近过期的优先），随后是即将到期（最早到期优先） */
  const tasks = useMemo(() => {
    const expired = [...(overview?.expired ?? [])].sort(
      (a, b) => (b.daysRemaining ?? 0) - (a.daysRemaining ?? 0),
    )
    const soon = [...(overview?.expiring ?? [])].sort((a, b) =>
      (a.expiryDate ?? '').localeCompare(b.expiryDate ?? ''),
    )
    return [...expired, ...soon]
  }, [overview])

  const activeFilterCount =
    (filters.state === 'all' ? 0 : 1) +
    (filters.cycleId === 'all' ? 0 : 1) +
    (filters.color ? 1 : 0)
  const hasFilters = activeFilterCount > 0 || keyword.trim() !== ''

  const openFilterSheet = () => {
    setDraft(filters)
    setFilterOpen(true)
  }

  const applyFilters = () => {
    setFilters(draft)
    setFilterOpen(false)
  }

  const runAction = useCallback(async () => {
    if (!action) return
    setBusy(true)
    try {
      if (action.kind === 'discard') {
        await api.discardLens(action.lens.id)
      } else {
        await api.openLens(action.lens.id, todayISO())
      }
      setAction(null)
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }, [action, refresh])

  const stats = overview?.stats

  return (
    <Page
      hero
      tabBar
      title="我的美瞳"
      subtitle={`${formatDate(todayISO())} · ${stats?.total ?? 0} 副在册${
        tasks.length > 0 ? ` · ${tasks.length} 副需要处理` : ''
      }`}
    >
      {error ? (
        <div className="error-box" style={{ marginBottom: 14 }}>
          {error}
        </div>
      ) : null}

      {/* 需要处理：临期与过期合并，全量展示，行内可直接操作 */}
      <section className="section">
        <div className="section-head">
          <h2>需要处理</h2>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            {tasks.length > 3 ? (
              <span style={{ fontSize: 12.5, color: 'var(--mm-ink-3)' }}>{tasks.length} 副</span>
            ) : null}
            {tasks.length > 0 ? (
              <button className="link" onClick={() => push({ name: 'expiring' })}>
                查看全部
              </button>
            ) : null}
          </div>
        </div>

        {loading && !overview ? (
          <div className="skeleton" style={{ height: 132 }} />
        ) : tasks.length === 0 ? (
          <div className="card card-pad" style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span
              style={{
                width: 32,
                height: 32,
                borderRadius: 11,
                background: 'var(--mm-success-soft)',
                color: 'var(--mm-success)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 15,
              }}
            >
              ✓
            </span>
            <div>
              <div style={{ fontSize: 14, fontWeight: 600 }}>都在有效期内</div>
              <div style={{ fontSize: 12, color: 'var(--mm-ink-3)', marginTop: 1 }}>
                有临期或过期的美瞳时会出现在这里
              </div>
            </div>
          </div>
        ) : (
          <div className="card" style={{ overflow: 'hidden' }}>
            {tasks.slice(0, 3).map((lens) => {
              const cover = lens.images[0] ? imageUrl(lens.images[0].path) : null
              const expired = lens.state === 'expired'
              return (
                <div
                  key={lens.id}
                  className="todo-row"
                  role="button"
                  tabIndex={0}
                  onClick={() => push({ name: 'lens', id: lens.id })}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter') push({ name: 'lens', id: lens.id })
                  }}
                >
                  <div className="todo-thumb">
                    {cover ? <img src={cover} alt={lens.name} /> : <Monogram text={lens.name} />}
                  </div>
                  <div className="todo-main">
                    <div className="todo-title">
                      {lens.brand} · {lens.name}
                    </div>
                    <div className="todo-meta">
                      <span style={{ color: expired ? 'var(--mm-danger)' : 'var(--mm-warning)' }}>
                        {remainingText(lens.daysRemaining)}
                      </span>
                      <span>·</span>
                      <span>{expired ? '已过期' : `${lens.expiryDate} 到期`}</span>
                    </div>
                  </div>
                  {expired ? (
                    <button
                      className="todo-action danger"
                      onClick={(event) => {
                        event.stopPropagation()
                        setAction({ kind: 'discard', lens })
                      }}
                    >
                      丢弃
                    </button>
                  ) : lens.state === 'unopened' ? (
                    <button
                      className="todo-action"
                      onClick={(event) => {
                        event.stopPropagation()
                        setAction({ kind: 'open', lens })
                      }}
                    >
                      开封
                    </button>
                  ) : (
                    <button
                      className="todo-action"
                      onClick={(event) => {
                        event.stopPropagation()
                        push({ name: 'lens', id: lens.id })
                      }}
                    >
                      查看
                    </button>
                  )}
                </div>
              )
            })}
          </div>
        )}
      </section>

      {/* 概览：一行细指标，替掉原来三个大方块 */}
      <section className="section">
        <div className="overview-strip">
          <div className="overview-cell in_use">
            <span>使用中</span>
            <strong>{stats?.inUse ?? 0}</strong>
          </div>
          <div className="overview-cell unopened">
            <span>未开封</span>
            <strong>{stats?.unopened ?? 0}</strong>
          </div>
          <div className="overview-cell expired">
            <span>已过期</span>
            <strong>{stats?.expired ?? 0}</strong>
          </div>
          {stats && stats.discarded > 0 ? (
            <div className="overview-cell">
              <span>已丢弃</span>
              <strong style={{ color: 'var(--mm-ink-3)' }}>{stats.discarded}</strong>
            </div>
          ) : null}
        </div>
      </section>

      {/* 美瞳库：搜索 + 筛选弹层 + 网格 */}
      <section className="section">
        <div className="section-head">
          <h2>美瞳库</h2>
          <span style={{ fontSize: 12.5, color: 'var(--mm-ink-3)' }}>{lenses.length} 副</span>
        </div>

        <div className="library-tools">
          <div className="search-box">
            <span style={{ color: 'var(--mm-ink-3)', display: 'flex' }}>
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <circle cx="11" cy="11" r="7" />
                <path d="M20 20l-3.5-3.5" strokeLinecap="round" />
              </svg>
            </span>
            <input
              value={keyword}
              onChange={(event) => setKeyword(event.target.value)}
              placeholder="搜索品牌 / 名称 / 颜色"
            />
            {keyword ? (
              <button
                onClick={() => setKeyword('')}
                style={{
                  border: 'none',
                  background: 'none',
                  color: 'var(--mm-ink-3)',
                  fontSize: 12,
                  cursor: 'pointer',
                  padding: 0,
                }}
              >
                清空
              </button>
            ) : null}
          </div>
          <button
            className={`tool-button ${activeFilterCount > 0 ? 'active' : ''}`}
            aria-label="筛选"
            onClick={openFilterSheet}
          >
            <SlidersHorizontal size={17} strokeWidth={1.8} />
            {activeFilterCount > 0 ? <span className="tool-badge">{activeFilterCount}</span> : null}
          </button>
          <button
            className="tool-button"
            aria-label="添加美瞳"
            style={{
              background: 'var(--mm-pink)',
              borderColor: 'var(--mm-pink)',
              color: '#fff',
              boxShadow: '0 6px 14px rgba(233, 120, 154, 0.3)',
            }}
            onClick={() => push({ name: 'lens-form' })}
          >
            <Plus size={19} strokeWidth={2.2} />
          </button>
        </div>

        {loading && lenses.length === 0 ? (
          <div className="lens-grid">
            <div className="skeleton" style={{ aspectRatio: '1 / 1.25' }} />
            <div className="skeleton" style={{ aspectRatio: '1 / 1.25' }} />
          </div>
        ) : lenses.length === 0 ? (
          <div className="card">
            <div className="empty">
              <h4>{hasFilters ? '没有符合条件的美瞳' : '还没有美瞳记录'}</h4>
              <p>
                {hasFilters
                  ? '换个筛选条件，或清空搜索关键词。'
                  : '添加后可以记录照片、镜片参数与开封日期，自动算到期日。'}
              </p>
              {hasFilters ? (
                <div style={{ marginTop: 14 }}>
                  <Button
                    variant="secondary"
                    onClick={() => {
                      setFilters(EMPTY_FILTER)
                      setKeyword('')
                    }}
                  >
                    清空筛选
                  </Button>
                </div>
              ) : (
                <div style={{ marginTop: 14, display: 'flex', justifyContent: 'center' }}>
                  <Button onClick={() => push({ name: 'lens-form' })}>添加第一副美瞳</Button>
                </div>
              )}
            </div>
          </div>
        ) : (
          <div className="lens-grid">
            {lenses.map((lens) => (
              <LensCard
                key={lens.id}
                lens={lens}
                onClick={() => push({ name: 'lens', id: lens.id })}
              />
            ))}
          </div>
        )}
      </section>

      <Dialog open={filterOpen} onOpenChange={setFilterOpen}>
        <DialogContent title="筛选" description="可组合状态、周期与颜色方案">
          <div className="filter-label">状态</div>
          <div className="filter-list">
            {STATE_FILTERS.map((item) => (
              <button
                key={item.value}
                className={`pill ${draft.state === item.value ? 'active' : ''}`}
                onClick={() => setDraft({ ...draft, state: item.value })}
              >
                {item.label}
              </button>
            ))}
          </div>

          <div className="filter-label">周期</div>
          <div className="filter-list">
            <button
              className={`pill ${draft.cycleId === 'all' ? 'active' : ''}`}
              onClick={() => setDraft({ ...draft, cycleId: 'all' })}
            >
              全部
            </button>
            {cycles.map((cycle) => (
              <button
                key={cycle.id}
                className={`pill ${draft.cycleId === cycle.id ? 'active' : ''}`}
                onClick={() => setDraft({ ...draft, cycleId: cycle.id })}
              >
                {cycle.cycleName}
              </button>
            ))}
          </div>

          {colors.length > 0 ? (
            <>
              <div className="filter-label">颜色方案</div>
              <div className="filter-list">
                <button
                  className={`pill ${draft.color === null ? 'active' : ''}`}
                  onClick={() => setDraft({ ...draft, color: null })}
                >
                  全部
                </button>
                {colors.map((color) => (
                  <button
                    key={color}
                    className={`pill ${draft.color === color ? 'active' : ''}`}
                    onClick={() => setDraft({ ...draft, color })}
                  >
                    {color}
                  </button>
                ))}
              </div>
            </>
          ) : null}

          <div className="filter-actions">
            <Button variant="secondary" style={{ flex: 1 }} onClick={() => setDraft(EMPTY_FILTER)}>
              重置
            </Button>
            <Button style={{ flex: 1 }} onClick={applyFilters}>
              应用
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={action !== null}
        onOpenChange={(open) => !open && setAction(null)}
        title={action?.kind === 'discard' ? '标记为已丢弃？' : '按今天开封？'}
        description={
          action?.kind === 'discard'
            ? `${action?.lens.brand} ${action?.lens.name} 将不再计入统计和提醒，之后可在详情页恢复。`
            : `${action?.lens.brand} ${action?.lens.name} 会以 ${todayISO()} 作为开封日期，并按周期重算到期日。`
        }
        confirmText={action?.kind === 'discard' ? '确认丢弃' : '确认开封'}
        danger={action?.kind === 'discard'}
        busy={busy}
        onConfirm={runAction}
      />
    </Page>
  )
}

/** 无照片时用名称首字占位，比粉色空块更像“有内容” */
function Monogram({ text }: { text: string }) {
  const initial = text.trim().charAt(0) || '·'
  return <span className="monogram">{initial.toUpperCase()}</span>
}

function LensCard({ lens, onClick }: { lens: Lens; onClick: () => void }) {
  const cover = lens.images[0] ? imageUrl(lens.images[0].path) : null
  const badge = (() => {
    if (lens.state === 'expired') return { text: '已过期', cls: 'expired' }
    if (lens.state === 'discarded') return { text: '已丢弃', cls: '' }
    if (lens.isExpiringSoon) return { text: remainingText(lens.daysRemaining), cls: 'soon' }
    if (lens.state === 'unopened') return { text: '未开封', cls: 'unopened' }
    return lens.daysRemaining === null
      ? { text: '无有效期', cls: '' }
      : { text: remainingText(lens.daysRemaining), cls: '' }
  })()

  return (
    <button
      className={`lens-card ${lens.state === 'discarded' ? 'is-discarded' : ''}`}
      onClick={onClick}
      type="button"
    >
      <div className="lens-card-cover">
        {cover ? (
          <img src={cover} alt={`${lens.brand} ${lens.name}`} />
        ) : (
          <Monogram text={lens.name} />
        )}
        <span className={`lens-card-badge ${badge.cls}`}>{badge.text}</span>
      </div>
      <div className="lens-card-body">
        <div className="lens-card-name">{lens.name}</div>
        <div className="lens-card-meta">
          {lens.brand} · {cycleText(lens.cycleUnit, lens.cycleValue)}
          {lens.colorScheme ? ` · ${lens.colorScheme}` : ''}
        </div>
      </div>
    </button>
  )
}
