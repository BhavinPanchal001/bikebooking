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
      ['open', 'reviewing'].includes(report.status),
  );

  if (hasOpenReport) {
    return 'flagged';
  }
  if (listing.status === 'sold') {
    return 'closed';
  }

  const createdAt = new Date(listing.createdAt ?? 0).getTime();
  const hoursSinceCreated = (Date.now() - createdAt) / (1000 * 60 * 60);
  if (Number.isFinite(hoursSinceCreated) && hoursSinceCreated < 36) {
    return 'pending';
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
      verificationStatus:
        user.email && user.phoneNumber && user.location?.address ? 'verified' : 'incomplete',
    };
  });

  const conversations = sortByNewest(raw.conversations, 'updatedAt');
  const reports = sortByNewest(raw.reports, 'createdAt');
  const reviews = sortByNewest(raw.reviews, 'createdAt');

  const totalRevenue = listings
    .filter((listing) => listing.status === 'sold')
    .reduce((sum, listing) => sum + (listing.price ?? 0), 0);

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
      estimatedRevenue: totalRevenue,
      approvalQueue: listings.filter((listing) => listing.moderationStatus === 'pending').length,
      flaggedListings: listings.filter((listing) => listing.moderationStatus === 'flagged').length,
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

async function fetchFirebaseAdminData() {
  const [userDocs, productDocs, chatDocs, reportDocs, reviewDocs] = await Promise.all([
    loadCollection('users', 'updatedAt').catch(() => []),
    loadCollection('products', 'updatedAt'),
    loadCollection('chats', 'updatedAt').catch(() => []),
    loadCollection('seller_reports', 'createdAt').catch(() => []),
    loadCollectionGroup('reviews', 'createdAt').catch(() => []),
  ]);

  return {
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
        price: typeof data.price === 'number' ? data.price : Number(data.price ?? 0),
        location: data.location?.toString().trim() ?? 'Unknown',
        sellerId: data.sellerId?.toString().trim() ?? '',
        sellerName: data.sellerName?.toString().trim() ?? 'Seller',
        status: data.status?.toString().trim().toLowerCase() ?? 'active',
        createdAt: toIsoString(data.createdAt) ?? toIsoString(data.updatedAt),
        views: Number(data.views ?? 0),
        inquiries: Number(data.inquiries ?? 0),
        imageUrls: Array.isArray(data.imageUrls) ? data.imageUrls : [],
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
  };
}

export function useAdminData({ enabled = true } = {}) {
  const [state, setState] = useState({
    ...buildAdminSnapshot(mockAdminData, 'mock'),
    loading: true,
  });

  useEffect(() => {
    let isCancelled = false;

    async function hydrate() {
      if (!enabled) {
        if (!isCancelled) {
          setState({
            ...buildAdminSnapshot(mockAdminData, 'mock'),
            loading: false,
          });
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

      try {
        const firebaseData = await fetchFirebaseAdminData();
        if (!isCancelled) {
          setState(buildAdminSnapshot(firebaseData, 'firebase'));
        }
      } catch (error) {
        console.error('Unable to load Firebase admin data.', error);
        if (!isCancelled) {
          setState(
            buildAdminSnapshot(
              mockAdminData,
              'mock',
              'Firebase data could not be loaded, so the demo dataset is shown.',
            ),
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
