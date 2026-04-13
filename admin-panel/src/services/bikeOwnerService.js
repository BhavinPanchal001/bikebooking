import { bikeOwnerFromFirestore, createBikeOwnerDraft } from '../data/models/bikeOwnerModel';
import { createFirestoreCrudService } from './firestoreCrudService';

function sortBikeOwners(first, second) {
  return first.value.localeCompare(second.value, 'en', { sensitivity: 'base' });
}

export const bikeOwnerService = createFirestoreCrudService({
  collectionName: 'bike_owner',
  fromFirestore: bikeOwnerFromFirestore,
  toFirestore: createBikeOwnerDraft,
  sortRecords: sortBikeOwners,
  itemLabel: 'bike owner entry',
});

