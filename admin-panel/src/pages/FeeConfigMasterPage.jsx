import { MasterCrudPage } from '../components/MasterCrudPage';
import { feeConfigMasterModel } from '../data/models/feeConfigMasterModel';
import { feeConfigService } from '../services/feeConfigService';

function formatAmount(paise) {
  const normalized = Number.parseInt(paise, 10);
  if (!Number.isFinite(normalized)) {
    return '-';
  }
  return `Rs.${(normalized / 100).toFixed(2)}`;
}

function formatDuration(days) {
  const normalized = Number.parseInt(days, 10);
  if (!Number.isFinite(normalized) || normalized <= 0) {
    return '-';
  }
  return `${normalized} day${normalized === 1 ? '' : 's'}`;
}

function formatKind(value) {
  switch (value) {
    case 'boost':
      return 'Boost';
    case 'listing_fee':
      return 'Listing fee';
    default:
      return value || '-';
  }
}

const feeConfigPageConfig = {
  title: 'Fee Config',
  subtitle:
    'Single source of truth for anything the user pays for — boost plans and one-time system fees. Editing here updates the mobile app immediately.',
  singularLabel: 'fee',
  pluralLabel: 'fees',
  collectionName: 'fee_config',
  createButtonLabel: 'Add fee',
  createDialogTitle: 'Create fee',
  editDialogTitle: 'Edit fee',
  deleteDialogTitle: 'Delete fee',
  formSubtitle:
    'Slug is the immutable key used by the mobile app and server. Enter the amount in rupees; the server converts it to paise automatically before talking to Razorpay. Set the kind to wire up the correct side-effect on payment.',
  searchPlaceholder: 'Search fees by slug, name, or kind',
  liveMessage: 'Fee records sync live with the Firestore fee_config collection.',
  loadingMessage: 'Loading fees from Firestore...',
  emptyStateMessage: 'No fees configured yet.',
  hideUpdatedColumn: true,
  filterField: 'kind',
  filterLabel: 'Kind',
  filterOptions: [
    { value: 'boost', label: 'Boost' },
    { value: 'listing_fee', label: 'Listing fee' },
  ],
  fields: [

    {
      name: 'slug',
      label: 'Slug (immutable id)',
      placeholder: 'listing_fee',
      required: true,
      autoFocus: true,
      helperText:
        'Lowercase letters, digits, and underscores only. Used as the Firestore document id and passed to createPaymentOrder.',
    },
    {
      name: 'displayName',
      label: 'Display name',
      placeholder: 'Listing fee',
      required: true,
    },
    {
      name: 'subtitle',
      label: 'Subtitle / tagline',
      placeholder: 'One-time fee to publish a listing',
    },
    {
      name: 'kind',
      label: 'Kind',
      type: 'select',
      options: [
        { value: 'boost', label: 'Boost' },
        { value: 'listing_fee', label: 'Listing fee' },
      ],
      required: true,
      helperText:
        'Boost: activates isBoosted + boostExpiresAt on the target product. Listing fee: sets listingFeePaid=true on the target product.',
    },
    {
      name: 'amountRupees',
      label: 'Amount (INR)',
      type: 'number',
      min: 0.01,
      step: 0.01,
      inputMode: 'decimal',
      placeholder: '49.00',
      required: true,
      helperText:
        'Enter rupees (e.g. 49 or 49.50). Stored internally as paise because Razorpay requires the smallest currency unit.',
    },
    {
      name: 'durationDays',
      label: 'Duration (days, boost only)',
      type: 'number',
      min: 0,
      step: 1,
      inputMode: 'numeric',
      placeholder: '7',
      helperText: 'Leave empty for one-time fees that do not expire.',
    },
    {
      name: 'sortOrder',
      label: 'Sort order',
      type: 'number',
      min: 0,
      step: 1,
      inputMode: 'numeric',
      placeholder: '1',
    },
    {
      name: 'isActive',
      label: 'Active',
      type: 'checkbox',
      helperText: 'Uncheck to hide the fee from checkout without deleting it.',
    },
  ],
  tableClassName: 'listing-table',
  tableWrapClassName: 'listing-table-wrap',
  columns: [
    {
      header: 'Fee configuration',
      renderCell: (record) => (
        <div className="listing-identity">
          <div>
            <strong>{record.displayName}</strong>
            <span>{record.slug}</span>
          </div>
          {record.subtitle && (
            <div className="listing-meta-row">
              <span>{record.subtitle}</span>
            </div>
          )}
        </div>
      ),
    },
    {
      header: 'Kind',
      renderCell: (record) => (
        <span className={`status-pill status-${record.kind === 'boost' ? 'pending' : 'active'}`}>
          {formatKind(record.kind)}
        </span>
      ),
    },
    {
      header: 'Amount',
      renderCell: (record) => (
        <strong className="listing-price">{formatAmount(record.amountPaise)}</strong>
      ),
    },
    {
      header: 'Status & Duration',
      renderCell: (record) => (
        <div className="listing-review-cell">
          <span className={`status-pill status-${record.isActive ? 'approved' : 'closed'}`}>
            {record.isActive ? 'Active' : 'Hidden'}
          </span>
          {record.durationDays > 0 && (
            <small>{formatDuration(record.durationDays)}</small>
          )}
        </div>
      ),
    },
  ],
};

export function FeeConfigMasterPage() {
  return (
    <MasterCrudPage
      config={feeConfigPageConfig}
      model={feeConfigMasterModel}
      service={feeConfigService}
    />
  );
}
