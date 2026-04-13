import { formatDateTime } from '../utils/format';

export function Topbar({
  title,
  eyebrow,
  source,
  loading,
  lastUpdated,
  issueCount,
  userEmail,
  onLogout,
}) {
  return (
    <header className="topbar">
      <div>
        <span className="page-eyebrow">{eyebrow}</span>
        <h2>{title}</h2>
      </div>

      <div className="topbar-meta">
        <div className="source-pill">
          <span className={`dot dot-${source}`} />
          {loading
            ? 'Refreshing feed'
            : source === 'firebase'
              ? 'Firebase data'
              : source === 'firebase-partial'
                ? 'Partial Firebase data'
                : 'Demo data'}
        </div>
        <div className="mini-stat">
          <span>Open issues</span>
          <strong>{issueCount}</strong>
        </div>
        <div className="mini-stat">
          <span>Last sync</span>
          <strong>{formatDateTime(lastUpdated)}</strong>
        </div>
        {userEmail ? (
          <button
            type="button"
            className="logout-button"
            onClick={onLogout}
          >
            {userEmail}
          </button>
        ) : null}
      </div>
    </header>
  );
}
