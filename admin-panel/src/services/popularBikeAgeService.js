import {
  createPopularBikeAgeDraft,
  popularBikeAgeFromFirestore,
} from '../data/models/popularBikeAgeModel';
import { createFirestoreCrudService } from './firestoreCrudService';

function sortPopularBikeAges(first, second) {
  return first.value.localeCompare(second.value, 'en', { sensitivity: 'base' });
}

export const popularBikeAgeService = createFirestoreCrudService({
  collectionName: 'popular_bike_age',
  fromFirestore: popularBikeAgeFromFirestore,
  toFirestore: createPopularBikeAgeDraft,
  sortRecords: sortPopularBikeAges,
  itemLabel: 'popular bike age entry',
});

