import { useEffect, useState } from 'react'
import MoverCard from './components/MoverCard'

const API_URL = import.meta.env.VITE_API_URL

export default function App() {
  const [movers, setMovers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetch(`${API_URL}/movers`)
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        return res.json()
      })
      .then((data) => {
        setMovers(data.movers || [])
        setLoading(false)
      })
      .catch((err) => {
        setError(err.message)
        setLoading(false)
      })
  }, [])

  return (
    <div className="min-vh-100 bg-light">
      <div className="w-100 py-3 mb-4" style={{ backgroundColor: '#3a7bd5', backgroundImage: 'var(--bs-gradient)' }}>
        <h1 className="text-center fw-bold m-0" style={{ color: '#ffffff' }}>Top Daily Stock Movers!</h1>
      </div>
      <div className="container-fluid px-4">

        {loading && (
          <div className="text-center py-5">
            <div className="spinner-border text-secondary" role="status" />
          </div>
        )}

        {error && (
          <div className="alert alert-danger text-center">
            Failed to load data: {error}
          </div>
        )}

        {!loading && !error && movers.length === 0 && (
          <div className="alert alert-info text-center">No data available yet.</div>
        )}

        {movers.map((mover) => (
          <MoverCard key={mover.date} mover={mover} />
        ))}
      </div>
    </div>
  )
}