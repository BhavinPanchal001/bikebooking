import { MasterCrudPage } from '../components/MasterCrudPage';
import { planMasterModel } from '../data/models/planMasterModel';
import { plansService } from '../services/plansService';

function formatDuration(days) {
  const normalized = Number.parseInt(days, 10);

  if (!Number.isFinite(normalized) || normalized <= 0) {
    return '-';
  }

  return `${normalized} day${normalized === 1 ? '' : 's'}`;
}

function formatPrice(value) {
  const amount = Number.parseFloat(value);

  if (!Number.isFinite(amount)) {
    return '-';
  }

  return `Rs.${amount.toFixed(2)}`;
}

const plansMasterPageConfig = {
  title: 'Plans Master',
  subtitle: 'Manage boost plans from Firestore so pricing and durations stay editable from the admin panel.',
  singularLabel: 'plan',
  pluralLabel: 'plans',
  collectionName: 'plans',
  createButtonLabel: 'Add plan',
  createDialogTitle: 'Create plan',
  editDialogTitle: 'Edit plan',
  deleteDialogTitle: 'Delete plan',
  formSubtitle: 'Use this master to control the plan name, duration, price, and display order shown for boost packages.',
  searchPlaceholder: 'Search plans by name, duration, or price',
  liveMessage: 'Plan records are syncing live with the Firestore plans collection.',
  loadingMessage: 'Loading plans from Firestore...',
  emptyStateMessage: 'No plans have been added yet.',
  fields: [
    {
      name: 'name',
      label: 'Plan name',
      placeholder: 'Popular Boost',
      required: true,
      autoFocus: true,
      helperText: 'Examples: Basic Boost, Popular Boost, Premium Boost.',
    },
    {
      name: 'durationDays',
      label: 'Duration (days)',
      type: 'number',
      min: 1,
      step: 1,
      inputMode: 'numeric',
      placeholder: '7',
      required: true,
      helperText: 'Enter the number of days this plan remains active.',
    },
    {
      name: 'price',
      label: 'Price (INR)',
      type: 'number',
      min: 0.01,
      step: 0.01,
      inputMode: 'decimal',
      placeholder: '199.00',
      required: true,
      helperText: 'Store only the amount. The UI can format it as Rs.199.00.',
    },
    {
      name: 'sortOrder',
      label: 'Sort order',
      type: 'number',
      min: 0,
      step: 1,
      inputMode: 'numeric',
      placeholder: '1',
      required: true,
      helperText: 'Lower values appear first in the plan list.',
    },
  ],
  columns: [
    {
      header: 'Plan',
      renderCell: (record) => (
        <div className="primary-cell">
          <strong>{record.name}</strong>
          <span>{`${formatDuration(record.durationDays)} boost package`}</span>
        </div>
      ),
    },
    {
      header: 'Duration',
      renderCell: (record) => formatDuration(record.durationDays),
    },
    {
      header: 'Price',
      renderCell: (record) => formatPrice(record.price),
    },
    {
      header: 'Sort Order',
      renderCell: (record) => record.sortOrder ?? 0,
    },
  ],
};

export function PlansMasterPage() {
  return (
    <MasterCrudPage
      config={plansMasterPageConfig}
      model={planMasterModel}
      service={plansService}
    />
  );
}
