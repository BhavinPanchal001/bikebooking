export function normalizeString(value) {
  return value?.toString().trim() ?? '';
}

export function toIsoString(value) {
  if (!value) {
    return null;
  }

  if (typeof value?.toDate === 'function') {
    return value.toDate().toISOString();
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

export function isValidHttpUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === 'http:' || url.protocol === 'https:';
  } catch (error) {
    return false;
  }
}

export function validateRequiredText(value, label, { maxLength = 120 } = {}) {
  const normalized = normalizeString(value);

  if (!normalized) {
    return `${label} is required.`;
  }

  if (normalized.length > maxLength) {
    return `${label} must be ${maxLength} characters or fewer.`;
  }

  return '';
}

export function validateRequiredImageUrl(value, label = 'Image URL') {
  const normalized = normalizeString(value);

  if (!normalized) {
    return `${label} is required.`;
  }

  if (!isValidHttpUrl(normalized)) {
    return `${label} must be a valid http or https URL.`;
  }

  return '';
}

