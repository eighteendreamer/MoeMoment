import { useEffect, useState } from 'react'
import { Page } from '@/components/Page'
import { LensRow } from '@/components/LensRow'
import { useNav } from '@/app/navigation'
import { api } from '@/lib/api'
import type { Lens } from '@/lib/types'

export function ExpiringPage() {
  const { push, version } = useNav()
  const [lenses, setLenses] = useState<Lens[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    api
      .expiringLenses()
      .then((data) => {
        if (!cancelled) {
          setLenses(data)
          setError(null)
        }
      })
      .catch((err: Error) => !cancelled && setError(err.message))
      .finally(() => !cancelled && setLoading(false))
    return () => {
      cancelled = true
    }
  }, [version])

  const expired = lenses.filter((lens) => lens.state === 'expired')
  const soon = lenses.filter((lens) => lens.state !== 'expired')

  return (
    <Page
      title="到期美瞳"
      subtitle={undefined}
      actions={
        <span style={{ fontSize: 12.5, color: 'var(--mm-ink-3)' }}>{lenses.length} 副</span>
      }
    >
      {error ? <div className="error-box" style={{ marginBottom: 12 }}>{error}</div> : null}

      {loading ? (
        <div className="stack-8">
          <div className="skeleton" style={{ height: 76 }} />
          <div className="skeleton" style={{ height: 76 }} />
        </div>
      ) : lenses.length === 0 ? (
        <div className="card">
          <div className="empty">
            <h4>没有需要关注的到期记录</h4>
            <p>这里会显示即将到期和已经过期的美瞳。</p>
          </div>
        </div>
      ) : (
        <>
          {expired.length > 0 ? (
            <section className="section">
              <div className="section-head">
                <h2>已过期</h2>
                <span className="chip expired plain">建议停用</span>
              </div>
              <div className="card" style={{ overflow: 'hidden' }}>
                <div className="list">
                  {expired.map((lens) => (
                    <LensRow
                      key={lens.id}
                      lens={lens}
                      onClick={() => push({ name: 'lens', id: lens.id })}
                    />
                  ))}
                </div>
              </div>
            </section>
          ) : null}

          {soon.length > 0 ? (
            <section className="section">
              <div className="section-head">
                <h2>即将到期</h2>
                <span className="chip soon plain">按到期日升序</span>
              </div>
              <div className="card" style={{ overflow: 'hidden' }}>
                <div className="list">
                  {soon.map((lens) => (
                    <LensRow
                      key={lens.id}
                      lens={lens}
                      onClick={() => push({ name: 'lens', id: lens.id })}
                    />
                  ))}
                </div>
              </div>
            </section>
          ) : null}

          <p className="muted" style={{ marginTop: 12 }}>
            到期日当天即视为已过期；已丢弃的美瞳不会出现在这个列表中。
          </p>
        </>
      )}
    </Page>
  )
}
