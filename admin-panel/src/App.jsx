import { useState } from 'react';
import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom';
import { Sidebar } from './components/Sidebar';
import { Topbar } from './components/Topbar';
import { useAdminAuth } from './hooks/useAdminAuth';
import { useAdminData } from './hooks/useAdminData';
import { DashboardPage } from './pages/DashboardPage';
import { BikeOwnerMasterPage } from './pages/BikeOwnerMasterPage';
import { BoostedListingsPage } from './pages/BoostedListingsPage';
import { BrandMasterPage } from './pages/BrandMasterPage';
import { FeeConfigMasterPage } from './pages/FeeConfigMasterPage';
import { CmsPagesPage } from './pages/CmsPagesPage';
import { InboxPage } from './pages/InboxPage';
import { ListingsPage } from './pages/ListingsPage';
import { LoginPage } from './pages/LoginPage';
import { PaymentsPage } from './pages/PaymentsPage';
import { ProductDetailPage } from './pages/ProductDetailPage';
import { PopularBikeAgeMasterPage } from './pages/PopularBikeAgeMasterPage';
import { ReportedPersonsPage } from './pages/ReportedPersonsPage';
import { UsersPage } from './pages/UsersPage';

const navItems = [
  { to: '/dashboard', label: 'Dashboard', eyebrow: 'Overview' },
  { to: '/listings', label: 'Listings', eyebrow: 'Inventory' },
  { to: '/boosted', label: 'Boosted & Featured', eyebrow: 'Promotion' },
  { to: '/users', label: 'Users', eyebrow: 'People' },
  { to: '/payments', label: 'Payments', eyebrow: 'Billing' },
  { to: '/reported-persons', label: 'Reported Persons', eyebrow: 'Safety' },
  { to: '/cms', label: 'CMS Pages', eyebrow: 'Publishing' },
  { to: '/masters/fees', label: 'Fee Config', eyebrow: 'Master data' },
// { to: '/masters/brands', label: 'Brand Master', eyebrow: 'Master data' },
// {
//   to: '/masters/popular-bike-age',
//   label: 'Popular Bike Age',
//   eyebrow: 'Trends',
// },
// { to: '/masters/bike-owner', label: 'Bike Owner', eyebrow: 'Entity' },
];

function AdminShell() {
  const [isCollapsed, setIsCollapsed] = useState(false);
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
          <p>Preparing the control room.</p>
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
    <div className={`app-shell ${isCollapsed ? 'sidebar-collapsed' : ''}`}>
      <Sidebar
        items={navItems}
        activePath={location.pathname}
        isCollapsed={isCollapsed}
        onToggle={() => setIsCollapsed(!isCollapsed)}
      />
      <div className="app-main">
        <Topbar
          title={activeItem.label}
          eyebrow={activeItem.eyebrow}
          lastUpdated={adminData.lastUpdated}
          issueCount={adminData.metrics.openReports}
          userEmail={adminAuth.user.email}
          onRefresh={adminData.refresh}
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
              element={
                <ListingsPage
                  data={adminData}
                  adminEmail={adminAuth.user.email}
                />
              }
            />
            <Route
              path="/listings/:listingId"
              element={
                <ProductDetailPage
                  data={adminData}
                  adminEmail={adminAuth.user.email}
                />
              }
            />
            <Route
              path="/users"
              element={
                <UsersPage
                  data={adminData}
                  adminEmail={adminAuth.user.email}
                />
              }
            />
            <Route
              path="/payments"
              element={<PaymentsPage adminEmail={adminAuth.user.email} />}
            />
            <Route
              path="/boosted"
              element={<BoostedListingsPage />}
            />
            <Route
              path="/reported-persons"
              element={<ReportedPersonsPage data={adminData} />}
            />
            <Route path="/cms" element={<CmsPagesPage />} />
            <Route
              path="/inbox"
              element={<InboxPage data={adminData} />}
            />
            <Route
              path="/masters/fees"
              element={<FeeConfigMasterPage />}
            />
            <Route
              path="/masters/brands"
              element={<BrandMasterPage />}
            />
            <Route
              path="/masters/popular-bike-age"
              element={<PopularBikeAgeMasterPage />}
            />
            <Route
              path="/masters/bike-owner"
              element={<BikeOwnerMasterPage />}
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
