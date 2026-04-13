import { MasterCrudPage } from '../components/MasterCrudPage';
import { bikeOwnerModel } from '../data/models/bikeOwnerModel';
import { bikeOwnerService } from '../services/bikeOwnerService';

const bikeOwnerPageConfig = {
  title: 'Bike Owner Master',
  subtitle: 'Maintain owner selection values with a dedicated Firestore-backed admin workflow.',
  singularLabel: 'bike owner value',
  pluralLabel: 'bike owner records',
  collectionName: 'bike_owner',
  createButtonLabel: 'Add owner value',
  createDialogTitle: 'Create bike owner value',
  editDialogTitle: 'Edit bike owner value',
  deleteDialogTitle: 'Delete bike owner value',
  formSubtitle: 'Use short, user-friendly labels that match the owner options you want in the app.',
  searchPlaceholder: 'Search bike owner values',
  liveMessage: 'Bike owner records are syncing live with the Firestore bike_owner collection.',
  loadingMessage: 'Loading bike owner records from Firestore...',
  emptyStateMessage: 'No bike owner records have been added yet.',
  fields: [
    {
      name: 'value',
      label: 'Value',
      placeholder: 'First owner',
      required: true,
      autoFocus: true,
      helperText: 'Examples: First owner, Second owner, Third owner.',
      fullWidth: true,
    },
  ],
  columns: [
    {
      header: 'Value',
      renderCell: (record) => (
        <div className="primary-cell">
          <strong>{record.value}</strong>
          <span>Stored in `bike_owner` for dynamic admin-managed forms.</span>
        </div>
      ),
    },
  ],
};

export function BikeOwnerMasterPage() {
  return (
    <MasterCrudPage
      config={bikeOwnerPageConfig}
      model={bikeOwnerModel}
      service={bikeOwnerService}
    />
  );
}
