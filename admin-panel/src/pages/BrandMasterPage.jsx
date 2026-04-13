import { useEffect, useState } from 'react';
import { MasterCrudPage } from '../components/MasterCrudPage';
import { brandMasterModel } from '../data/models/brandMasterModel';
import { brandsService } from '../services/brandsService';

function LogoPreview({ imageUrl }) {
  const [hasError, setHasError] = useState(false);
  const normalized = imageUrl.trim();

  useEffect(() => {
    setHasError(false);
  }, [normalized]);

  if (!normalized) {
    return <div className="logo-preview-empty">Paste a public image URL to preview the logo.</div>;
  }

  if (hasError) {
    return <div className="logo-preview-empty">This image URL could not be loaded.</div>;
  }

  return (
    <div className="logo-preview-card">
      <img
        src={normalized}
        alt="Brand logo preview"
        className="logo-preview-image"
        onError={() => setHasError(true)}
      />
    </div>
  );
}

const brandMasterPageConfig = {
  title: 'Brand Master',
  subtitle: 'Create and maintain bike brands with live Firestore syncing for admin operations.',
  singularLabel: 'brand',
  pluralLabel: 'brands',
  collectionName: 'brands',
  createButtonLabel: 'Add brand',
  createDialogTitle: 'Create brand',
  editDialogTitle: 'Edit brand',
  deleteDialogTitle: 'Delete brand',
  formSubtitle: 'Keep brand naming and logo URLs clean so the app can reuse the same source of truth.',
  searchPlaceholder: 'Search brands by name or logo URL',
  liveMessage: 'Brand master records are syncing live with the Firestore brands collection.',
  loadingMessage: 'Loading brand master records from Firestore...',
  emptyStateMessage: 'No brand records have been added yet.',
  fields: [
    {
      name: 'name',
      label: 'Brand name',
      placeholder: 'Royal Enfield',
      required: true,
      autoFocus: true,
      helperText: 'Use the exact brand label you want the app to display.',
    },
    {
      name: 'logoImage',
      label: 'Logo image URL',
      type: 'url',
      placeholder: 'https://example.com/brand-logo.png',
      required: true,
      helperText: 'Use a direct public image URL so clients can render the logo.',
      fullWidth: true,
      renderPreview: (value) => <LogoPreview imageUrl={value} />,
    },
  ],
  columns: [
    {
      header: 'Brand',
      renderCell: (record) => (
        <div className="master-identity">
          <div className="logo-thumb-shell">
            <img src={record.logoImage} alt={`${record.name} logo`} className="logo-thumb" />
          </div>
          <div className="primary-cell">
            <strong>{record.name}</strong>
            <span>{record.logoImage}</span>
          </div>
        </div>
      ),
    },
  ],
};

export function BrandMasterPage() {
  return (
    <MasterCrudPage
      config={brandMasterPageConfig}
      model={brandMasterModel}
      service={brandsService}
    />
  );
}
