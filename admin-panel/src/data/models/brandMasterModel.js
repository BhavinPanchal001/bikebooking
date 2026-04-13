import {
  normalizeString,
  toIsoString,
  validateRequiredImageUrl,
  validateRequiredText,
} from './masterModelUtils';

export function createBrandDraft(values = {}) {
  return {
    name: normalizeString(values.name),
    logoImage: normalizeString(values.logoImage),
  };
}

export function validateBrandDraft(values = {}) {
  const errors = {};
  const nameError = validateRequiredText(values.name, 'Brand name', { maxLength: 80 });
  const logoError = validateRequiredImageUrl(values.logoImage, 'Logo image URL');

  if (nameError) {
    errors.name = nameError;
  }

  if (logoError) {
    errors.logoImage = logoError;
  }

  return errors;
}

export function brandFromFirestore(snapshot) {
  const data = snapshot.data();
  const draft = createBrandDraft(data);

  return {
    id: snapshot.id,
    ...draft,
    createdAt: toIsoString(data.createdAt),
    updatedAt: toIsoString(data.updatedAt),
  };
}

export const brandMasterModel = {
  getEmptyValues() {
    return {
      name: '',
      logoImage: '',
    };
  },
  createDraft: createBrandDraft,
  validate: validateBrandDraft,
  getSearchText(record) {
    return `${record.name} ${record.logoImage}`.toLowerCase();
  },
  getRecordLabel(record) {
    return record.name || 'brand';
  },
};

