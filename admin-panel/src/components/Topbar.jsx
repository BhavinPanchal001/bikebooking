import { formatDateTime } from '../utils/format';

export function Topbar({
  title,
  eyebrow,
  lastUpdated,
  issueCount,
  userEmail,
  onRefresh,
  onLogout,
}) {
  return (
    <header className="topbar">
      <div>
        <span className="page-eyebrow">{eyebrow}</span>
        <h2>{title}</h2>
      </div>

      <div className="topbar-meta">
        <div className="mini-stat">
          <span>Open issues</span>
          <strong>{issueCount}</strong>
        </div>
        <div className="mini-stat">
          <span>Last sync</span>
          <strong>{formatDateTime(lastUpdated)}</strong>
        </div>
        {onRefresh ? (
          <button
            type="button"
            className="secondary-button topbar-refresh"
            onClick={onRefresh}
          >
            Refresh
          </button>
        ) : null}
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
