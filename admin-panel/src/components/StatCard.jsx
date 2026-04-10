export function StatCard({ label, value, trend, tone = 'default', helper }) {
  return (
    <article className={`stat-card stat-card-${tone}`}>
      <span className="stat-label">{label}</span>
      <strong className="stat-value">{value}</strong>
      <div className="stat-footer">
        <span className="stat-trend">{trend}</span>
        {helper ? <span className="stat-helper">{helper}</span> : null}
      </div>
    </article>
  );
}
