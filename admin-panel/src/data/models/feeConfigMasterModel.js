import {
  normalizeString,
  toIsoString,
  validateRequiredText,
} from './masterModelUtils';

// The admin UI shows rupees for humans but Firestore / Razorpay / Cloud
// Functions still operate in paise (integer smallest currency unit). These
// helpers convert between the two on the boundary between form state and
// the draft we persist.
function rupeesInputToPaise(value) {
  if (value === null || value === undefined || value === '') {
    return '';
  }
  const parsed = Number.parseFloat(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return value;
  }
  return Math.round(parsed * 100);
}

function paiseToRupeesInput(paise) {
  const parsed = Number.parseInt(paise, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return '';
  }
  return (parsed / 100).toString();
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
    kind: 'boost',
    amountPaise: rupeesInputToPaise(values.amountRupees),
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

  const rupees = Number.parseFloat(values.amountRupees);
  if (!Number.isFinite(rupees) || rupees <= 0) {
    errors.amountRupees = 'Amount must be a positive number in rupees.';
  } else {
    // Guard against more than two decimal places (sub-paisa precision).
    const paise = Math.round(rupees * 100);
    if (Math.abs(rupees * 100 - paise) > 1e-6) {
      errors.amountRupees =
        'Amount can have at most 2 decimal places (paise-level precision).';
    }
  }

  const duration = Number.parseInt(values.durationDays, 10);
  if (!Number.isFinite(duration) || duration <= 0) {
    errors.durationDays = 'Boost plans require a duration in days.';
  }

  return errors;
}

export function feeConfigFromFirestore(snapshot) {
  const data = snapshot.data() || {};
  const amountPaise = Number.parseInt(data.amountPaise, 10) || 0;
  return {
    id: snapshot.id,
    slug: snapshot.id,
    displayName: normalizeString(data.displayName),
    kind: normalizeString(data.kind),
    amountPaise,
    // Populated so the edit dialog can prefill the rupees input directly
    // from the record without the caller having to re-derive it.
    amountRupees: paiseToRupeesInput(amountPaise),
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
      amountRupees: '',
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
    return `${record.slug} ${record.displayName}`.toLowerCase();
  },
  getRecordLabel(record) {
    return record.displayName || record.slug || 'fee';
  },
};
