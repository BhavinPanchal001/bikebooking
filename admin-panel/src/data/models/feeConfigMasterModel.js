import {
  normalizeString,
  toIsoString,
  validateRequiredText,
} from './masterModelUtils';

const SUPPORTED_KINDS = ['boost', 'listing_fee'];

function normalizePositiveInteger(value) {
  if (value === null || value === undefined || value === '') {
    return '';
  }
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : value;
}

function normalizeNonNegativeInteger(value) {
  if (value === null || value === undefined || value === '') {
    return 0;
  }
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : value;
}

function normalizeOptionalPositiveInteger(value) {
  if (value === null || value === undefined || value === '') {
    return null;
  }
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return null;
  }
  return parsed;
}

function normalizeBoolean(value) {
  if (typeof value === 'boolean') return value;
  if (value === 'false' || value === 0 || value === '0') return false;
  return Boolean(value);
}

export function createFeeConfigDraft(values = {}) {
  return {
    slug: normalizeString(values.slug).toLowerCase().replace(/\s+/g, '_'),
    displayName: normalizeString(values.displayName),
    kind: normalizeString(values.kind),
    amountPaise: normalizePositiveInteger(values.amountPaise),
    durationDays: normalizeOptionalPositiveInteger(values.durationDays),
    currency: normalizeString(values.currency) || 'INR',
    sortOrder: normalizeNonNegativeInteger(values.sortOrder),
    isActive:
      values.isActive === undefined ? true : normalizeBoolean(values.isActive),
    subtitle: normalizeString(values.subtitle),
  };
}

export function validateFeeConfigDraft(values = {}) {
  const errors = {};

  const slugError = validateRequiredText(values.slug, 'Slug', { maxLength: 60 });
  if (slugError) errors.slug = slugError;
  if (!slugError && !/^[a-z0-9_]+$/.test(values.slug)) {
    errors.slug =
      'Slug must only contain lowercase letters, numbers, and underscores.';
  }

  const displayError = validateRequiredText(values.displayName, 'Display name');
  if (displayError) errors.displayName = displayError;

  if (!SUPPORTED_KINDS.includes(values.kind)) {
    errors.kind = `Kind must be one of: ${SUPPORTED_KINDS.join(', ')}`;
  }

  const amount = Number.parseInt(values.amountPaise, 10);
  if (!Number.isFinite(amount) || amount <= 0) {
    errors.amountPaise = 'Amount (paise) must be a positive whole number.';
  }

  if (values.kind === 'boost') {
    const duration = Number.parseInt(values.durationDays, 10);
    if (!Number.isFinite(duration) || duration <= 0) {
      errors.durationDays = 'Boost plans require a duration in days.';
    }
  }

  return errors;
}

export function feeConfigFromFirestore(snapshot) {
  const data = snapshot.data() || {};
  return {
    id: snapshot.id,
    slug: snapshot.id,
    displayName: normalizeString(data.displayName),
    kind: normalizeString(data.kind),
    amountPaise: Number.parseInt(data.amountPaise, 10) || 0,
    durationDays: Number.parseInt(data.durationDays, 10) || null,
    currency: normalizeString(data.currency) || 'INR',
    sortOrder: Number.parseInt(data.sortOrder, 10) || 0,
    isActive: data.isActive !== false,
    subtitle: normalizeString(data.subtitle),
    createdAt: toIsoString(data.createdAt),
    updatedAt: toIsoString(data.updatedAt),
  };
}

export const feeConfigMasterModel = {
  getEmptyValues() {
    return {
      slug: '',
      displayName: '',
      kind: 'boost',
      amountPaise: '',
      durationDays: '',
      currency: 'INR',
      sortOrder: 0,
      isActive: true,
      subtitle: '',
    };
  },
  createDraft: createFeeConfigDraft,
  validate: validateFeeConfigDraft,
  getSearchText(record) {
    return `${record.slug} ${record.displayName} ${record.kind}`.toLowerCase();
  },
  getRecordLabel(record) {
    return record.displayName || record.slug || 'fee';
  },
};
