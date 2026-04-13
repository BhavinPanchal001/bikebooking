import { MasterCrudPage } from '../components/MasterCrudPage';
import { popularBikeAgeModel } from '../data/models/popularBikeAgeModel';
import { popularBikeAgeService } from '../services/popularBikeAgeService';

const popularBikeAgePageConfig = {
  title: 'Popular Bike Age Master',
  subtitle: 'Manage the bike age options shown across the platform from one Firestore collection.',
  singularLabel: 'popular bike age',
  pluralLabel: 'popular bike age records',
  collectionName: 'popular_bike_age',
  createButtonLabel: 'Add age value',
  createDialogTitle: 'Create bike age value',
  editDialogTitle: 'Edit bike age value',
  deleteDialogTitle: 'Delete bike age value',
  formSubtitle: 'Keep the label concise and consistent so filters and forms stay predictable.',
  searchPlaceholder: 'Search bike age values',
  liveMessage: 'Popular bike age records are syncing live with the Firestore popular_bike_age collection.',
  loadingMessage: 'Loading popular bike age records from Firestore...',
  emptyStateMessage: 'No popular bike age records have been added yet.',
  fields: [
    {
      name: 'value',
      label: 'Value',
      placeholder: '0-1 years',
      required: true,
      autoFocus: true,
      helperText: 'Examples: 0-1 years, 2-3 years, 5+ years.',
      fullWidth: true,
    },
  ],
  columns: [
    {
      header: 'Value',
      renderCell: (record) => (
        <div className="primary-cell">
          <strong>{record.value}</strong>
          <span>Stored in `popular_bike_age` for dynamic admin-managed forms.</span>
        </div>
      ),
    },
  ],
};

export function PopularBikeAgeMasterPage() {
  return (
    <MasterCrudPage
      config={popularBikeAgePageConfig}
      model={popularBikeAgeModel}
      service={popularBikeAgeService}
    />
  );
}

