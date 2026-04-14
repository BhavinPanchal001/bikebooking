import { planFromFirestore } from '../data/models/planMasterModel';
import { createFirestoreCrudService } from './firestoreCrudService';

function sortPlans(first, second) {
  const firstSortOrder = Number.isFinite(first.sortOrder) ? first.sortOrder : Number.MAX_SAFE_INTEGER;
  const secondSortOrder = Number.isFinite(second.sortOrder)
    ? second.sortOrder
    : Number.MAX_SAFE_INTEGER;

  if (firstSortOrder !== secondSortOrder) {
    return firstSortOrder - secondSortOrder;
  }

  const firstDuration = Number.isFinite(first.durationDays)
    ? first.durationDays
    : Number.MAX_SAFE_INTEGER;
  const secondDuration = Number.isFinite(second.durationDays)
    ? second.durationDays
    : Number.MAX_SAFE_INTEGER;

  if (firstDuration !== secondDuration) {
    return firstDuration - secondDuration;
  }

  return first.name.localeCompare(second.name);
}

export const plansService = createFirestoreCrudService({
  collectionName: 'plans',
  fromFirestore: planFromFirestore,
  toFirestore: (values) => values,
  sortRecords: sortPlans,
  itemLabel: 'plan',
});
