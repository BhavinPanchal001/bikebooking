import { NavLink } from 'react-router-dom';

export function Sidebar({ items, activePath, isCollapsed, onToggle }) {
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
    </aside>
  );
}
