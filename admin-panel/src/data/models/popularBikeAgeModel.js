import { normalizeString, toIsoString, validateRequiredText } from './masterModelUtils';

export function createPopularBikeAgeDraft(values = {}) {
  return {
    value: normalizeString(values.value),
  };
}

export function validatePopularBikeAgeDraft(values = {}) {
  const errors = {};
  const valueError = validateRequiredText(values.value, 'Popular bike age', {
    maxLength: 60,
  });

  if (valueError) {
    errors.value = valueError;
  }

  return errors;
}

export function popularBikeAgeFromFirestore(snapshot) {
  const data = snapshot.data();
  const draft = createPopularBikeAgeDraft(data);

  return {
    id: snapshot.id,
    ...draft,
    createdAt: toIsoString(data.createdAt),
    updatedAt: toIsoString(data.updatedAt),
  };
}

export const popularBikeAgeModel = {
  getEmptyValues() {
    return {
      value: '',
    };
  },
  createDraft: createPopularBikeAgeDraft,
  validate: validatePopularBikeAgeDraft,
  getSearchText(record) {
    return record.value.toLowerCase();
  },
  getRecordLabel(record) {
    return record.value || 'popular bike age';
  },
};

