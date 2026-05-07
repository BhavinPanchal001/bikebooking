import { useDeferredValue, useEffect, useMemo, useState } from 'react';
import { ActionMenu } from '../components/ActionMenu';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { FeedbackBanner } from '../components/FeedbackBanner';
import { PanelCard } from '../components/PanelCard';
import { adminListingsService } from '../services/adminListingsService';
import { formatCurrency, formatDateTime } from '../utils/format';

function getDialogConfig(action) {
  if (!action?.listing) {
    return null;
  }

  const listingTitle = action.listing.title || action.listing.id;

  switch (action.type) {
    case 'close':
      return {
        title: 'Close listing',
        message: `Close "${listingTitle}" and mark it sold in Firestore?`,
        confirmLabel: 'Close listing',
        busyLabel: 'Closing...',
        confirmButtonClassName: 'danger-button',
      };
    case 'reopen':
      return {
        title: 'Reopen listing',
        message: `Reopen "${listingTitle}" and return it to active status?`,
        confirmLabel: 'Reopen listing',
        busyLabel: 'Reopening...',
        confirmButtonClassName: 'secondary-button',
      };
    case 'delete':
      return {
        title: 'Delete listing',
        message: `Delete "${listingTitle}" and clean up saved references and related chats? This action cannot be undone.`,
        confirmLabel: 'Delete listing',
        busyLabel: 'Deleting...',
        confirmButtonClassName: 'danger-button',
      };
    default:
      return null;
  }
}

function formatStatusLabel(value) {
  if (!value) {
    return 'Unknown';
  }

  return value
    .split(/[_\s-]+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

export function ListingsPage({ data, adminEmail }) {
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const [pendingAction, setPendingAction] = useState(null);
  const [busyActionKey, setBusyActionKey] = useState('');
  const [actionError, setActionError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const deferredSearch = useDeferredValue(search);
  const [displayLimit, setDisplayLimit] = useState(20);

  useEffect(() => {
    setDisplayLimit(20);
  }, [search, filter]);

  const filteredListings = useMemo(
    () =>
      data.listings.filter((listing) => {
        const matchesSearch =
          !deferredSearch ||
          `${listing.title} ${listing.brand} ${listing.sellerName} ${listing.location}`
            .toLowerCase()
            .includes(deferredSearch.toLowerCase());

        const matchesFilter = filter === 'all' || listing.status === filter;
        return matchesSearch && matchesFilter;
      }),
    [data.listings, deferredSearch, filter],
  );

  const listingSummary = useMemo(() => {
    const counts = data.listings.reduce(
      (summary, listing) => {
        const status = listing.status || 'active';
        summary[status] = (summary[status] ?? 0) + 1;
        summary.all += 1;
        return summary;
      },
      { all: 0 },
    );

    return ['all', 'active', 'sold'].map((status) => ({
      status,
      count: counts[status] ?? 0,
    }));
  }, [data.listings]);

  const dialogConfig = getDialogConfig(pendingAction);

  const displayedListings = filteredListings.slice(0, displayLimit);

  function clearFeedback() {
    setActionError('');
    setSuccessMessage('');
  }

  async function handleConfirmedAction() {
    if (!pendingAction?.listing) {
      return;
    }

    const { listing, type } = pendingAction;
    const busyKey = `${type}:${listing.id}`;
    setBusyActionKey(busyKey);
    clearFeedback();

    try {
      if (type === 'close') {
        await adminListingsService.closeListing({
          listingId: listing.id,
          adminEmail,
        });
        setSuccessMessage(`${listing.title} was closed successfully.`);
      }

      if (type === 'reopen') {
        await adminListingsService.reopenListing({
          listingId: listing.id,
          adminEmail,
        });
        setSuccessMessage(`${listing.title} was reopened successfully.`);
      }

      if (type === 'delete') {
        await adminListingsService.deleteListing({ listingId: listing.id });
        setSuccessMessage(`${listing.title} was deleted successfully.`);
      }

      setPendingAction(null);
      data.refresh?.();
    } catch (error) {
      setActionError(error?.message || 'Unable to complete this listing action.');
    } finally {
      setBusyActionKey('');
    }
  }

  return (
    <div className="page-stack">
      <PanelCard
        title="Listing moderation"
        subtitle="Review live inventory, seller context, and moderation state from one focused queue."
      >
        <FeedbackBanner tone="error">{actionError}</FeedbackBanner>
        <FeedbackBanner tone="success">{successMessage}</FeedbackBanner>

        <div className="toolbar listing-toolbar">
          <label className="listing-search-field">
            <span>Search listings</span>
            <input
              className="search-input"
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Title, seller, brand, or city"
            />
          </label>
          <label className="listing-status-filter">
            <span>Status</span>
            <select
              value={filter}
              onChange={(event) => setFilter(event.target.value)}
            >
              {listingSummary.map(({ status, count }) => (
                <option key={status} value={status}>
                  {formatStatusLabel(status)} ({count})
                </option>
              ))}
            </select>
          </label>
          <div className="listing-toolbar-note">
            <strong>{filteredListings.length}</strong>
            <span>{filteredListings.length === 1 ? 'listing visible' : 'listings visible'}</span>
          </div>
        </div>

        <div className="table-wrap listing-table-wrap">
          <table className="data-table listing-table">
            <thead>
              <tr>
                <th>Listing</th>
                <th>Seller</th>
                <th>Price</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {data.loading ? (
                <tr>
                  <td colSpan="5">
                    <div className="empty-state">Loading live listings...</div>
                  </td>
                </tr>
              ) : displayedListings.length > 0 ? (
                <>
                  {displayedListings.map((listing) => (
                    <tr key={listing.id}>
                    <td>
                      <div className="listing-identity">
                        <div>
                          <strong>{listing.title}</strong>
                          <span>{listing.brand || 'Unknown brand'} · {listing.location || 'Unknown city'}</span>
                        </div>
                        <div className="listing-meta-row">
                          <span>{listing.category || 'Uncategorised'}</span>
                          <span>{formatStatusLabel(listing.status)}</span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="listing-seller-cell">
                        <strong>{listing.sellerName || 'Unknown seller'}</strong>
                      </div>
                    </td>
                    <td>
                      <strong className="listing-price">{formatCurrency(listing.price)}</strong>
                    </td>
                    <td>
                      <div className="listing-review-cell">
                        <span className={`status-pill status-${listing.status}`}>
                          {formatStatusLabel(listing.status)}
                        </span>
                      </div>
                    </td>
                    <td className="table-actions-cell">
                      <ActionMenu
                        label={`Manage ${listing.title || 'listing'}`}
                        iconOnly
                        items={[
                          {
                            key: 'details',
                            label: 'Open details',
                            icon: 'details',
                            to: `/listings/${listing.id}`,
                          },
                          {
                            key: listing.status === 'sold' ? 'reopen' : 'close',
                            label: listing.status === 'sold' ? 'Reopen listing' : 'Close listing',
                            icon: listing.status === 'sold' ? 'reopen' : 'close',
                            tone: listing.status === 'sold' ? 'default' : 'danger',
                            disabled:
                              busyActionKey === `${listing.status === 'sold' ? 'reopen' : 'close'}:${listing.id}`,
                            onSelect() {
                              clearFeedback();
                              setPendingAction({
                                type: listing.status === 'sold' ? 'reopen' : 'close',
                                listing,
                              });
                            },
                          },
                          {
                            key: 'delete',
                            label: 'Delete listing',
                            icon: 'delete',
                            tone: 'danger',
                            disabled: busyActionKey === `delete:${listing.id}`,
                            onSelect() {
                              clearFeedback();
                              setPendingAction({ type: 'delete', listing });
                            },
                          },
                        ]}
                      />
                    </td>
                  </tr>
                ))}
                {displayLimit < filteredListings.length && (
                  <tr>
                    <td colSpan="5" style={{ textAlign: 'center', padding: '2rem' }}>
                      <button 
                        type="button" 
                        className="secondary-button"
                        onClick={() => setDisplayLimit((prev) => prev + 50)}
                      >
                        Load more listings
                      </button>
                    </td>
                  </tr>
                )}
                </>
              ) : (
                <tr>
                  <td colSpan="5">
                    <div className="empty-state">No listings found for this filter.</div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </PanelCard>

      <ConfirmDialog
        open={Boolean(dialogConfig)}
        title={dialogConfig?.title}
        message={dialogConfig?.message}
        confirmLabel={dialogConfig?.confirmLabel}
        busyLabel={dialogConfig?.busyLabel}
        busy={Boolean(pendingAction?.listing) && busyActionKey === `${pendingAction?.type}:${pendingAction?.listing?.id}`}
        confirmButtonClassName={dialogConfig?.confirmButtonClassName}
        onConfirm={handleConfirmedAction}
        onClose={() => {
          if (!busyActionKey) {
            setPendingAction(null);
          }
        }}
      />
    </div>
  );
}
