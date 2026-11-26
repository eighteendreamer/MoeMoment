import { useRef, useState } from 'react'
import { Download, FileUp, Loader2, PackageCheck } from 'lucide-react'
import { Page } from '@/components/Page'
import { Button } from '@/components/arc/button/button'
import { useToast } from '@/components/ToastProvider'
import { useNav } from '@/app/navigation'
import { api } from '@/lib/api'

interface ImportSummary {
  lenses: number
  images: number
  cycles: number
  careBottles: number
  autoBackup: string | null
}

/** 文件 → base64（不含 data: 前缀） */
function fileToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => {
      const result = String(reader.result)
      resolve(result.slice(result.indexOf(',') + 1))
    }
    reader.onerror = () => reject(new Error('读取文件失败'))
    reader.readAsDataURL(file)
  })
}

export function DataPage() {
  const { refresh } = useNav()
  const toast = useToast()
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState<'export' | 'import' | null>(null)
  const [imported, setImported] = useState<ImportSummary | null>(null)
  const [pending, setPending] = useState<{ file: File; base64: string } | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleExport = async () => {
    setError(null)
    setBusy('export')
    try {
      const path = await api.exportBackup()
      try {
        // Android：弹系统分享面板，用户选「发给文件传输助手 / 保存到文件」等
        await api.shareFile(path)
        toast('备份已生成，请在分享面板选择保存位置')
      } catch {
        toast(`备份已生成：${path.split('/').pop()}`)
      }
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(null)
    }
  }

  const handlePickFile = async (files: FileList | null) => {
    if (!files || files.length === 0) return
    setError(null)
    const file = files[0]
    if (!file.name.toLowerCase().endsWith('.zip')) {
      setError('请选择本应用导出的 .zip 备份文件')
      return
    }
    try {
      const base64 = await fileToBase64(file)
      setPending({ file, base64 })
    } catch (err) {
      setError((err as Error).message)
    } finally {
      if (fileInputRef.current) fileInputRef.current.value = ''
    }
  }

  const confirmImport = async () => {
    if (!pending) return
    setError(null)
    setBusy('import')
    try {
      const summary = await api.importBackup(pending.base64)
      setPending(null)
      setImported(summary)
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(null)
    }
  }

  return (
    <Page title="数据管理">
      {error ? <div className="error-box">{error}</div> : null}

      {imported ? (
        <div className="notice" style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
          <PackageCheck size={18} style={{ marginTop: 2, flex: '0 0 auto' }} />
          <div>
            <div style={{ fontWeight: 600 }}>导入完成</div>
            <div style={{ fontSize: 12.5, lineHeight: 1.6, marginTop: 4 }}>
              美瞳 {imported.lenses} 副 · 照片 {imported.images} 张 · 周期 {imported.cycles} 种 · 护理液{' '}
              {imported.careBottles} 瓶
              {imported.autoBackup ? ` · 导入前已自动备份 ${imported.autoBackup}` : ''}
            </div>
          </div>
        </div>
      ) : null}

      <section className="card card-pad">
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Download size={17} strokeWidth={1.8} style={{ color: 'var(--mm-pink-strong)' }} />
          <span style={{ fontWeight: 620, fontSize: 14.5 }}>导出数据</span>
        </div>
        <p className="muted" style={{ fontSize: 12.5, lineHeight: 1.7, marginTop: 8 }}>
          把全部美瞳、照片、护理液和提醒设置打包成一个备份文件，通过分享面板发送给文件传输助手或保存到任意位置。
        </p>
        <Button
          variant="secondary"
          style={{ marginTop: 12, width: '100%' }}
          loading={busy === 'export'}
          onClick={handleExport}
        >
          {busy === 'export' ? '正在打包' : '导出备份文件'}
        </Button>
      </section>

      <section className="card card-pad">
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <FileUp size={17} strokeWidth={1.8} style={{ color: 'var(--mm-pink-strong)' }} />
          <span style={{ fontWeight: 620, fontSize: 14.5 }}>导入数据</span>
        </div>
        <p className="muted" style={{ fontSize: 12.5, lineHeight: 1.7, marginTop: 8 }}>
          选择本应用导出的备份文件。导入会<b>替换</b>当前的全部数据；替换前会自动备份现有数据（保留最近
          3 份），导错了可以再导回去。
        </p>
        <Button
          variant="secondary"
          style={{ marginTop: 12, width: '100%' }}
          disabled={busy === 'import'}
          onClick={() => fileInputRef.current?.click()}
        >
          {busy === 'import' ? (
            <>
              <Loader2 size={15} className="spin" style={{ marginRight: 6 }} />
              正在导入
            </>
          ) : (
            '选择备份文件'
          )}
        </Button>
        <input
          ref={fileInputRef}
          type="file"
          accept=".zip,application/zip"
          hidden
          onChange={(event) => handlePickFile(event.target.files)}
        />
      </section>

      <p className="muted" style={{ fontSize: 12, lineHeight: 1.7 }}>
        备份包含照片，请注意保管。数据仅保存在本机，不会自动上传。
      </p>

      {pending ? (
        <div className="notice" style={{ marginTop: 4 }}>
          <div style={{ fontWeight: 600 }}>确认导入「{pending.file.name}」？</div>
          <div style={{ fontSize: 12.5, lineHeight: 1.7, marginTop: 6 }}>
            当前数据（美瞳、照片、护理液、提醒设置）将全部被备份文件替换。导入前会自动备份当前数据。
          </div>
          <div style={{ display: 'flex', gap: 10, marginTop: 12 }}>
            <Button variant="secondary" style={{ flex: 1 }} onClick={() => setPending(null)}>
              取消
            </Button>
            <Button variant="danger" style={{ flex: 1.2 }} loading={busy === 'import'} onClick={confirmImport}>
              替换并导入
            </Button>
          </div>
        </div>
      ) : null}
    </Page>
  )
}
