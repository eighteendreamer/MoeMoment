/**
 * 开发期辅助脚本：通过 WebView2 的远程调试端口（CDP）截图或执行 JS。
 * 仅用于本地验证，不参与应用打包。
 *
 * 用法：
 *   node scripts/cdp.mjs shot <输出路径.png>
 *   node scripts/cdp.mjs eval "<返回 Promise 的表达式>"
 *
 * 启动应用前需要设置：
 *   WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS="--remote-debugging-port=9222"
 */
const PORT = process.env.CDP_PORT ?? '9222'

async function pageTarget() {
  const res = await fetch(`http://127.0.0.1:${PORT}/json`)
  const targets = await res.json()
  const page = targets.find((target) => target.type === 'page')
  if (!page) throw new Error('未找到可调试的页面，请确认应用已启动')
  return page
}

function connect(url) {
  const ws = new WebSocket(url)
  let nextId = 1
  const pending = new Map()
  const ready = new Promise((resolve, reject) => {
    ws.addEventListener('open', () => resolve())
    ws.addEventListener('error', (event) => reject(event))
  })
  ws.addEventListener('message', (event) => {
    const payload = JSON.parse(event.data)
    if (payload.id && pending.has(payload.id)) {
      const { resolve, reject } = pending.get(payload.id)
      pending.delete(payload.id)
      if (payload.error) reject(new Error(JSON.stringify(payload.error)))
      else resolve(payload.result)
    }
  })
  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const id = nextId++
      pending.set(id, { resolve, reject })
      ws.send(JSON.stringify({ id, method, params }))
    })
  return { ready, send, close: () => ws.close() }
}

const [, , action, arg] = process.argv
if (!action) {
  console.error('用法: node scripts/cdp.mjs shot <path> | eval <expr>')
  process.exit(1)
}

const page = await pageTarget()
const client = connect(page.webSocketDebuggerUrl)
await client.ready
await client.send('Page.enable')
await client.send('Runtime.enable')
await client.send('DOM.enable')

if (action === 'shot') {
  const fs = await import('node:fs')
  const path = await import('node:path')
  const result = await client.send('Page.captureScreenshot', { format: 'png' })
  const out = path.resolve(arg)
  fs.mkdirSync(path.dirname(out), { recursive: true })
  fs.writeFileSync(out, Buffer.from(result.data, 'base64'))
  console.log(`saved ${out}`)
} else if (action === 'upload') {
  // 给页面里的第一个 file input 选择本地文件，用于验证图片上传流程
  const fs = await import('node:fs')
  const path = await import('node:path')
  const doc = await client.send('DOM.getDocument', { depth: -1 })
  const node = await client.send('DOM.querySelector', {
    nodeId: doc.root.nodeId,
    selector: 'input[type=file]',
  })
  if (!node.nodeId) throw new Error('页面上没有 file input')
  await client.send('DOM.setFileInputFiles', {
    nodeId: node.nodeId,
    files: [path.resolve(arg)],
  })
  console.log(`uploaded ${path.resolve(arg)}`)
} else if (action === 'eval') {
  const result = await client.send('Runtime.evaluate', {
    expression: `(async () => { ${arg} })()`,
    awaitPromise: true,
    returnByValue: true,
  })
  if (result.exceptionDetails) {
    console.error('EVAL ERROR:', JSON.stringify(result.exceptionDetails, null, 2))
    process.exit(1)
  }
  console.log(JSON.stringify(result.result.value, null, 2))
}

client.close()
