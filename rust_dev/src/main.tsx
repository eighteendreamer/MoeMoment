import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
// Arc UI 的语义 token 必须先加载，主题覆盖在其后
import './components/arc/foundation.css'
import './styles/app.css'
import App from './App'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
