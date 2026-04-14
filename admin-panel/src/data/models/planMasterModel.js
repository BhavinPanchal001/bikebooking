import { normalizeString, toIsoString, validateRequiredText } from './masterModelUtils';

function normalizePositiveInteger(value) {
  if (value === null || value === undefined || value === '') {
    return '';
  }

  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : value;
}

function normalizePositiveAmount(value) {
  if (value === null || value === undefined || value === '') {
    return '';
  }

  const parsed = Number.parseFloat(value);
  return Number.isFinite(parsed) && parsed > 0 ? Number(parsed.toFixed(2)) : value;
}

function normalizeSortOrder(value) {
  if (value === null || value === undefined || value === '') {
    return 0;
  }

  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : value;
}

function validatePositiveInteger(value, label, { min = 1, max = 365 } = {}) {
  const parsed = Number.parseInt(value, 10);

  if (!Number.isFinite(parsed)) {
    return `${label} must be a whole number.`;
  }

  if (parsed < min) {
    return `${label} must be at least ${min}.`;
  }

  if (parsed > max) {
    return `${label} must be ${max} or fewer.`;
  }

  return '';
}

function validatePositiveAmount(value, label) {
  const parsed = Number.parseFloat(value);

  if (!Number.isFinite(parsed)) {
    return `${label} must be a valid amount.`;
  }

  if (parsed <= 0) {
    return `${label} must be greater than zero.`;
  }

  return '';
}

function validateSortOrder(value, label) {
  const parsed = Number.parseInt(value, 10);

  if (!Number.isFinite(parsed)) {
    return `${label} must be a whole number.`;
  }

  if (parsed < 0) {
    return `${label} cannot be negative.`;
  }

  return '';
}

export function createPlanDraft(values = {}) {
  return {
    name: normalizeString(values.name),
    durationDays: normalizePositiveInteger(values.durationDays),
    price: normalizePositiveAmount(values.price),
    sortOrder: normalizeSortOrder(values.sortOrder),
  };
}

export function validatePlanDraft(values = {}) {
  const errors = {};
  const nameError = validateRequiredText(values.name, 'Plan name', { maxLength: 80 });
  const durationDaysError = validatePositiveInteger(values.durationDays, 'Duration (days)');
  const priceError = validatePositiveAmount(values.price, 'Price');
  const sortOrderError = validateSortOrder(values.sortOrder, 'Sort order');

  if (nameError) {
    errors.name = nameError;
  }

  if (durationDaysError) {
    errors.durationDays = durationDaysError;
  }

  if (priceError) {
    errors.price = priceError;
  }

  if (sortOrderError) {
    errors.sortOrder = sortOrderError;
  }

  return errors;
}

export function planFromFirestore(snapshot) {
  const data = snapshot.data();
  const draft = createPlanDraft(data);

  return {
    id: snapshot.id,
    ...draft,
    createdAt: toIsoString(data.createdAt),
    updatedAt: toIsoString(data.updatedAt),
  };
}

export const planMasterModel = {
  getEmptyValues() {
    return {
      name: '',
      durationDays: '',
      price: '',
      sortOrder: 0,
    };
  },
  createDraft: createPlanDraft,
  validate: validatePlanDraft,
  getSearchText(record) {
    return `${record.name} ${record.durationDays} ${record.price} ${record.sortOrder}`.toLowerCase();
  },
  getRecordLabel(record) {
    return record.name || 'plan';
  },
};
