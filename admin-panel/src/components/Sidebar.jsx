import { NavLink } from 'react-router-dom';

export function Sidebar({ items, activePath }) {
  return (
    <aside className="sidebar">
      <div className="brand-lockup">
        <span className="brand-kicker">BikeBooking</span>
        <h1>Admin HQ</h1>
        <p>Listings, users, safety checks, and live marketplace health.</p>
      </div>

      <nav className="nav-stack">
        {items.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={`nav-link ${
              activePath.startsWith(item.to) ? 'nav-link-active' : ''
            }`}
          >
            <span className="nav-eyebrow">{item.eyebrow}</span>
            <span className="nav-label">{item.label}</span>
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
