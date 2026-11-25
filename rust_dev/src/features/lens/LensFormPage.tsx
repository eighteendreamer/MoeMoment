import { useCallback, useEffect, useRef, useState } from 'react'
import { Camera, ChevronDown, ChevronLeft, ChevronRight, ImagePlus, Loader2, Trash2 } from 'lucide-react'
import { Page } from '@/components/Page'
import { Button } from '@/components/arc/button/button'
import { DatePicker } from '@/components/arc/date-picker/date-picker'
import { Input } from '@/components/arc/input/input'
import { Select } from '@/components/arc/select/select'
import { Textarea } from '@/components/arc/textarea/textarea'
import { useNav } from '@/app/navigation'
import { api, imageUrl } from '@/lib/api'
import { dateToISO, isoToDate, cycleText } from '@/lib/format'
import { formatSize, prepareImage } from '@/lib/image'
import type { Cycle, Lens, LensSpecs, LensUpsert } from '@/lib/types'

interface SpecField {
  key: keyof LensSpecs
  label: string
  placeholder: string
  step: string
  min?: string
  max?: string
}

const SPEC_FIELDS: SpecField[] = [
  { key: 'Lens_diameter', label: '镜片直径', placeholder: 'mm，如 14.2', step: '0.1', min: '0', max: '30' },
  { key: 'Colored_diameter', label: '着色直径', placeholder: 'mm，如 13.2', step: '0.1', min: '0', max: '30' },
  { key: 'Moisture_content', label: '含水量', placeholder: '%，如 48', step: '1', min: '0', max: '100' },
  { key: 'Base_arc', label: '基弧', placeholder: 'mm，如 8.6', step: '0.1', min: '0', max: '20' },
  { key: 'Left_eye_prescription', label: '左眼度数', placeholder: 'D，如 -3.25', step: '0.25', min: '-30', max: '30' },
  { key: 'right_eye_prescription', label: '右眼度数', placeholder: 'D，如 -3.50', step: '0.25', min: '-30', max: '30' },
]

export function LensFormPage({ id }: { id?: number }) {
  const { back, push, replace, refresh } = useNav()
  const editing = typeof id === 'number'

  const [cycles, setCycles] = useState<Cycle[]>([])
  const [brand, setBrand] = useState('')
  const [name, setName] = useState('')
  const [cycleId, setCycleId] = useState<string>('')
  const [colorScheme, setColorScheme] = useState('')
  const [packageExpiry, setPackageExpiry] = useState<Date | undefined>(undefined)
  const [note, setNote] = useState('')
  const [specs, setSpecs] = useState<Record<string, string>>({})
  const [specsOpen, setSpecsOpen] = useState(false)
  const [images, setImages] = useState<string[]>([])
  const [loading, setLoading] = useState(editing)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // 用户中途放弃时，清理本次新写入但没保存的图片文件
  const addedImages = useRef<string[]>([])
  const savedRef = useRef(false)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const cameraInputRef = useRef<HTMLInputElement>(null)
  const [processing, setProcessing] = useState(false)
  const [imageTip, setImageTip] = useState<string | null>(null)

  useEffect(() => {
    return () => {
      if (!savedRef.current && addedImages.current.length > 0) {
        addedImages.current.forEach((path) => {
          api.deleteLensImage(path).catch(() => undefined)
        })
      }
    }
  }, [])

  const hydrate = useCallback((lens: Lens) => {
    setBrand(lens.brand)
    setName(lens.name)
    setCycleId(String(lens.cycleId))
    setColorScheme(lens.colorScheme ?? '')
    setPackageExpiry(isoToDate(lens.packageExpiryDate))
    setNote(lens.note ?? '')
    const nextSpecs: Record<string, string> = {}
    SPEC_FIELDS.forEach((field) => {
      const value = lens.lensSpecs[field.key]
      if (value !== undefined && value !== null) nextSpecs[field.key] = String(value)
    })
    setSpecs(nextSpecs)
    // 已经有参数时默认展开，新增时收起，避免一屏全是空格子
    setSpecsOpen(Object.keys(nextSpecs).length > 0)
    setImages(lens.images.map((image) => image.path))
  }, [])

  useEffect(() => {
    let cancelled = false
    api
      .listCycles()
      .then((list) => {
        if (cancelled) return
        setCycles(list)
        if (!editing) {
          const monthly = list.find((cycle) => cycle.cycleName === '月抛') ?? list[0]
          if (monthly) setCycleId(String(monthly.id))
        }
      })
      .catch((err: Error) => setError(err.message))

    if (editing) {
      api
        .getLens(id)
        .then((lens) => {
          if (!cancelled) hydrate(lens)
        })
        .catch((err: Error) => setError(err.message))
        .finally(() => {
          if (!cancelled) setLoading(false)
        })
    }
    return () => {
      cancelled = true
    }
  }, [editing, id, hydrate])

  const handleFiles = async (files: FileList | null) => {
    if (!files || files.length === 0) return
    setError(null)
    setProcessing(true)
    try {
      for (const file of Array.from(files)) {
        if (!file.type.startsWith('image/')) {
          setError('只能选择图片文件')
          continue
        }
        // 先压缩再落盘，避免原图几 MB 直接写进应用数据目录
        const prepared = await prepareImage(file)
        const path = await api.saveLensImage(prepared.dataUrl, prepared.mime)
        addedImages.current.push(path)
        setImages((prev) => [...prev, path])
        setImageTip(
          prepared.compressed
            ? `已压缩：${formatSize(file.size)} → ${formatSize(prepared.bytes)}`
            : `已添加：${formatSize(prepared.bytes)}`,
        )
      }
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setProcessing(false)
      if (fileInputRef.current) fileInputRef.current.value = ''
      if (cameraInputRef.current) cameraInputRef.current.value = ''
    }
  }

  /** 调整图片顺序：第一张作为封面 */
  const moveImage = (index: number, direction: -1 | 1) => {
    setImages((prev) => {
      const next = [...prev]
      const target = index + direction
      if (target < 0 || target >= next.length) return prev
      const [item] = next.splice(index, 1)
      next.splice(target, 0, item)
      return next
    })
  }

  const removeImage = async (path: string) => {
    setImages((prev) => prev.filter((item) => item !== path))
    if (addedImages.current.includes(path)) {
      addedImages.current = addedImages.current.filter((item) => item !== path)
      await api.deleteLensImage(path).catch(() => undefined)
    }
    // 已有图片的删除在保存时统一由后端处理，避免中途放弃导致数据不一致
  }

  const submit = async () => {
    setError(null)
    if (!brand.trim()) {
      setError('请填写品牌')
      return
    }
    if (!name.trim()) {
      setError('请填写美瞳名称')
      return
    }
    if (!cycleId) {
      setError('请选择使用周期')
      return
    }

    const lensSpecs: LensSpecs = {}
    for (const field of SPEC_FIELDS) {
      const raw = specs[field.key]?.trim()
      if (!raw) continue
      const value = Number(raw)
      if (Number.isNaN(value)) {
        setError(`${field.label} 需要填写数字`)
        setSpecsOpen(true)
        return
      }
      lensSpecs[field.key] = value
    }

    const payload: LensUpsert = {
      brand: brand.trim(),
      name: name.trim(),
      cycleId: Number(cycleId),
      colorScheme: colorScheme.trim() || null,
      lensSpecs,
      packageExpiryDate: dateToISO(packageExpiry),
      note: note.trim() || null,
      images,
    }

    setSaving(true)
    try {
      if (editing) {
        await api.updateLens(id, payload)
        savedRef.current = true
        refresh()
        back()
      } else {
        const created = await api.createLens(payload)
        savedRef.current = true
        refresh()
        replace({ name: 'lens', id: created.id })
      }
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setSaving(false)
    }
  }

  const filledSpecs = SPEC_FIELDS.filter((field) => (specs[field.key] ?? '').trim() !== '').length

  return (
    <Page title={editing ? '编辑美瞳' : '添加美瞳'}>
      {loading ? <div className="skeleton" style={{ height: 320 }} /> : null}

      {!loading ? (
        <>
          {error ? (
            <div className="error-box" style={{ marginBottom: 12 }}>
              {error}
            </div>
          ) : null}

          <div className="form-stack">
            {/* 基础信息：两列排布，短字段不再各占一整行 */}
            <section className="card card-pad">
              <div className="card-section-head" style={{ marginBottom: 10 }}>
                <span className="collapse-title">基础信息</span>
                <button
                  type="button"
                  className="text-link"
                  style={{ marginLeft: 'auto' }}
                  onClick={() => push({ name: 'cycles' })}
                >
                  管理周期
                </button>
              </div>
              <div className="form-grid-2">
                <Input
                  label="品牌"
                  value={brand}
                  onChange={(event) => setBrand(event.target.value)}
                  placeholder="Olens"
                  maxLength={40}
                />
                <Input
                  label="名称"
                  value={name}
                  onChange={(event) => setName(event.target.value)}
                  placeholder="Scandi Hazel"
                  maxLength={60}
                />
              </div>

              <div className="form-grid-2" style={{ marginTop: 12 }}>
                <div className="arc-field">
                  <Select
                    label="使用周期"
                    value={cycleId}
                    onValueChange={setCycleId}
                    placeholder="选择周期"
                    options={cycles.map((cycle) => ({
                      value: String(cycle.id),
                      label: `${cycle.cycleName}（${cycleText(cycle.cycleUnit, cycle.cycleValue)}）`,
                    }))}
                  />
                </div>
                <Input
                  label="颜色方案"
                  value={colorScheme}
                  onChange={(event) => setColorScheme(event.target.value)}
                  placeholder="蜜糖棕"
                  maxLength={30}
                />
              </div>

              <div className="arc-field" style={{ marginTop: 10 }}>
                <DatePicker
                  label="包装有效期"
                  value={packageExpiry}
                  onChange={setPackageExpiry}
                  locale="zh-CN"
                  format={{ year: 'numeric', month: 'long', day: 'numeric' }}
                />
              </div>
            </section>

            {/* 镜片参数：折叠面板，展开后两列数字输入 */}
            <section className="card">
              <button
                type="button"
                className="collapse-head"
                onClick={() => setSpecsOpen((open) => !open)}
                aria-expanded={specsOpen}
              >
                <span className="collapse-title">镜片参数</span>
                <span className="collapse-meta">
                  {filledSpecs > 0 ? `已填 ${filledSpecs}/6` : '全部可选'}
                </span>
                <ChevronDown
                  size={17}
                  className={`collapse-chevron ${specsOpen ? 'open' : ''}`}
                  strokeWidth={1.9}
                />
              </button>

              {specsOpen ? (
                <div className="collapse-body">
                  <div className="form-grid-3">
                    {SPEC_FIELDS.map((field) => (
                      <label className="number-field" key={field.key}>
                        <span>{field.label}</span>
                        <input
                          type="number"
                          inputMode="decimal"
                          step={field.step}
                          min={field.min}
                          max={field.max}
                          placeholder={field.placeholder}
                          value={specs[field.key] ?? ''}
                          onChange={(event) =>
                            setSpecs((prev) => ({ ...prev, [field.key]: event.target.value }))
                          }
                        />
                      </label>
                    ))}
                  </div>
                </div>
              ) : null}
            </section>

            {/* 照片 */}
            <section className="card card-pad">
              <div className="card-section-head">
                <span className="collapse-title">照片</span>
                <span className="collapse-meta">{images.length > 0 ? `${images.length} 张` : '可选'}</span>
              </div>

              <div className="image-scroller" style={{ marginTop: 10 }}>
                {images.map((path, index) => {
                  const src = imageUrl(path)
                  return (
                    <div className="image-tile" key={`${path}-${index}`}>
                      {src ? <img src={src} alt={`第 ${index + 1} 张照片`} /> : null}
                      <span className="index">{index + 1}</span>
                      <div className="image-tile-actions">
                        <button
                          type="button"
                          aria-label="前移一位"
                          disabled={index === 0}
                          onClick={() => moveImage(index, -1)}
                        >
                          <ChevronLeft size={12} />
                        </button>
                        <button
                          type="button"
                          aria-label="后移一位"
                          disabled={index === images.length - 1}
                          onClick={() => moveImage(index, 1)}
                        >
                          <ChevronRight size={12} />
                        </button>
                      </div>
                      <button
                        type="button"
                        className="remove"
                        aria-label="移除这张照片"
                        onClick={() => removeImage(path)}
                      >
                        <Trash2 size={12} />
                      </button>
                    </div>
                  )
                })}

                <button
                  type="button"
                  className="image-add"
                  disabled={processing}
                  onClick={() => fileInputRef.current?.click()}
                >
                  {processing ? (
                    <Loader2 size={20} className="spin" />
                  ) : (
                    <ImagePlus size={20} strokeWidth={1.7} />
                  )}
                  {processing ? '处理中' : '相册'}
                </button>
                <button
                  type="button"
                  className="image-add"
                  disabled={processing}
                  onClick={() => cameraInputRef.current?.click()}
                >
                  <Camera size={20} strokeWidth={1.7} />
                  拍照
                </button>

                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  multiple
                  hidden
                  onChange={(event) => handleFiles(event.target.files)}
                />
                <input
                  ref={cameraInputRef}
                  type="file"
                  accept="image/*"
                  capture="environment"
                  hidden
                  onChange={(event) => handleFiles(event.target.files)}
                />
              </div>
              {imageTip ? <div className="field-hint">{imageTip}</div> : null}
            </section>

            {/* 备注 */}
            <section className="card card-pad">
              <Textarea
                label="备注"
                value={note}
                onChange={(event) => setNote(event.target.value)}
                placeholder="佩戴感受、购买渠道等（可选）"
                rows={2}
              />
            </section>
          </div>

          {/* 底部固定操作，长表单也不用滑到底找保存 */}
          <div className="form-actions-sticky">
            <Button variant="secondary" onClick={back} disabled={saving}>
              取消
            </Button>
            <Button onClick={submit} loading={saving} style={{ flex: 1.6 }}>
              {editing ? '保存修改' : '保存美瞳'}
            </Button>
          </div>

          <div style={{ height: 76 }} />
        </>
      ) : null}
    </Page>
  )
}
