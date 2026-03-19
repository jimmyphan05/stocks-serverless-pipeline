const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
]

function formatDate(dateStr) {
  const [year, month, day] = dateStr.split('-').map(Number)
  const d = new Date(year, month - 1, day)
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()} (${DAYS[d.getDay()]})`
}

export default function MoverCard({ mover }) {
  const pct = parseFloat(mover.percent_change)
  const isPositive = pct >= 0
  const bgColor = isPositive ? '#d4edda' : '#f8d7da'
  const borderColor = isPositive ? '#7ec89a' : '#e88a92'
  const textColor = isPositive ? '#155724' : '#721c24'
  const arrow = isPositive ? '↑' : '↓'
  const sign = isPositive ? '+' : ''

  return (
    <div
      className="card mb-3"
      style={{
        backgroundColor: bgColor,
        backgroundImage: 'var(--bs-gradient)',
        border: `1px solid ${borderColor}`,
        boxShadow: '0 4px 12px rgba(0,0,0,0.12)',
      }}
    >
      <div className="card-body d-flex justify-content-between align-items-center">
        <div>
          <div className="fw-semibold" style={{ color: textColor }}>
            {formatDate(mover.date)}
          </div>
          <div className="fs-3 fw-bold" style={{ color: textColor }}>
            {mover.ticker}
          </div>
          <div style={{ color: textColor }}>
            Percentage Change: {sign}{pct.toFixed(2)}%
          </div>
          <div style={{ color: textColor, opacity: 0.85 }} className="small">
            Close: ${parseFloat(mover.close_price).toFixed(2)}
          </div>
        </div>
        <div className="fs-1 fw-bold" style={{ color: textColor }}>
          {arrow}
        </div>
      </div>
    </div>
  )
}