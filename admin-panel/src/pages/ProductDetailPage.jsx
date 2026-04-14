import { useState } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import { ActionMenu } from '../components/ActionMenu';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { FeedbackBanner } from '../components/FeedbackBanner';
import { PanelCard } from '../components/PanelCard';
import { adminListingsService } from '../services/adminListingsService';
import { formatCurrency, formatDateTime } from '../utils/format';

function DetailItem({ label, value }) {
  return (
    <div className="detail-item">
      <span>{label}</span>
      <strong>{value || 'NA'}</strong>
    </div>
  );
}

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

export function ProductDetailPage({ data, adminEmail }) {
  const { listingId } = useParams();
  const [pendingAction, setPendingAction] = useState(null);
  const [busyActionKey, setBusyActionKey] = useState('');
  const [actionError, setActionError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const listing = data.listings.find((item) => item.id === listingId);
  const seller = listing ? data.users.find((user) => user.id === listing.sellerId) : null;
  const relatedReports = listing
    ? data.reports.filter((report) => report.sellerId === listing.sellerId)
    : [];
  const dialogConfig = getDialogConfig(pendingAction);

  function clearFeedback() {
    setActionError('');
    setSuccessMessage('');
  }

  async function handleConfirmedAction() {
    if (!pendingAction?.listing) {
      return;
    }

    const { listing: actionListing, type } = pendingAction;
    const busyKey = `${type}:${actionListing.id}`;
    setBusyActionKey(busyKey);
    clearFeedback();

    try {
      if (type === 'approve') {
        await adminListingsService.approveListing({
          listingId: actionListing.id,
          adminEmail,
        });
        setSuccessMessage(`${actionListing.title} was approved successfully.`);
      }

      if (type === 'flag') {
        await adminListingsService.flagListing({
          listingId: actionListing.id,
          adminEmail,
        });
        setSuccessMessage(`${actionListing.title} was flagged successfully.`);
      }

      if (type === 'close') {
        await adminListingsService.closeListing({
          listingId: actionListing.id,
          adminEmail,
        });
        setSuccessMessage(`${actionListing.title} was closed successfully.`);
      }

      if (type === 'reopen') {
        await adminListingsService.reopenListing({
          listingId: actionListing.id,
          adminEmail,
        });
        setSuccessMessage(`${actionListing.title} was reopened successfully.`);
      }

      if (type === 'delete') {
        await adminListingsService.deleteListing({ listingId: actionListing.id });
        setSuccessMessage(`${actionListing.title} was deleted successfully.`);
      }

      setPendingAction(null);
      data.refresh?.();
    } catch (error) {
      setActionError(error?.message || 'Unable to complete this listing action.');
    } finally {
      setBusyActionKey('');
    }
  }

  if (!listingId) {
    return <Navigate to="/listings" replace />;
  }

  if (!data.loading && !listing) {
    return (
      <div className="page-stack">
        <PanelCard
          title="Product details"
          subtitle="This listing could not be found in the current Firestore snapshot."
        >
          <div className="empty-state">
            The listing may have been deleted or is no longer visible to the admin panel.
          </div>
          <div className="detail-actions">
            <Link to="/listings" className="secondary-button">
              Back to listings
            </Link>
          </div>
        </PanelCard>
      </div>
    );
  }

  if (data.loading || !listing) {
    return (
      <div className="page-stack">
        <PanelCard title="Product details" subtitle="Loading listing details from Firestore.">
          <div className="empty-state">Loading listing details...</div>
        </PanelCard>
      </div>
    );
  }

  const specs = [
    { label: 'Category', value: listing.category },
    { label: 'Brand', value: listing.brand },
    { label: 'Year', value: listing.year ? listing.year.toString() : '' },
    { label: 'Fuel type', value: listing.fuelType },
    {
      label: 'Kilometers driven',
      value: listing.kilometerDriven ? `${listing.kilometerDriven.toLocaleString('en-IN')} km` : '',
    },
    {
      label: 'Owners',
      value: listing.numberOfOwners ? listing.numberOfOwners.toString() : '',
    },
    { label: 'Sub-category', value: listing.subCategory },
    { label: 'Condition', value: listing.condition },
    { label: 'Seller type', value: listing.sellerType },
  ].filter((item) => item.value);

  return (
    <div className="page-stack">
      <PanelCard
        title="Product details"
        subtitle="A full admin view of the selected marketplace listing."
        actions={
          <div className="row-actions">
            <Link to="/listings" className="secondary-button">
              Back to listings
            </Link>
            <ActionMenu
              label="Listing actions"
              items={[
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
          </div>
        }
      >
        <FeedbackBanner tone="error">{actionError}</FeedbackBanner>
        <FeedbackBanner tone="success">{successMessage}</FeedbackBanner>

        <div className="detail-hero">
          <div>
            <span className={`status-pill status-${listing.moderationStatus}`}>
              {listing.moderationStatus}
            </span>
            <h3 className="detail-title">{listing.title}</h3>
            <p className="detail-copy">
              {listing.description || 'No description was added for this listing.'}
            </p>
          </div>
          <div className="detail-price-card">
            <span>Listed price</span>
            <strong>{formatCurrency(listing.price)}</strong>
            <small>Created {formatDateTime(listing.createdAt)}</small>
          </div>
        </div>

        <div className="content-grid">
          <PanelCard
            title="Listing overview"
            subtitle="Core metadata and listing health."
            className="detail-panel"
          >
            <div className="detail-grid">
              <DetailItem label="Listing ID" value={listing.id} />
              <DetailItem label="Stored status" value={listing.status} />
              <DetailItem label="Location" value={listing.location} />
              <DetailItem label="Views" value={listing.views?.toString()} />
              <DetailItem label="Inquiries" value={listing.inquiries?.toString()} />
              <DetailItem label="Review status" value={listing.adminReviewStatus || listing.moderationStatus} />
              <DetailItem label="Moderated by" value={listing.moderatedBy} />
              <DetailItem label="Moderated at" value={formatDateTime(listing.moderatedAt)} />
              <DetailItem label="Last updated" value={formatDateTime(listing.updatedAt)} />
            </div>
          </PanelCard>

          <PanelCard
            title="Seller snapshot"
            subtitle="Who posted the listing and how their account looks right now."
            className="detail-panel"
          >
            <div className="detail-grid">
              <DetailItem label="Seller name" value={listing.sellerName} />
              <DetailItem label="Seller ID" value={listing.sellerId} />
              <DetailItem label="Email" value={seller?.email ?? ''} />
              <DetailItem label="Phone" value={seller?.phoneNumber ?? ''} />
              <DetailItem label="Location" value={seller?.location?.address ?? ''} />
              <DetailItem
                label="Verification"
                value={seller?.verificationStatus ?? 'Unknown'}
              />
            </div>
          </PanelCard>
        </div>

        {specs.length > 0 ? (
          <PanelCard
            title="Product specifications"
            subtitle="Bike, scooter, spare part, or accessory fields captured with the listing."
            className="detail-panel"
          >
            <div className="detail-grid">
              {specs.map((item) => (
                <DetailItem key={item.label} label={item.label} value={item.value} />
              ))}
            </div>
          </PanelCard>
        ) : null}

        <PanelCard
          title="Media"
          subtitle="Product images stored on the listing document."
          className="detail-panel"
        >
          {listing.imageUrls?.length > 0 ? (
            <div className="detail-image-grid">
              {listing.imageUrls.map((imageUrl, index) => (
                <a
                  key={`${listing.id}-image-${index + 1}`}
                  href={imageUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="detail-image-card"
                >
                  <img
                    src={imageUrl}
                    alt={`${listing.title} ${index + 1}`}
                    className="detail-image"
                  />
                </a>
              ))}
            </div>
          ) : (
            <div className="empty-state">No images are attached to this listing.</div>
          )}
        </PanelCard>

        <PanelCard
          title="Safety context"
          subtitle="Open or historical seller reports related to this listing’s seller."
          className="detail-panel"
        >
          {relatedReports.length > 0 ? (
            <div className="list-stack">
              {relatedReports.map((report) => (
                <div key={report.id} className="list-row">
                  <div>
                    <strong>{report.reason}</strong>
                    <p>{report.sellerName}</p>
                  </div>
                  <div className="list-row-meta">
                    <span className={`status-pill status-${report.status}`}>
                      {report.status}
                    </span>
                    <small>{formatDateTime(report.createdAt)}</small>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="empty-state">No seller reports are connected to this listing.</div>
          )}
        </PanelCard>
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
