import { brandFromFirestore, createBrandDraft } from '../data/models/brandMasterModel';
import { createFirestoreCrudService } from './firestoreCrudService';

function sortBrands(first, second) {
  return first.name.localeCompare(second.name, 'en', { sensitivity: 'base' });
}

export const brandsService = createFirestoreCrudService({
  collectionName: 'brands',
  fromFirestore: brandFromFirestore,
  toFirestore: createBrandDraft,
  sortRecords: sortBrands,
  itemLabel: 'brand',
});

