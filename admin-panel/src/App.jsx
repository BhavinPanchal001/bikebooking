import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom';
import { Sidebar } from './components/Sidebar';
import { Topbar } from './components/Topbar';
import { useAdminAuth } from './hooks/useAdminAuth';
import { useAdminData } from './hooks/useAdminData';
import { DashboardPage } from './pages/DashboardPage';
import { InboxPage } from './pages/InboxPage';
import { ListingsPage } from './pages/ListingsPage';
import { LoginPage } from './pages/LoginPage';
import { UsersPage } from './pages/UsersPage';

const navItems = [
  { to: '/dashboard', label: 'Dashboard', eyebrow: 'Overview' },
  { to: '/listings', label: 'Listings', eyebrow: 'Inventory' },
  { to: '/users', label: 'Users', eyebrow: 'People' },
  { to: '/inbox', label: 'Inbox', eyebrow: 'Safety & chats' },
];

function AdminShell() {
  const location = useLocation();
  const adminAuth = useAdminAuth();
  const adminData = useAdminData({ enabled: Boolean(adminAuth.user) });
  const activeItem =
    navItems.find((item) => location.pathname.startsWith(item.to)) ?? navItems[0];

  if (adminAuth.loading) {
    return (
      <div className="login-shell">
        <section className="login-panel login-panel-loading">
          <h1>Checking admin session...</h1>
          <p>Connecting to Firebase Auth and preparing the control room.</p>
        </section>
      </div>
    );
  }

  if (!adminAuth.user) {
    return (
      <LoginPage
        onSubmit={adminAuth.login}
        error={adminAuth.error}
        authReady
      />
    );
  }

  return (
    <div className="app-shell">
      <Sidebar
        items={navItems}
        activePath={location.pathname}
      />
      <div className="app-main">
        <Topbar
          title={activeItem.label}
          eyebrow={activeItem.eyebrow}
          source={adminData.source}
          loading={adminData.loading}
          lastUpdated={adminData.lastUpdated}
          issueCount={adminData.metrics.openReports}
          userEmail={adminAuth.user.email}
          onLogout={adminAuth.logout}
        />
        <main className="page-wrap">
          <Routes>
            <Route
              path="/"
              element={<Navigate to="/dashboard" replace />}
            />
            <Route
              path="/dashboard"
              element={<DashboardPage data={adminData} />}
            />
            <Route
              path="/listings"
              element={<ListingsPage data={adminData} />}
            />
            <Route
              path="/users"
              element={<UsersPage data={adminData} />}
            />
            <Route
              path="/inbox"
              element={<InboxPage data={adminData} />}
            />
          </Routes>
        </main>
      </div>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AdminShell />
    </BrowserRouter>
  );
}
