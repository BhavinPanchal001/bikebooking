import { useDeferredValue, useState } from 'react';
import { PanelCard } from '../components/PanelCard';
import { formatCurrency, formatDate } from '../utils/format';

export function UsersPage({ data }) {
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const deferredSearch = useDeferredValue(search);

  const filteredUsers = data.users.filter((user) => {
    const matchesSearch =
      !deferredSearch ||
      `${user.fullName} ${user.email} ${user.phoneNumber} ${user.location?.address ?? ''}`
        .toLowerCase()
        .includes(deferredSearch.toLowerCase());

    const matchesFilter = filter === 'all' || user.verificationStatus === filter;
    return matchesSearch && matchesFilter;
  });

  return (
    <div className="page-stack">
      <PanelCard
        title="User directory"
        subtitle="Seller and buyer health in one place."
        actions={
          <div className="filter-row">
            {['all', 'verified', 'incomplete'].map((status) => (
              <button
                key={status}
                type="button"
                className={`filter-chip ${filter === status ? 'filter-chip-active' : ''}`}
                onClick={() => setFilter(status)}
              >
                {status}
              </button>
            ))}
          </div>
        }
      >
        <div className="toolbar">
          <input
            className="search-input"
            type="search"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search users by name, phone, email, or location"
          />
          <div className="toolbar-note">{filteredUsers.length} users visible</div>
        </div>

        <div className="user-grid">
          {filteredUsers.map((user) => (
            <article key={user.id} className="user-card">
              <div className="user-card-head">
                <div>
                  <h4>{user.fullName}</h4>
                  <p>{user.location?.address || 'Location not shared'}</p>
                </div>
                <span className={`status-pill status-${user.verificationStatus}`}>
                  {user.verificationStatus}
                </span>
              </div>
              <div className="user-card-body">
                <div>
                  <span>Email</span>
                  <strong>{user.email || 'Not added'}</strong>
                </div>
                <div>
                  <span>Phone</span>
                  <strong>{user.phoneNumber || 'Not added'}</strong>
                </div>
                <div>
                  <span>Joined</span>
                  <strong>{formatDate(user.joinedAt)}</strong>
                </div>
                <div>
                  <span>Active listings</span>
                  <strong>{user.activeListings}</strong>
                </div>
                <div>
                  <span>Total sales</span>
                  <strong>{formatCurrency(user.totalSales)}</strong>
                </div>
                <div>
                  <span>Seller rating</span>
                  <strong>{user.rating > 0 ? user.rating.toFixed(1) : 'New'}</strong>
                </div>
              </div>
            </article>
          ))}
        </div>
      </PanelCard>
    </div>
  );
}
