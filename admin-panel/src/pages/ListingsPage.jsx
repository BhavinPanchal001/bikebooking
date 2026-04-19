import { useDeferredValue, useMemo, useState } from 'react';
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
    case 'approve':
      return {
        title: 'Approve listing',
        message: `Approve "${listingTitle}" and restore it to active marketplace status?`,
        confirmLabel: 'Approve listing',
        busyLabel: 'Approving...',
        confirmButtonClassName: 'secondary-button',
      };
    case 'flag':
      return {
        title: 'Flag listing',
        message: `Flag "${listingTitle}" for moderation follow-up?`,
        confirmLabel: 'Flag listing',
        busyLabel: 'Flagging...',
        confirmButtonClassName: 'danger-button',
      };
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

export function ListingsPage({ data, adminEmail }) {
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const [pendingAction, setPendingAction] = useState(null);
  const [busyActionKey, setBusyActionKey] = useState('');
  const [actionError, setActionError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const deferredSearch = useDeferredValue(search);

  const filteredListings = useMemo(
    () =>
      data.listings.filter((listing) => {
        const matchesSearch =
          !deferredSearch ||
          `${listing.title} ${listing.brand} ${listing.sellerName} ${listing.location}`
            .toLowerCase()
            .includes(deferredSearch.toLowerCase());

        const matchesFilter = filter === 'all' || listing.moderationStatus === filter;
        return matchesSearch && matchesFilter;
      }),
    [data.listings, deferredSearch, filter],
  );

  const dialogConfig = getDialogConfig(pendingAction);

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
      if (type === 'approve') {
        await adminListingsService.approveListing({
          listingId: listing.id,
          adminEmail,
        });
        setSuccessMessage(`${listing.title} was approved successfully.`);
      }

      if (type === 'flag') {
        await adminListingsService.flagListing({
          listingId: listing.id,
          adminEmail,
        });
        setSuccessMessage(`${listing.title} was flagged successfully.`);
      }

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
        subtitle="Review live inventory, trace seller performance, and inspect listing details."
        actions={
          <div className="filter-row">
            {['all', 'approved', 'flagged', 'pending', 'closed'].map((status) => (
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
        {data.source === 'mock' && !data.loading ? null : (
          <div className="live-note">
            <span className={`dot dot-${data.source}`} />
            {data.loading
              ? 'Loading live listings from Firestore.'
              : data.source === 'firebase-partial'
                ? 'Listings are partially loaded from Firestore. Some related collections may be blocked.'
                : 'Listings are loaded from your live Firestore products collection.'}
          </div>
        )}

        <FeedbackBanner tone="error">{actionError}</FeedbackBanner>
        <FeedbackBanner tone="success">{successMessage}</FeedbackBanner>

        <div className="toolbar">
          <input
            className="search-input"
            type="search"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search by title, seller, brand, or city"
          />
          <div className="toolbar-note">{filteredListings.length} listings visible</div>
        </div>

        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Listing</th>
                <th>Category</th>
                <th>Seller</th>
                <th>Price</th>
                <th>Status</th>
                <th>Posted</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {data.loading ? (
                <tr>
                  <td colSpan="7">
                    <div className="empty-state">Loading live listings...</div>
                  </td>
                </tr>
              ) : filteredListings.length > 0 ? (
                filteredListings.map((listing) => (
                  <tr key={listing.id}>
                    <td>
                      <div className="primary-cell">
                        <strong>{listing.title}</strong>
                        <span>
                          {listing.brand} · {listing.location}
                        </span>
                      </div>
                    </td>
                    <td>{listing.category}</td>
                    <td>{listing.sellerName}</td>
                    <td>{formatCurrency(listing.price)}</td>
                    <td>
                      <span className={`status-pill status-${listing.moderationStatus}`}>
                        {listing.moderationStatus}
                      </span>
                    </td>
                    <td>{formatDateTime(listing.createdAt)}</td>
                    <td className="table-actions-cell">
                      <ActionMenu
                        items={[
                          {
                            key: 'details',
                            label: 'Open details',
                            to: `/listings/${listing.id}`,
                          },
                          listing.moderationStatus !== 'approved' || listing.status !== 'active'
                            ? {
                                key: 'approve',
                                label: 'Approve listing',
                                disabled: busyActionKey === `approve:${listing.id}`,
                                onSelect() {
                                  clearFeedback();
                                  setPendingAction({ type: 'approve', listing });
                                },
                              }
                            : null,
                          listing.moderationStatus !== 'flagged'
                            ? {
                                key: 'flag',
                                label: 'Flag listing',
                                tone: 'danger',
                                disabled: busyActionKey === `flag:${listing.id}`,
                                onSelect() {
                                  clearFeedback();
                                  setPendingAction({ type: 'flag', listing });
                                },
                              }
                            : null,
                          {
                            key: listing.status === 'sold' ? 'reopen' : 'close',
                            label: listing.status === 'sold' ? 'Reopen listing' : 'Close listing',
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
                ))
              ) : (
                <tr>
                  <td colSpan="7">
                    <div className="empty-state">No listings found in Firestore for this filter.</div>
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
