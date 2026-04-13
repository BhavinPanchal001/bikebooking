import { normalizeString, toIsoString, validateRequiredText } from './masterModelUtils';

export function createBikeOwnerDraft(values = {}) {
  return {
    value: normalizeString(values.value),
  };
}

export function validateBikeOwnerDraft(values = {}) {
  const errors = {};
  const valueError = validateRequiredText(values.value, 'Bike owner value', {
    maxLength: 60,
  });

  if (valueError) {
    errors.value = valueError;
  }

  return errors;
}

export function bikeOwnerFromFirestore(snapshot) {
  const data = snapshot.data();
  const draft = createBikeOwnerDraft(data);

  return {
    id: snapshot.id,
    ...draft,
    createdAt: toIsoString(data.createdAt),
    updatedAt: toIsoString(data.updatedAt),
  };
}

export const bikeOwnerModel = {
  getEmptyValues() {
    return {
      value: '',
    };
  },
  createDraft: createBikeOwnerDraft,
  validate: validateBikeOwnerDraft,
  getSearchText(record) {
    return record.value.toLowerCase();
  },
  getRecordLabel(record) {
    return record.value || 'bike owner';
  },
};

