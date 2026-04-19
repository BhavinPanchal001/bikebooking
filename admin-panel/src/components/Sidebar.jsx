import { NavLink } from 'react-router-dom';

function getSidebarStatus(source, loading) {
  if (loading) {
    return {
      title: 'Refreshing feed',
      body: 'Pulling the latest admin data from the workspace.',
    };
  }

  if (source === 'firebase') {
    return {
      title: 'Live Firestore',
      body: 'Users, listings, and reports are loading from the project database.',
    };
  }

  if (source === 'firebase-partial') {
    return {
      title: 'Partial Firestore',
      body: 'Some collections failed, but the panel is showing what it could read.',
    };
  }

  return {
    title: 'Demo workspace',
    body: 'Using mock data because Firestore is not connected.',
  };
}

export function Sidebar({ items, activePath, source, loading, isCollapsed, onToggle }) {
  const status = getSidebarStatus(source, loading);

  return (
    <aside className={`sidebar ${isCollapsed ? 'is-collapsed' : ''}`}>
      <button
        className="sidebar-toggle"
        onClick={onToggle}
        aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
      >
        {isCollapsed ? '→' : '←'}
      </button>

      <div className="brand-lockup">
        <span className="brand-kicker">{isCollapsed ? 'BB' : 'BikeBooking'}</span>
        {!isCollapsed && (
          <>
            <h1>Admin HQ</h1>
            <p>Listings, users, safety checks, and live marketplace health.</p>
          </>
        )}
      </div>

      <nav className="nav-stack">
        {items.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={`nav-link ${activePath.startsWith(item.to) ? 'nav-link-active' : ''
              }`}
            title={isCollapsed ? item.label : ''}
          >
            {!isCollapsed && <span className="nav-eyebrow">{item.eyebrow}</span>}
            <span className="nav-label">{isCollapsed ? item.label.charAt(0) : item.label}</span>
          </NavLink>
        ))}
      </nav>

      {!isCollapsed && (
        <div className="sidebar-note">
          <span className="sidebar-note-label">Control room</span>
          <strong>{status.title}</strong>
          <p>{status.body}</p>
        </div>
      )}
    </aside>
  );
}
