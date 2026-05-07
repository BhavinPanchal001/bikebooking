import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { FeedbackBanner } from '../components/FeedbackBanner';
import { PanelCard } from '../components/PanelCard';
import { BoostActionDialog } from '../components/BoostActionDialog';
import { adminBoostService } from '../services/adminBoostService';
import { formatCurrency, formatDateTime } from '../utils/format';
import { ActionMenu } from '../components/ActionMenu';


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

function isActiveBoost(record) {
  if (!record.isBoosted) return false;
  if (!record.boostExpiresAt) return false;
  return new Date(record.boostExpiresAt).getTime() > Date.now();
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

  async function handleConfirm({ durationDays, additionalDays, note }) {
    if (!pendingAction?.record) return { ok: false };
    const { type, record } = pendingAction;
    try {
      if (type === 'revoke') {
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
      } else if (type === 'extend') {
        await adminBoostService.extendBoost({
          productId: record.id,
          additionalDays,
          note,
        });
        setFeedback({
          error: '',
          success: `${record.title} boost extended by ${additionalDays} day${
            additionalDays === 1 ? '' : 's'
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
        setTab('editorial');
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
        setTab('editorial');
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

        <div className="chip-grid">
          <div className="metric-chip">
            <span>Active boosts</span>
            <strong>{activeBoosts.length}</strong>
          </div>
          <div className="metric-chip">
            <span>Admin-granted (free)</span>
            <strong>
              {activeBoosts.filter((r) => r.boostGrantSource === 'admin').length}
            </strong>
          </div>
          <div className="metric-chip">
            <span>Editorial featured</span>
            <strong>{featured.length}</strong>
          </div>
        </div>


        <div className="toolbar listing-toolbar">
          <div className="listing-status-filter">
            <span>View</span>
            <select
              value={tab}
              onChange={(event) => setTab(event.target.value)}
            >
              {TABS.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.label}
                </option>
              ))}
            </select>
          </div>
          <label className="listing-search-field">
            <span>Search promoted</span>
            <input
              className="search-input"
              type="search"
              placeholder="Title, seller, or plan slug"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
            />
          </label>
          <div className="listing-toolbar-note">
            <strong>
              {tab === 'active-boosts' ? visibleBoosts.length : visibleFeatured.length}
            </strong>
            <span>listings visible</span>
          </div>
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
    <Link to={`/listings/${record.id}`} className="listing-identity">
      <div>
        <strong>{record.title}</strong>
        <span>
          {record.brand || 'Unknown brand'}
          {record.category ? ` · ${record.category}` : ''}
        </span>
      </div>
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
    <div className="table-wrap listing-table-wrap">
      <table className="data-table listing-table">
        <thead>
          <tr>
            <th>Listing</th>
            <th>Seller</th>
            <th>Plan</th>
            <th>Expiry</th>
            <th>Status</th>
            <th />
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
              message="No active boosts found."
            />
          ) : (
            records.map((record) => (
              <tr key={record.id}>
                <td>
                  <ListingLink record={record} />
                </td>
                <td>
                  <div className="listing-seller-cell">
                    <strong>{record.sellerName}</strong>
                    <span>{formatCurrency(record.price)}</span>
                  </div>
                </td>
                <td>
                  <div className="listing-review-cell">
                    {record.boostGrantSource === 'admin' ? (
                      <span className="status-pill status-flagged">Admin grant</span>
                    ) : (
                      <span className="status-pill status-approved">Paid boost</span>
                    )}
                    <small>{record.boostPlanId || '—'}</small>
                  </div>
                </td>
                <td>
                  <div className="listing-review-cell">
                    <strong>{remainingLabel(record.boostExpiresAt)}</strong>
                    <small>{formatDateTime(record.boostExpiresAt)}</small>
                  </div>
                </td>
                <td>
                  <div className="listing-review-cell">
                    {record.isEditorialFeatured && (
                      <span className="status-pill status-verified">Featured</span>
                    )}
                  </div>
                </td>
                <td className="table-actions-cell">
                  <ActionMenu
                    label={`Manage ${record.title}`}
                    iconOnly
                    items={[
                      {
                        key: 'details',
                        label: 'Open details',
                        icon: 'details',
                        to: `/listings/${record.id}`,
                      },
                      {
                        key: 'extend',
                        label: 'Extend boost',
                        icon: 'extend',
                        onSelect: () => onExtend(record),
                      },
                      {
                        key: 'feature',
                        label: record.isEditorialFeatured ? 'Unfeature listing' : 'Feature listing',
                        icon: 'feature',
                        onSelect: () => onFeatureToggle(record),
                      },
                      {
                        key: 'revoke',
                        label: 'Revoke boost',
                        icon: 'close',
                        tone: 'danger',
                        onSelect: () => onRevoke(record),
                      },
                    ]}
                  />
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
    <div className="table-wrap listing-table-wrap">
      <table className="data-table listing-table">
        <thead>
          <tr>
            <th>Listing</th>
            <th>Seller</th>
            <th>Featured since</th>
            <th>Promotion</th>
            <th />
          </tr>
        </thead>
        <tbody>
          {error ? (
            <StateRow colSpan={5} message={error} />
          ) : loading ? (
            <StateRow colSpan={5} message="Loading featured listings..." />
          ) : records.length === 0 ? (
            <StateRow
              colSpan={5}
              message="No editorial featured listings found."
            />
          ) : (
            records.map((record) => (
              <tr key={record.id}>
                <td>
                  <ListingLink record={record} />
                </td>
                <td>
                  <div className="listing-seller-cell">
                    <strong>{record.sellerName}</strong>
                    <span>{formatCurrency(record.price)}</span>
                  </div>
                </td>
                <td>
                  <div className="listing-review-cell">
                    <strong>{formatDateTime(record.editorialFeaturedAt)}</strong>
                    <small>{record.editorialFeaturedByEmail || 'Admin'}</small>
                  </div>
                </td>
                <td>
                  <div className="listing-review-cell">
                    {isActiveBoost(record) ? (
                      <>
                        <span className="status-pill status-approved">Boosted</span>
                        <small>{remainingLabel(record.boostExpiresAt)}</small>
                      </>
                    ) : (
                      <span className="status-pill status-closed">Organic</span>
                    )}
                  </div>
                </td>
                <td className="table-actions-cell">
                  <ActionMenu
                    label={`Manage ${record.title}`}
                    iconOnly
                    items={[
                      {
                        key: 'details',
                        label: 'Open details',
                        icon: 'details',
                        to: `/listings/${record.id}`,
                      },
                      !isActiveBoost(record) && {
                        key: 'grant',
                        label: 'Grant boost',
                        icon: 'grant',
                        onSelect: () => onGrantBoost(record),
                      },
                      {
                        key: 'unfeature',
                        label: 'Remove from featured',
                        icon: 'close',
                        tone: 'danger',
                        onSelect: () => onUnfeature(record),
                      },
                    ]}
                  />
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}

