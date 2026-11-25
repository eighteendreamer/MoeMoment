import { useCallback, useEffect, useState } from 'react'
import { BellRing, RefreshCw, ShieldAlert } from 'lucide-react'
import { Page } from '@/components/Page'
import { Button } from '@/components/arc/button/button'
import { Switch } from '@/components/arc/switch/switch'
import { useNav } from '@/app/navigation'
import { useToast } from '@/components/ToastProvider'
import { api } from '@/lib/api'
import { formatDate, formatDateTime } from '@/lib/format'
import type { AppSettings, NotificationLog, NotificationPermission } from '@/lib/types'

const STATUS_TEXT: Record<string, string> = {
  scheduled: '待触发',
  sent: '已发送',
  failed: '发送失败',
  cancelled: '已取消',
}

const TARGET_TEXT: Record<string, string> = {
  lens_expiry: '美瞳到期',
  care_change: '护理液更换',
  care_expiry: '护理液到期',
}

export function NotificationPage() {
  const { refresh } = useNav()
  const toast = useToast()
  const [permission, setPermission] = useState<NotificationPermission | null>(null)
  const [settings, setSettings] = useState<AppSettings | null>(null)
  const [logs, setLogs] = useState<NotificationLog[]>([])
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const load = useCallback(() => {
    Promise.all([api.notificationPermission(), api.getAppSettings(), api.notificationLogs(40)])
      .then(([nextPermission, nextSettings, nextLogs]) => {
        setPermission(nextPermission)
        setSettings(nextSettings)
        setLogs(nextLogs)
        setError(null)
      })
      .catch((err: Error) => setError(err.message))
  }, [])

  useEffect(() => {
    load()
  }, [load])

  const toggleMaster = async (checked: boolean) => {
    setBusy(true)
    try {
      const updated = await api.setAppSetting('system_notifications_enabled', String(checked))
      setSettings(updated)
      toast(checked ? '已开启应用内通知' : '已关闭应用内通知')
      load()
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  const requestPermission = async () => {
    setBusy(true)
    try {
      const next = await api.requestNotificationPermission()
      setPermission(next)
      toast(next.granted ? '通知权限已授权' : '仍未获得权限，请在系统设置中开启')
      load()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  const reschedule = async () => {
    setBusy(true)
    try {
      const sent = await api.rescheduleNotifications()
      toast(sent > 0 ? `已补发 ${sent} 条提醒` : '提醒计划已重排')
      load()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <Page title="系统通知">
      {error ? (
        <div className="error-box" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <div className="card card-pad" style={{ marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span
            className="lead"
            style={{
              width: 38,
              height: 38,
              borderRadius: 12,
              background: permission?.granted ? 'var(--mm-success-soft)' : 'var(--mm-warning-soft)',
              color: permission?.granted ? 'var(--mm-success)' : 'var(--mm-warning)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            {permission?.granted ? <BellRing size={18} /> : <ShieldAlert size={18} />}
          </span>
          <div style={{ flex: 1 }}>
            <div style={{ fontWeight: 600 }}>
              系统通知权限：{permission?.granted ? '已授权' : '未授权'}
            </div>

          </div>
        </div>

        {!permission?.granted ? (
          <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
            <Button style={{ flex: 1 }} loading={busy} onClick={requestPermission}>
              请求通知权限
            </Button>
          </div>
        ) : null}

        {permission?.platformNote ? (
          <div className="notice" style={{ marginTop: 12 }}>
            {permission.platformNote}
          </div>
        ) : null}
      </div>

      <div className="settings-group">
        <h3>应用内通知</h3>
        <div className="settings-card">
          <div className="settings-row" style={{ cursor: 'default' }}>
            <span style={{ flex: 1 }}>通知总开关</span>
            <Switch
              checked={settings?.systemNotificationsEnabled ?? true}
              onCheckedChange={toggleMaster}
              disabled={busy || !settings}
              aria-label="通知总开关"
            />
          </div>
          <button className="settings-row" onClick={reschedule} disabled={busy}>
            <span className="lead">
              <RefreshCw size={16} strokeWidth={1.8} />
            </span>
            <span>立即检查并补发</span>
          </button>
        </div>
      </div>

      <section className="section">
        <div className="section-head">
          <h2>通知记录</h2>
          <span style={{ fontSize: 12.5, color: 'var(--mm-ink-3)' }}>最近 {logs.length} 条</span>
        </div>
        {logs.length === 0 ? (
          <div className="card">
            <div className="empty">
              <h4>还没有通知记录</h4>
              <p>开启提醒并添加美瞳后，这里会记录每次计划与发送结果。</p>
            </div>
          </div>
        ) : (
          <div className="card">
            <div className="list">
              {logs.map((log) => (
                <div key={log.id} className="card-pad" style={{ padding: '12px 14px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', gap: 10 }}>
                    <span style={{ fontWeight: 600, fontSize: 14 }}>{log.title}</span>
                    <span
                      className={`chip plain ${
                        log.status === 'sent'
                          ? 'unopened'
                          : log.status === 'failed'
                            ? 'expired'
                            : log.status === 'scheduled'
                              ? 'soon'
                              : 'discarded'
                      }`}
                    >
                      {STATUS_TEXT[log.status] ?? log.status}
                    </span>
                  </div>
                  <div style={{ fontSize: 13, color: 'var(--mm-ink-2)', marginTop: 4 }}>
                    {log.body}
                  </div>
                  <div style={{ fontSize: 11.5, color: 'var(--mm-ink-3)', marginTop: 6 }}>
                    {TARGET_TEXT[log.targetType] ?? log.targetType} · 计划 {formatDate(log.scheduledDate)}
                    {log.sentAt ? ` · 发送 ${formatDateTime(log.sentAt)}` : ''}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </section>
    </Page>
  )
}
