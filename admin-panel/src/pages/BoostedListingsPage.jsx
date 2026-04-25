import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { FeedbackBanner } from '../components/FeedbackBanner';
import { PanelCard } from '../components/PanelCard';
import { BoostActionDialog } from '../components/BoostActionDialog';
import { adminBoostService } from '../services/adminBoostService';
import { formatCurrency, formatDateTime } from '../utils/format';

const TABS = [
  { id: 'active-boosts', label: 'Active boosts' },
  { id: 'editorial', label: 'Editorial featured' },
];

function remainingLabel(isoString) {
  if (!isoString) return 'No expiry';
  const expires = new Date(isoString);
  if (Number.isNaN(expires.getTime())) return 'No expiry';
  const diffMs = expires.getTime() - Date.now();
  if (diffMs <= 0) return 'Expired';

  const hours = Math.floor(diffMs / (60 * 60 * 1000));
  if (hours < 1) {
    const minutes = Math.max(1, Math.floor(diffMs / (60 * 1000)));
    return `${minutes} min left`;
  }
  if (hours < 24) return `${hours} h left`;
  const days = Math.floor(hours / 24);
  return `${days} day${days === 1 ? '' : 's'} left`;
}

function planSourceBadge(record) {
  if (!record.isBoosted) return null;
  const source = record.boostGrantSource === 'admin' ? 'Admin grant' : 'Paid';
  return (
    <span
      className={`status-badge ${
        source === 'Admin grant' ? 'status-warn' : 'status-ok'
      }`}
    >
      {source}
    </span>
  );
}

export function BoostedListingsPage() {
  const [tab, setTab] = useState(TABS[0].id);
  const [activeBoosts, setActiveBoosts] = useState([]);
  const [featured, setFeatured] = useState([]);
  const [loadingBoosts, setLoadingBoosts] = useState(true);
  const [loadingFeatured, setLoadingFeatured] = useState(true);
  const [boostError, setBoostError] = useState('');
  const [featuredError, setFeaturedError] = useState('');
  const [search, setSearch] = useState('');
  const [pendingAction, setPendingAction] = useState(null);
  const [feedback, setFeedback] = useState({ error: '', success: '' });

  useEffect(() => {
    setLoadingBoosts(true);
    setBoostError('');
    const unsubscribe = adminBoostService.subscribeActiveBoosts({
      onData: (records) => {
        setActiveBoosts(records);
        setLoadingBoosts(false);
      },
      onError: (message) => {
        setBoostError(message);
        setLoadingBoosts(false);
      },
    });
    return () => unsubscribe?.();
  }, []);

  useEffect(() => {
    setLoadingFeatured(true);
    setFeaturedError('');
    const unsubscribe = adminBoostService.subscribeEditorialFeatured({
      onData: (records) => {
        setFeatured(records);
        setLoadingFeatured(false);
      },
      onError: (message) => {
        setFeaturedError(message);
        setLoadingFeatured(false);
      },
    });
    return () => unsubscribe?.();
  }, []);

  const normalizedSearch = search.trim().toLowerCase();
  const visibleBoosts = useMemo(() => {
    if (!normalizedSearch) return activeBoosts;
    return activeBoosts.filter((record) => {
      const haystack = [
        record.id,
        record.title,
        record.brand,
        record.sellerName,
        record.sellerId,
        record.boostPlanId,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      return haystack.includes(normalizedSearch);
    });
  }, [activeBoosts, normalizedSearch]);

  const visibleFeatured = useMemo(() => {
    if (!normalizedSearch) return featured;
    return featured.filter((record) => {
      const haystack = [
        record.id,
        record.title,
        record.brand,
        record.sellerName,
        record.sellerId,
        record.editorialFeaturedNote,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      return haystack.includes(normalizedSearch);
    });
  }, [featured, normalizedSearch]);

  function openAction(type, record, extras = {}) {
    setFeedback({ error: '', success: '' });
    setPendingAction({ type, record, ...extras });
  }

  async function handleConfirm({ additionalDays, durationDays, note }) {
    if (!pendingAction?.record) return { ok: false };
    const { type, record } = pendingAction;
    try {
      if (type === 'extend') {
        await adminBoostService.extendBoost({
          productId: record.id,
          additionalDays,
          note,
        });
        setFeedback({
          error: '',
          success: `${record.title} extended by ${additionalDays} day${
            additionalDays === 1 ? '' : 's'
          }.`,
        });
      } else if (type === 'revoke') {
        await adminBoostService.revokeBoost({ productId: record.id, note });
        setFeedback({
          error: '',
          success: `${record.title} boost revoked.`,
        });
      } else if (type === 'grant') {
        await adminBoostService.grantBoost({
          productId: record.id,
          durationDays,
          planSlug: 'admin_grant',
          note,
        });
        setFeedback({
          error: '',
          success: `${record.title} boosted for ${durationDays} day${
            durationDays === 1 ? '' : 's'
          }.`,
        });
      } else if (type === 'unfeature') {
        await adminBoostService.setEditorialFeatured({
          productId: record.id,
          isFeatured: false,
          note,
        });
        setFeedback({
          error: '',
          success: `${record.title} removed from editorial featured.`,
        });
      } else if (type === 'feature') {
        await adminBoostService.setEditorialFeatured({
          productId: record.id,
          isFeatured: true,
          note,
        });
        setFeedback({
          error: '',
          success: `${record.title} added to editorial featured.`,
        });
      }
      setPendingAction(null);
      return { ok: true };
    } catch (error) {
      const message = error?.message || 'Unable to complete this action.';
      setFeedback({ error: message, success: '' });
      return { ok: false, error: message };
    }
  }

  return (
    <div className="page-stack">
      <PanelCard
        title="Featured & promoted listings"
        subtitle="Active paid boosts, admin grants, and editorially hand-picked listings for the home feed."
      >
        <FeedbackBanner tone="error">{feedback.error}</FeedbackBanner>
        <FeedbackBanner tone="success">{feedback.success}</FeedbackBanner>

        <div className="summary-grid">
          <div className="summary-card">
            <span className="summary-label">Active boosts</span>
            <span className="summary-value">{activeBoosts.length}</span>
          </div>
          <div className="summary-card">
            <span className="summary-label">Admin-granted (free)</span>
            <span className="summary-value">
              {activeBoosts.filter((r) => r.boostGrantSource === 'admin').length}
            </span>
          </div>
          <div className="summary-card">
            <span className="summary-label">Editorial featured</span>
            <span className="summary-value">{featured.length}</span>
          </div>
        </div>

        <div className="toolbar">
          <div className="filter-row">
            {TABS.map((item) => (
              <button
                key={item.id}
                type="button"
                className={`filter-chip ${
                  tab === item.id ? 'filter-chip-active' : ''
                }`}
                onClick={() => setTab(item.id)}
              >
                {item.label}
              </button>
            ))}
          </div>
          <input
            className="search-input"
            type="search"
            placeholder="Search id, title, seller, plan..."
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
        </div>

        {tab === 'active-boosts' ? (
          <ActiveBoostsTable
            records={visibleBoosts}
            loading={loadingBoosts}
            error={boostError}
            onExtend={(record) => openAction('extend', record)}
            onRevoke={(record) => openAction('revoke', record)}
            onFeatureToggle={(record) =>
              openAction(
                record.isEditorialFeatured ? 'unfeature' : 'feature',
                record,
              )
            }
          />
        ) : (
          <EditorialFeaturedTable
            records={visibleFeatured}
            loading={loadingFeatured}
            error={featuredError}
            onUnfeature={(record) => openAction('unfeature', record)}
            onGrantBoost={(record) => openAction('grant', record)}
          />
        )}
      </PanelCard>

      <BoostActionDialog
        action={pendingAction}
        onClose={() => setPendingAction(null)}
        onConfirm={handleConfirm}
      />
    </div>
  );
}

function StateRow({ colSpan, message }) {
  return (
    <tr>
      <td colSpan={colSpan}>
        <div className="empty-state">{message}</div>
      </td>
    </tr>
  );
}

function ListingLink({ record }) {
  return (
    <Link to={`/listings/${record.id}`} className="primary-cell">
      <strong>{record.title}</strong>
      <span>
        {record.brand || 'Unknown brand'}
        {record.category ? ` · ${record.category}` : ''}
      </span>
    </Link>
  );
}

function ActiveBoostsTable({
  records,
  loading,
  error,
  onExtend,
  onRevoke,
  onFeatureToggle,
}) {
  return (
    <div className="table-wrap">
      <table className="data-table">
        <thead>
          <tr>
            <th>Listing</th>
            <th>Seller</th>
            <th>Plan</th>
            <th>Expires</th>
            <th>Editorial</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {error ? (
            <StateRow colSpan={6} message={error} />
          ) : loading ? (
            <StateRow colSpan={6} message="Loading active boosts..." />
          ) : records.length === 0 ? (
            <StateRow
              colSpan={6}
              message="No active boosts. When a seller completes a boost purchase or an admin grants a boost, it will show up here."
            />
          ) : (
            records.map((record) => (
              <tr key={record.id}>
                <td>
                  <ListingLink record={record} />
                </td>
                <td>
                  <div className="primary-cell">
                    <strong>{record.sellerName}</strong>
                    <span>{formatCurrency(record.price)}</span>
                  </div>
                </td>
                <td>
                  <div className="primary-cell">
                    <strong>{planSourceBadge(record)}</strong>
                    <span>
                      {record.boostPlanId || '—'}
                      {record.boostGrantedByEmail
                        ? ` · by ${record.boostGrantedByEmail}`
                        : ''}
                    </span>
                  </div>
                </td>
                <td>
                  <div className="primary-cell">
                    <strong>{remainingLabel(record.boostExpiresAt)}</strong>
                    <span>{formatDateTime(record.boostExpiresAt)}</span>
                  </div>
                </td>
                <td>
                  {record.isEditorialFeatured ? (
                    <span className="status-badge status-ok">Featured</span>
                  ) : (
                    <span className="muted">—</span>
                  )}
                </td>
                <td>
                  <div className="boost-action-group">
                    <button
                      type="button"
                      className="secondary-button"
                      onClick={() => onExtend(record)}
                    >
                      Extend
                    </button>
                    <button
                      type="button"
                      className="secondary-button"
                      onClick={() => onFeatureToggle(record)}
                    >
                      {record.isEditorialFeatured ? 'Unfeature' : 'Feature'}
                    </button>
                    <button
                      type="button"
                      className="danger-button"
                      onClick={() => onRevoke(record)}
                    >
                      Revoke
                    </button>
                  </div>
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}

function EditorialFeaturedTable({
  records,
  loading,
  error,
  onUnfeature,
  onGrantBoost,
}) {
  return (
    <div className="table-wrap">
      <table className="data-table">
        <thead>
          <tr>
            <th>Listing</th>
            <th>Seller</th>
            <th>Featured since</th>
            <th>Note</th>
            <th>Boost</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {error ? (
            <StateRow colSpan={6} message={error} />
          ) : loading ? (
            <StateRow colSpan={6} message="Loading featured listings..." />
          ) : records.length === 0 ? (
            <StateRow
              colSpan={6}
              message="No editorially featured listings yet. Open any listing's detail page to feature it."
            />
          ) : (
            records.map((record) => (
              <tr key={record.id}>
                <td>
                  <ListingLink record={record} />
                </td>
                <td>
                  <div className="primary-cell">
                    <strong>{record.sellerName}</strong>
                    <span>{formatCurrency(record.price)}</span>
                  </div>
                </td>
                <td>
                  <div className="primary-cell">
                    <strong>{formatDateTime(record.editorialFeaturedAt)}</strong>
                    {record.editorialFeaturedByEmail ? (
                      <span>by {record.editorialFeaturedByEmail}</span>
                    ) : null}
                  </div>
                </td>
                <td>
                  <span className="muted">
                    {record.editorialFeaturedNote || '—'}
                  </span>
                </td>
                <td>
                  {record.isBoosted ? (
                    <div className="primary-cell">
                      <strong>{planSourceBadge(record)}</strong>
                      <span>{remainingLabel(record.boostExpiresAt)}</span>
                    </div>
                  ) : (
                    <span className="muted">Not boosted</span>
                  )}
                </td>
                <td>
                  <div className="boost-action-group">
                    {!record.isBoosted ? (
                      <button
                        type="button"
                        className="secondary-button"
                        onClick={() => onGrantBoost(record)}
                      >
                        Grant boost
                      </button>
                    ) : null}
                    <button
                      type="button"
                      className="danger-button"
                      onClick={() => onUnfeature(record)}
                    >
                      Unfeature
                    </button>
                  </div>
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}
