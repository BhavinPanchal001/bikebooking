import {
  collection,
  doc,
  getDoc,
  getDocs,
  onSnapshot,
  serverTimestamp,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { auth, db } from '../lib/firebase';
import { cmsPageFromFirestore, createCmsPageDraft, normalizeCmsPageSlug } from '../data/models/cmsPageModel';

const COLLECTION_NAME = 'cms_pages';
const FIRESTORE_WRITE_TIMEOUT_MS = 15000;

function getCollectionRef() {
  if (!db) {
    throw new Error('Firestore is not configured for the admin panel.');
  }

  return collection(db, COLLECTION_NAME);
}

function getPageRef(slug) {
  return doc(db, COLLECTION_NAME, normalizeCmsPageSlug(slug));
}

function getVersionRef(slug, version) {
  return doc(db, COLLECTION_NAME, normalizeCmsPageSlug(slug), 'versions', String(version));
}

function getActorMetadata() {
  const user = auth?.currentUser;
  const userId = user?.uid?.trim() ?? '';
  const userEmail = user?.email?.trim() ?? '';

  return {
    ...(userId ? { updatedByUid: userId } : {}),
    ...(userEmail ? { updatedByEmail: userEmail } : {}),
  };
}

function getCreateMetadata() {
  const actorMetadata = getActorMetadata();

  return {
    ...actorMetadata,
    ...(actorMetadata.updatedByUid ? { createdByUid: actorMetadata.updatedByUid } : {}),
    ...(actorMetadata.updatedByEmail ? { createdByEmail: actorMetadata.updatedByEmail } : {}),
  };
}

async function withTimeout(promise, timeoutMessage, timeoutMs = FIRESTORE_WRITE_TIMEOUT_MS) {
  let timeoutId;

  const timeoutPromise = new Promise((_, reject) => {
    timeoutId = window.setTimeout(() => {
      reject(new Error(timeoutMessage));
    }, timeoutMs);
  });

  try {
    return await Promise.race([promise, timeoutPromise]);
  } finally {
    window.clearTimeout(timeoutId);
  }
}

function resolveErrorMessage(error, action) {
  const code = error?.code?.toString().trim().toLowerCase() ?? '';

  switch (code) {
    case 'permission-denied':
      return `You do not have permission to ${action} this CMS page.`;
    case 'unauthenticated':
      return 'Your admin session expired. Please sign in again.';
    case 'unavailable':
      return 'Firestore is temporarily unavailable. Please try again.';
    case 'already-exists':
      return 'A CMS page with this slug already exists.';
    case 'not-found':
      return 'This CMS page no longer exists.';
    default:
      return error?.message || `Unable to ${action} this CMS page.`;
  }
}

function getTimestampValue(...values) {
  for (const value of values) {
    if (!value) {
      continue;
    }

    const timestamp = Date.parse(value);
    if (!Number.isNaN(timestamp)) {
      return timestamp;
    }
  }

  return 0;
}

function mapAndSortRecords(snapshot) {
  return snapshot.docs
    .map(cmsPageFromFirestore)
    .sort((first, second) => {
      const secondTimestamp = getTimestampValue(
        second.updatedAt,
        second.publishedAt,
        second.createdAt,
      );
      const firstTimestamp = getTimestampValue(
        first.updatedAt,
        first.publishedAt,
        first.createdAt,
      );
      return secondTimestamp - firstTimestamp;
    });
}

function persistVersionSnapshot(batch, slug, version, payload, { isPublished = false } = {}) {
  batch.set(
    getVersionRef(slug, version),
    {
      slug,
      title: payload.title,
      bodyMarkdown: payload.bodyMarkdown,
      version,
      isPublished,
      savedAt: serverTimestamp(),
      ...(isPublished ? { publishedAt: serverTimestamp() } : {}),
      ...getActorMetadata(),
    },
    { merge: true },
  );
}

export const cmsPagesService = {
  subscribe({ onData, onError }) {
    try {
      return onSnapshot(
        getCollectionRef(),
        (snapshot) => {
          try {
            onData?.(mapAndSortRecords(snapshot));
          } catch (error) {
            console.error('Unable to map cms_pages data.', error);
            onError?.(error?.message || 'Unable to load CMS pages from Firestore.');
          }
        },
        (error) => {
          console.error('Unable to subscribe to cms_pages.', error);
          onError?.(resolveErrorMessage(error, 'load'));
        },
      );
    } catch (error) {
      console.error('Unable to initialize cms_pages subscription.', error);
      onError?.(resolveErrorMessage(error, 'load'));
      return () => {};
    }
  },

  async create(values) {
    const payload = createCmsPageDraft(values);

    if (!payload.slug) {
      throw new Error('Slug is required before saving.');
    }

    const pageRef = getPageRef(payload.slug);
    const existingDoc = await getDoc(pageRef);
    if (existingDoc.exists()) {
      throw new Error('A CMS page with this slug already exists.');
    }

    const draftVersion = 1;
    const batch = writeBatch(db);

    batch.set(pageRef, {
      slug: payload.slug,
      title: payload.title,
      bodyMarkdown: payload.bodyMarkdown,
      version: draftVersion,
      isPublished: false,
      publishedVersion: 0,
      publishedTitle: '',
      publishedBodyMarkdown: '',
      publishedAt: null,
      publishedByUid: '',
      publishedByEmail: '',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
      ...getCreateMetadata(),
    });
    await persistVersionSnapshot(batch, payload.slug, draftVersion, payload);

    try {
      await withTimeout(
        batch.commit(),
        'Saving the CMS page is taking too long. Check your Firestore rules or network connection and try again.',
      );
    } catch (error) {
      console.error('Unable to create CMS page.', error);
      throw new Error(resolveErrorMessage(error, 'create'));
    }
  },

  async update(id, values) {
    const slug = normalizeCmsPageSlug(id);
    const payload = createCmsPageDraft({ ...values, slug });

    if (!slug) {
      throw new Error('Unable to update this CMS page because the slug is missing.');
    }

    const currentVersion = Number.parseInt(values.version, 10) || 0;
    const nextVersion = Math.max(currentVersion + 1, 1);
    const batch = writeBatch(db);

    batch.update(getPageRef(slug), {
      title: payload.title,
      bodyMarkdown: payload.bodyMarkdown,
      version: nextVersion,
      updatedAt: serverTimestamp(),
      ...getActorMetadata(),
    });
    await persistVersionSnapshot(batch, slug, nextVersion, payload);

    try {
      await withTimeout(
        batch.commit(),
        'Updating the CMS page is taking too long. Check your Firestore rules or network connection and try again.',
      );
    } catch (error) {
      console.error(`Unable to update CMS page ${slug}.`, error);
      throw new Error(resolveErrorMessage(error, 'update'));
    }
  },

  async publish(slug) {
    const normalizedSlug = normalizeCmsPageSlug(slug);
    if (!normalizedSlug) {
      throw new Error('Unable to publish this CMS page because the slug is missing.');
    }

    try {
      const snapshot = await getDoc(getPageRef(normalizedSlug));
      if (!snapshot.exists()) {
        throw new Error('This CMS page no longer exists.');
      }

      const data = snapshot.data();
      const version = Number.parseInt(data.version, 10) || 1;
      const payload = createCmsPageDraft({
        slug: normalizedSlug,
        title: data.title,
        bodyMarkdown: data.bodyMarkdown,
      });
      const actorMetadata = getActorMetadata();
      const batch = writeBatch(db);

      batch.update(getPageRef(normalizedSlug), {
        isPublished: true,
        publishedTitle: payload.title,
        publishedBodyMarkdown: payload.bodyMarkdown,
        publishedVersion: version,
        publishedAt: serverTimestamp(),
        ...(actorMetadata.updatedByUid ? { publishedByUid: actorMetadata.updatedByUid } : {}),
        ...(actorMetadata.updatedByEmail ? { publishedByEmail: actorMetadata.updatedByEmail } : {}),
        updatedAt: serverTimestamp(),
        ...actorMetadata,
      });
      await persistVersionSnapshot(batch, normalizedSlug, version, payload, { isPublished: true });

      await withTimeout(
        batch.commit(),
        'Publishing the CMS page is taking too long. Check your Firestore rules or network connection and try again.',
      );
    } catch (error) {
      console.error(`Unable to publish CMS page ${normalizedSlug}.`, error);
      throw new Error(resolveErrorMessage(error, 'publish'));
    }
  },

  async unpublish(slug) {
    const normalizedSlug = normalizeCmsPageSlug(slug);
    if (!normalizedSlug) {
      throw new Error('Unable to unpublish this CMS page because the slug is missing.');
    }

    try {
      await withTimeout(
        updateDoc(getPageRef(normalizedSlug), {
          isPublished: false,
          updatedAt: serverTimestamp(),
          ...getActorMetadata(),
        }),
        'Unpublishing the CMS page is taking too long. Check your Firestore rules or network connection and try again.',
      );
    } catch (error) {
      console.error(`Unable to unpublish CMS page ${normalizedSlug}.`, error);
      throw new Error(resolveErrorMessage(error, 'unpublish'));
    }
  },

  async remove(slug) {
    const normalizedSlug = normalizeCmsPageSlug(slug);
    if (!normalizedSlug) {
      throw new Error('Unable to delete this CMS page because the slug is missing.');
    }

    try {
      const versionsSnapshot = await getDocs(collection(db, COLLECTION_NAME, normalizedSlug, 'versions'));
      const batch = writeBatch(db);

      versionsSnapshot.docs.forEach((record) => {
        batch.delete(record.ref);
      });
      batch.delete(getPageRef(normalizedSlug));

      await withTimeout(
        batch.commit(),
        'Deleting the CMS page is taking too long. Check your Firestore rules or network connection and try again.',
      );
    } catch (error) {
      console.error(`Unable to delete CMS page ${normalizedSlug}.`, error);
      throw new Error(resolveErrorMessage(error, 'delete'));
    }
  },
};
