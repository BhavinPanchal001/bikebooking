import { useEffect, useState } from 'react';
import {
  collection,
  collectionGroup,
  getDocs,
  orderBy,
  query,
} from 'firebase/firestore';
import { mockAdminData } from '../data/mockData';
import { db, hasFirebaseConfig } from '../lib/firebase';

const emptyAdminData = {
  users: [],
  listings: [],
  conversations: [],
  reports: [],
  reviews: [],
  notifications: [],
  blockedUsers: [],
};

function createEmptySnapshot({
  source = 'firebase',
  loading = true,
  error = '',
} = {}) {
  return {
    source,
    error,
    loading,
    lastUpdated: null,
    users: [],
    listings: [],
    conversations: [],
    reports: [],
    reviews: [],
    notifications: [],
    blockedUsers: [],
    categoryBreakdown: [],
    brandLeaders: [],
    recentActivity: [],
    metrics: {
      totalUsers: 0,
      activeListings: 0,
      soldListings: 0,
      openReports: 0,
      unreadChats: 0,
      unreadNotifications: 0,
      verifiedUsers: 0,
      incompleteUsers: 0,
      estimatedRevenue: 0,
      averageActivePrice: 0,
      approvalQueue: 0,
      flaggedListings: 0,
      blockedUsers: 0,
      totalChats: 0,
    },
  };
}

function toIsoString(value) {
  if (!value) {
    return null;
  }

  if (typeof value?.toDate === 'function') {
    return value.toDate().toISOString();
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

function sortByNewest(items, key) {
  return [...items].sort((first, second) => {
    const firstDate = new Date(first[key] ?? 0).getTime();
    const secondDate = new Date(second[key] ?? 0).getTime();
    return secondDate - firstDate;
  });
}

function deriveModerationStatus(listing, reports) {
  const hasOpenReport = reports.some(
    (report) =>
      report.sellerId === listing.sellerId &&
      ['open', 'reviewing', 'pending'].includes(report.status),
  );

  if (hasOpenReport) {
    return 'flagged';
  }
  if (listing.status === 'sold') {
    return 'closed';
  }

  return 'approved';
}

function buildAdminSnapshot(raw, source, error = '') {
  const listings = sortByNewest(raw.listings, 'createdAt').map((listing) => ({
    ...listing,
    moderationStatus: deriveModerationStatus(listing, raw.reports),
  }));

  const reviewsBySeller = raw.reviews.reduce((accumulator, review) => {
    const current = accumulator.get(review.sellerId) ?? [];
    current.push(review);
    accumulator.set(review.sellerId, current);
    return accumulator;
  }, new Map());

  const users = sortByNewest(raw.users, 'joinedAt').map((user) => {
    const ownedListings = listings.filter((listing) => listing.sellerId === user.id);
    const soldListings = ownedListings.filter((listing) => listing.status === 'sold');
    const reviews = reviewsBySeller.get(user.id) ?? [];
    const averageRating =
      reviews.length > 0
        ? reviews.reduce((sum, review) => sum + review.rating, 0) / reviews.length
        : 0;

    return {
      ...user,
      activeListings: ownedListings.filter((listing) => listing.status === 'active').length,
      soldListings: soldListings.length,
      totalSales: soldListings.reduce((sum, listing) => sum + (listing.price ?? 0), 0),
      rating: averageRating,
      verificationStatus: user.phoneNumber ? 'verified' : 'incomplete',
    };
  });

  const conversations = sortByNewest(raw.conversations, 'updatedAt');
  const reports = sortByNewest(raw.reports, 'createdAt');
  const reviews = sortByNewest(raw.reviews, 'createdAt');
  const notifications = sortByNewest(raw.notifications ?? [], 'createdAt');
  const blockedUsers = sortByNewest(raw.blockedUsers ?? [], 'blockedAt');

  const totalRevenue = listings
    .filter((listing) => listing.status === 'sold')
    .reduce((sum, listing) => sum + (listing.price ?? 0), 0);
  const averageActivePrice =
    listings.filter((listing) => listing.status === 'active').reduce(
      (sum, listing, index, items) => sum + (listing.price ?? 0) / (items.length || 1),
      0,
    ) || 0;
  const verifiedUsers = users.filter((user) => user.verificationStatus === 'verified').length;
  const unreadNotifications = notifications.filter((notification) => !notification.isRead).length;

  const categoryCounts = listings.reduce((accumulator, listing) => {
    accumulator[listing.category] = (accumulator[listing.category] ?? 0) + 1;
    return accumulator;
  }, {});

  const brandCounts = listings.reduce((accumulator, listing) => {
    accumulator[listing.brand] = (accumulator[listing.brand] ?? 0) + 1;
    return accumulator;
  }, {});

  const recentActivity = sortByNewest(
    [
      ...listings.slice(0, 4).map((listing) => ({
        id: `listing-${listing.id}`,
        type: 'Listing',
        title: listing.title,
        meta: `${listing.sellerName} listed ${listing.category}`,
        timestamp: listing.createdAt,
      })),
      ...reports.slice(0, 3).map((report) => ({
        id: `report-${report.id}`,
        type: 'Report',
        title: report.reason,
        meta: `${report.sellerName} needs moderation`,
        timestamp: report.createdAt,
      })),
      ...conversations.slice(0, 3).map((chat) => ({
        id: `chat-${chat.id}`,
        type: 'Chat',
        title: chat.productTitle,
        meta: chat.lastMessage,
        timestamp: chat.updatedAt,
      })),
      ...notifications.slice(0, 3).map((notification) => ({
        id: `notification-${notification.id}`,
        type: 'Notification',
        title: notification.title,
        meta: notification.body,
        timestamp: notification.createdAt,
      })),
    ],
    'timestamp',
  ).slice(0, 6);

  return {
    source,
    error,
    loading: false,
    lastUpdated: new Date().toISOString(),
    listings,
    users,
    conversations,
    reports,
    reviews,
    notifications,
    blockedUsers,
    categoryBreakdown: Object.entries(categoryCounts)
      .map(([label, count]) => ({ label, count }))
      .sort((first, second) => second.count - first.count),
    brandLeaders: Object.entries(brandCounts)
      .map(([label, count]) => ({ label, count }))
      .sort((first, second) => second.count - first.count)
      .slice(0, 5),
    recentActivity,
    metrics: {
      totalUsers: users.length,
      activeListings: listings.filter((listing) => listing.status === 'active').length,
      soldListings: listings.filter((listing) => listing.status === 'sold').length,
      openReports: reports.filter((report) => report.status !== 'resolved').length,
      unreadChats: conversations.reduce((sum, chat) => sum + (chat.unread ?? 0), 0),
      unreadNotifications,
      verifiedUsers,
      incompleteUsers: users.length - verifiedUsers,
      estimatedRevenue: totalRevenue,
      averageActivePrice,
      approvalQueue: listings.filter((listing) => listing.moderationStatus === 'pending').length,
      flaggedListings: listings.filter((listing) => listing.moderationStatus === 'flagged').length,
      blockedUsers: blockedUsers.length,
      totalChats: conversations.length,
    },
  };
}

async function loadCollection(path, sortField) {
  try {
    if (sortField) {
      const snapshot = await getDocs(query(collection(db, path), orderBy(sortField, 'desc')));
      return snapshot.docs;
    }
  } catch (error) {
    console.warn(`Falling back to unordered read for ${path}.`, error);
  }

  const snapshot = await getDocs(collection(db, path));
  return snapshot.docs;
}

async function loadCollectionGroup(groupName, sortField) {
  try {
    const snapshot = await getDocs(
      query(collectionGroup(db, groupName), orderBy(sortField, 'desc')),
    );
    return snapshot.docs;
  } catch (error) {
    console.warn(`Unable to read collection group ${groupName}.`, error);
    return [];
  }
}

async function loadCollectionResult(name, loader) {
  try {
    const docs = await loader();
    return {
      name,
      ok: true,
      docs,
      error: '',
    };
  } catch (error) {
    console.error(`Unable to load ${name}.`, error);
    return {
      name,
      ok: false,
      docs: [],
      error: error?.message || `Unable to load ${name}.`,
    };
  }
}

async function fetchFirebaseAdminData() {
  const results = await Promise.all([
    loadCollectionResult('users', () => loadCollection('users', 'updatedAt')),
    loadCollectionResult('products', () => loadCollection('products', 'updatedAt')),
    loadCollectionResult('chats', () => loadCollection('chats', 'updatedAt')),
    loadCollectionResult('seller_reports', () => loadCollection('seller_reports', 'createdAt')),
    loadCollectionResult('reviews', () => loadCollectionGroup('reviews', 'createdAt')),
    loadCollectionResult('notifications', () => loadCollectionGroup('notifications', 'createdAt')),
    loadCollectionResult('user_blocks', () => loadCollection('user_blocks', 'blockedAt')),
  ]);

  const resultMap = Object.fromEntries(results.map((result) => [result.name, result]));
  const loadErrors = results
    .filter((result) => !result.ok)
    .map((result) => result.name);

  const userDocs = resultMap.users.docs;
  const productDocs = resultMap.products.docs;
  const chatDocs = resultMap.chats.docs;
  const reportDocs = resultMap.seller_reports.docs;
  const reviewDocs = resultMap.reviews.docs;
  const notificationDocs = resultMap.notifications.docs;
  const blockedUserDocs = resultMap.user_blocks.docs;

  return {
    source:
      loadErrors.length > 0 && loadErrors.length < results.length ? 'firebase-partial' : 'firebase',
    error:
      loadErrors.length > 0
        ? `Some Firestore collections could not be read: ${loadErrors.join(', ')}.`
        : '',
    users: userDocs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        fullName: data.fullName?.toString().trim() || data.phoneNumber?.toString().trim() || 'User',
        email: data.email?.toString().trim() ?? '',
        phoneNumber: data.phoneNumber?.toString().trim() ?? '',
        photoUrl: data.photoUrl?.toString().trim() ?? '',
        joinedAt: toIsoString(data.createdAt) ?? toIsoString(data.updatedAt),
        location:
          data.location && typeof data.location === 'object'
            ? { address: data.location.address?.toString().trim() ?? '' }
            : null,
      };
    }),
    listings: productDocs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        category: data.category?.toString().trim() ?? 'Uncategorized',
        title: data.title?.toString().trim() ?? 'Untitled listing',
        brand: data.brand?.toString().trim() ?? 'Unknown',
        description: data.description?.toString().trim() ?? '',
        price: typeof data.price === 'number' ? data.price : Number(data.price ?? 0),
        location: data.location?.toString().trim() ?? 'Unknown',
        sellerId: data.sellerId?.toString().trim() ?? '',
        sellerName: data.sellerName?.toString().trim() ?? 'Seller',
        year: typeof data.year === 'number' ? data.year : Number(data.year ?? 0) || null,
        status: data.status?.toString().trim().toLowerCase() ?? 'active',
        createdAt: toIsoString(data.createdAt) ?? toIsoString(data.updatedAt),
        updatedAt: toIsoString(data.updatedAt) ?? toIsoString(data.createdAt),
        views: Number(data.views ?? 0),
        inquiries: Number(data.inquiries ?? 0),
        imageUrls: Array.isArray(data.imageUrls) ? data.imageUrls : [],
        fuelType: data.fuelType?.toString().trim() ?? '',
        kilometerDriven:
          typeof data.kilometerDriven === 'number'
            ? data.kilometerDriven
            : Number(data.kilometerDriven ?? 0) || null,
        numberOfOwners:
          typeof data.numberOfOwners === 'number'
            ? data.numberOfOwners
            : Number(data.numberOfOwners ?? 0) || null,
        subCategory: data.subCategory?.toString().trim() ?? '',
        condition: data.condition?.toString().trim() ?? '',
        sellerType: data.sellerType?.toString().trim() ?? '',
      };
    }),
    conversations: chatDocs.map((doc) => {
      const data = doc.data();
      const participants = Object.values(data.participantDetails ?? {}).map((entry) => {
        if (entry && typeof entry === 'object') {
          return entry.name?.toString().trim() || entry.phoneNumber?.toString().trim() || 'User';
        }
        return 'User';
      });
      const unread = Object.values(data.unreadCount ?? {}).reduce(
        (sum, value) => sum + Number(value ?? 0),
        0,
      );

      return {
        id: doc.id,
        participantNames: participants.slice(0, 2),
        productTitle:
          data.productSnapshot?.title?.toString().trim() ??
          data.productSnapshot?.productId?.toString().trim() ??
          'Product chat',
        lastMessage: data.lastMessage?.text?.toString().trim() ?? 'No message yet',
        unread,
        flagged: unread >= 5,
        updatedAt: toIsoString(data.updatedAt) ?? toIsoString(data.lastMessage?.timestamp),
      };
    }),
    reports: reportDocs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        sellerId: data.sellerId?.toString().trim() ?? '',
        sellerName: data.sellerName?.toString().trim() ?? 'Seller',
        reason: data.reason?.toString().trim() ?? 'Seller report',
        priority: data.priority?.toString().trim().toLowerCase() ?? 'medium',
        status: data.status?.toString().trim().toLowerCase() ?? 'open',
        createdAt: toIsoString(data.createdAt) ?? toIsoString(data.updatedAt),
      };
    }),
    reviews: reviewDocs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        sellerId: data.sellerId?.toString().trim() ?? '',
        reviewerName: data.reviewerName?.toString().trim() ?? 'Reviewer',
        rating: Number(data.rating ?? 0),
        comment: data.comment?.toString().trim() ?? '',
        createdAt: toIsoString(data.createdAt) ?? toIsoString(data.updatedAt),
      };
    }),
    notifications: notificationDocs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        recipientId: data.recipientId?.toString().trim() ?? '',
        title: data.title?.toString().trim() ?? 'Notification',
        body: data.body?.toString().trim() ?? '',
        type: data.type?.toString().trim() ?? 'system',
        isRead: data.isRead === true,
        senderName: data.senderName?.toString().trim() ?? '',
        createdAt: toIsoString(data.createdAt) ?? toIsoString(data.updatedAt),
      };
    }),
    blockedUsers: blockedUserDocs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        blockerId: data.blockerId?.toString().trim() ?? '',
        blockedUserId: data.blockedUserId?.toString().trim() ?? '',
        sellerName:
          data.sellerName?.toString().trim() ||
          data.fullName?.toString().trim() ||
          'Blocked user',
        photoUrl: data.photoUrl?.toString().trim() ?? '',
        blockedAt: toIsoString(data.blockedAt) ?? toIsoString(data.updatedAt),
      };
    }),
  };
}

export function useAdminData({ enabled = true } = {}) {
  const [state, setState] = useState(() =>
    enabled && hasFirebaseConfig
      ? createEmptySnapshot({ source: 'firebase', loading: true })
      : createEmptySnapshot({ source: 'mock', loading: false }),
  );

  useEffect(() => {
    let isCancelled = false;

    async function hydrate() {
      if (!enabled) {
        if (!isCancelled) {
          setState(createEmptySnapshot({ source: 'mock', loading: false }));
        }
        return;
      }

      if (!hasFirebaseConfig) {
        if (!isCancelled) {
          setState({
            ...buildAdminSnapshot(mockAdminData, 'mock'),
            loading: false,
          });
        }
        return;
      }

      if (!isCancelled) {
        setState(createEmptySnapshot({ source: 'firebase', loading: true }));
      }

      try {
        const firebaseData = await fetchFirebaseAdminData();
        if (!isCancelled) {
          setState(
            buildAdminSnapshot(
              {
                ...emptyAdminData,
                ...firebaseData,
              },
              firebaseData.source,
              firebaseData.error,
            ),
          );
        }
      } catch (error) {
        console.error('Unable to load Firebase admin data.', error);
        if (!isCancelled) {
          setState(
            createEmptySnapshot({
              source: 'firebase-partial',
              loading: false,
              error: 'Firebase data could not be loaded for the admin panel.',
            }),
          );
        }
      }
    }

    hydrate();

    return () => {
      isCancelled = true;
    };
  }, [enabled]);

  return state;
}
