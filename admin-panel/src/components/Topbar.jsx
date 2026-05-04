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
