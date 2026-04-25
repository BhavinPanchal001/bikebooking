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
    reportedUsers: [],
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
      reportedUsers: 0,
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

function getTimestamp(value) {
  if (!value) {
    return 0;
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? 0 : date.getTime();
}

function sortItemsByNewest(items, getValue) {
  return [...items].sort(
    (first, second) => getTimestamp(getValue(second)) - getTimestamp(getValue(first)),
  );
}

function getReportTargetId(report) {
  return (
    report.sellerId ||
    report.userId ||
    report.reportedUserId ||
    report.reportedPersonId ||
    ''
  )
    .toString()
    .trim();
}

function getReportTargetName(report) {
  return (
    report.sellerName ||
    report.userName ||
    report.reportedUserName ||
    report.reportedPersonName ||
    'Unknown user'
  );
}

function isOpenReport(report) {
  const normalizedStatus = String(report.status || '')
    .trim()
    .toLowerCase();

  return !['resolved', 'closed', 'dismissed'].includes(normalizedStatus);
}

function normalizePriority(priority, reason = '', details = '') {
  const normalizedPriority = String(priority || '')
    .trim()
    .toLowerCase();

  if (['high', 'medium', 'low'].includes(normalizedPriority)) {
    return normalizedPriority;
  }

  const priorityText = `${reason} ${details}`.toLowerCase();
  if (
    priorityText.includes('fraud') ||
    priorityText.includes('scam') ||
    priorityText.includes('abusive')
  ) {
    return 'high';
  }

  if (
    priorityText.includes('misleading') ||
    priorityText.includes('fake') ||
    priorityText.includes('spam')
  ) {
    return 'medium';
  }

  return 'low';
}

function getPriorityScore(priority) {
  switch (String(priority || '').trim().toLowerCase()) {
    case 'high':
      return 3;
    case 'medium':
      return 2;
    case 'low':
      return 1;
    default:
      return 0;
  }
}

function normalizeVerificationStatus(user) {
  const explicitStatus = String(user.verificationStatus || '')
    .trim()
    .toLowerCase();

  if (explicitStatus) {
    return explicitStatus;
  }

  return user.phoneNumber || user.registeredMobileNumber ? 'verified' : 'incomplete';
}

function deriveModerationStatus(listing, reports) {
  const manualStatus = String(listing.adminReviewStatus || '')
    .trim()
    .toLowerCase();
  const hasOpenReport = reports.some(
    (report) => report.sellerId === listing.sellerId && isOpenReport(report),
  );

  if (listing.status === 'sold' || manualStatus === 'closed') {
    return 'closed';
  }

  if (manualStatus === 'flagged') {
    return 'flagged';
  }

  if (manualStatus === 'pending') {
    return 'pending';
  }

  if (manualStatus === 'approved') {
    return 'approved';
  }

  return hasOpenReport ? 'flagged' : 'approved';
}

function buildAdminSnapshot(raw, source, error = '') {
  const reports = sortItemsByNewest(raw.reports || [], (report) => report.updatedAt || report.createdAt)
    .map((report) => ({
      ...report,
      priority: normalizePriority(report.priority, report.reason, report.details),
      status: String(report.status || 'pending').trim().toLowerCase() || 'pending',
    }));
  const listings = sortItemsByNewest(raw.listings || [], (listing) => listing.updatedAt || listing.createdAt)
    .map((listing) => ({
      ...listing,
      moderationStatus: deriveModerationStatus(listing, reports),
    }));
  const conversations = sortItemsByNewest(raw.conversations || [], (conversation) => conversation.updatedAt);
  const reviews = sortItemsByNewest(raw.reviews || [], (review) => review.updatedAt || review.createdAt);
  const notifications = sortItemsByNewest(raw.notifications || [], (notification) => notification.updatedAt || notification.createdAt);
  const blockedUsers = sortItemsByNewest(raw.blockedUsers || [], (entry) => entry.blockedAt || entry.updatedAt);

  const activeListingsBySeller = new Map();
  const totalSalesBySeller = new Map();
  const ratingBySeller = new Map();
  const reportSummaryByUser = new Map();

  listings.forEach((listing) => {
    if (!listing?.sellerId) {
      return;
    }

    if (listing.status === 'active') {
      activeListingsBySeller.set(
        listing.sellerId,
        (activeListingsBySeller.get(listing.sellerId) ?? 0) + 1,
      );
    }

    if (listing.status === 'sold') {
      totalSalesBySeller.set(
        listing.sellerId,
        (totalSalesBySeller.get(listing.sellerId) ?? 0) + (listing.price ?? 0),
      );
    }
  });

  reviews.forEach((review) => {
    if (!review?.sellerId || typeof review.rating !== 'number') {
      return;
    }

    const sellerRating = ratingBySeller.get(review.sellerId) ?? {
      total: 0,
      count: 0,
    };

    sellerRating.total += review.rating;
    sellerRating.count += 1;
    ratingBySeller.set(review.sellerId, sellerRating);
  });

  reports.forEach((report) => {
    const targetId = getReportTargetId(report);
    if (!targetId) {
      return;
    }

    const existingSummary = reportSummaryByUser.get(targetId) ?? {
      id: targetId,
      fullName: getReportTargetName(report),
      reportCount: 0,
      openReportCount: 0,
      latestReportAt: '',
      latestStatus: '',
      highestPriority: 'low',
      reasons: new Set(),
      reporterNames: new Set(),
      reports: [],
    };

    existingSummary.reportCount += 1;
    if (isOpenReport(report)) {
      existingSummary.openReportCount += 1;
    }

    const reportTimestamp = report.updatedAt || report.createdAt;
    if (getTimestamp(reportTimestamp) >= getTimestamp(existingSummary.latestReportAt)) {
      existingSummary.latestReportAt = reportTimestamp;
      existingSummary.latestStatus = report.status || 'pending';
      existingSummary.fullName = getReportTargetName(report);
    }

    if (
      getPriorityScore(report.priority) >=
      getPriorityScore(existingSummary.highestPriority)
    ) {
      existingSummary.highestPriority = report.priority;
    }

    if (report.reason) {
      existingSummary.reasons.add(report.reason);
    }

    if (report.reporterName) {
      existingSummary.reporterNames.add(report.reporterName);
    }

    existingSummary.reports.push(report);
    reportSummaryByUser.set(targetId, existingSummary);
  });

  const users = sortItemsByNewest(raw.users || [], (user) => user.joinedAt || user.updatedAt || user.createdAt)
    .map((user) => {
      const reportSummary = reportSummaryByUser.get(user.id);
      const ratingSummary = ratingBySeller.get(user.id);

      return {
        ...user,
        fullName: user.fullName || user.displayName || user.phoneNumber || user.id,
        accountStatus: user.accountStatus || 'active',
        verificationStatus: normalizeVerificationStatus(user),
        activeListings:
          typeof user.activeListings === 'number'
            ? user.activeListings
            : activeListingsBySeller.get(user.id) ?? 0,
        totalSales:
          typeof user.totalSales === 'number'
            ? user.totalSales
            : totalSalesBySeller.get(user.id) ?? 0,
        rating:
          typeof user.rating === 'number'
            ? user.rating
            : ratingSummary?.count
              ? ratingSummary.total / ratingSummary.count
              : 0,
        reportCount: reportSummary?.reportCount ?? 0,
        openReportCount: reportSummary?.openReportCount ?? 0,
        latestReportAt: reportSummary?.latestReportAt ?? '',
        latestReportStatus: reportSummary?.latestStatus ?? '',
        reportReasons: reportSummary ? Array.from(reportSummary.reasons) : [],
        reporterNames: reportSummary ? Array.from(reportSummary.reporterNames) : [],
      };
    });

  const userMap = new Map(users.map((user) => [user.id, user]));
  const reportedUsers = Array.from(reportSummaryByUser.values())
    .map((summary) => {
      const user = userMap.get(summary.id);
      const latestReport = sortItemsByNewest(summary.reports, (report) => report.updatedAt || report.createdAt)[0];

      return {
        ...(user || {}),
        id: summary.id,
        fullName: user?.fullName || summary.fullName,
        email: user?.email || '',
        phoneNumber: user?.phoneNumber || user?.registeredMobileNumber || '',
        location: user?.location || null,
        accountStatus: user?.accountStatus || 'active',
        verificationStatus: user?.verificationStatus || 'incomplete',
        activeListings: user?.activeListings ?? 0,
        totalSales: user?.totalSales ?? 0,
        rating: user?.rating ?? 0,
        reportCount: summary.reportCount,
        openReportCount: summary.openReportCount,
        latestReportAt: summary.latestReportAt,
        latestReportStatus: summary.latestStatus,
        highestPriority:
          summary.openReportCount > 1 && getPriorityScore(summary.highestPriority) < 3
            ? 'high'
            : summary.highestPriority,
        reportReasons: Array.from(summary.reasons).slice(0, 3),
        reporterNames: Array.from(summary.reporterNames).slice(0, 3),
        reporterCount: summary.reporterNames.size,
        latestReason: latestReport?.reason || Array.from(summary.reasons)[0] || '',
        latestDetails: latestReport?.details || '',
        reports: sortItemsByNewest(summary.reports, (report) => report.updatedAt || report.createdAt),
      };
    })
    .sort((first, second) => {
      if (second.openReportCount !== first.openReportCount) {
        return second.openReportCount - first.openReportCount;
      }

      if (second.reportCount !== first.reportCount) {
        return second.reportCount - first.reportCount;
      }

      return getTimestamp(second.latestReportAt) - getTimestamp(first.latestReportAt);
    });

  const categoryCounts = listings.reduce((accumulator, listing) => {
    accumulator[listing.category] = (accumulator[listing.category] ?? 0) + 1;
    return accumulator;
  }, {});

  const brandCounts = listings.reduce((accumulator, listing) => {
    accumulator[listing.brand] = (accumulator[listing.brand] ?? 0) + 1;
    return accumulator;
  }, {});

  const recentActivity = sortItemsByNewest(
    [
      ...listings.map((listing) => ({
        id: `listing:${listing.id}`,
        type: 'listing',
        title: listing.title || 'Listing updated',
        meta: `${listing.sellerName || 'Unknown seller'} · ${listing.status || 'draft'}`,
        timestamp: listing.updatedAt || listing.createdAt,
      })),
      ...reports.map((report) => ({
        id: `report:${report.id}`,
        type: 'report',
        title: getReportTargetName(report),
        meta: `${report.reason || 'Seller report'} · ${report.status || 'pending'}`,
        timestamp: report.updatedAt || report.createdAt,
      })),
      ...conversations.map((conversation) => ({
        id: `chat:${conversation.id}`,
        type: 'chat',
        title: conversation.productTitle || 'Conversation updated',
        meta: conversation.participantNames?.join(' · ') || 'Marketplace chat',
        timestamp: conversation.updatedAt,
      })),
      ...notifications.map((notification) => ({
        id: `notification:${notification.id}`,
        type: 'notification',
        title: notification.title || notification.type || 'Notification sent',
        meta: notification.body || notification.recipientId || 'User alert',
        timestamp: notification.updatedAt || notification.createdAt,
      })),
    ].filter((item) => item.timestamp),
    (item) => item.timestamp,
  ).slice(0, 8);

  const verifiedUsers = users.filter(
    (user) => user.verificationStatus === 'verified',
  ).length;
  const activeListings = listings.filter((listing) => listing.status === 'active');

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
    reportedUsers,
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
      activeListings: activeListings.length,
      soldListings: listings.filter((listing) => listing.status === 'sold').length,
      openReports: reports.filter((report) => isOpenReport(report)).length,
      unreadChats: conversations.reduce((sum, chat) => sum + (chat.unread ?? 0), 0),
      unreadNotifications: notifications.filter((notification) => !notification.isRead).length,
      verifiedUsers,
      incompleteUsers: users.length - verifiedUsers,
      estimatedRevenue: listings
        .filter((listing) => listing.status === 'sold')
        .reduce((sum, listing) => sum + (listing.price ?? 0), 0),
      averageActivePrice:
        activeListings.length > 0
          ? Math.round(
              activeListings.reduce((sum, listing) => sum + (listing.price ?? 0), 0) /
                activeListings.length,
            )
          : 0,
      approvalQueue: listings.filter((listing) => listing.moderationStatus === 'pending').length,
      flaggedListings: listings.filter((listing) => listing.moderationStatus === 'flagged').length,
      blockedUsers: blockedUsers.length,
      reportedUsers: reportedUsers.length,
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
    loadCollectionResult('seller_reports', () => loadCollection('seller_reports', 'updatedAt')),
    loadCollectionResult('reviews', () => loadCollectionGroup('reviews', 'updatedAt')),
    loadCollectionResult('notifications', () => loadCollectionGroup('notifications', 'updatedAt')),
    loadCollectionResult('user_blocks', () => loadCollection('user_blocks', 'updatedAt')),
  ]);

  const resultMap = Object.fromEntries(results.map((result) => [result.name, result]));
  const loadErrors = results
    .filter((result) => !result.ok)
    .map((result) => result.name);

  return {
    source:
      loadErrors.length > 0 && loadErrors.length < results.length ? 'firebase-partial' : 'firebase',
    error:
      loadErrors.length > 0
        ? `Some Firestore collections could not be read: ${loadErrors.join(', ')}.`
        : '',
    users: resultMap.users.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        fullName:
          data.fullName?.toString().trim() ||
          data.phoneNumber?.toString().trim() ||
          'User',
        email: data.email?.toString().trim() ?? '',
        phoneNumber: data.phoneNumber?.toString().trim() ?? '',
        registeredMobileNumber: data.registeredMobileNumber?.toString().trim() ?? '',
        photoUrl: data.photoUrl?.toString().trim() ?? '',
        joinedAt: toIsoString(data.createdAt) ?? toIsoString(data.updatedAt),
        createdAt: toIsoString(data.createdAt),
        updatedAt: toIsoString(data.updatedAt),
        accountStatus:
          data.adminBlocked === true ||
          data.accountStatus?.toString().trim().toLowerCase() === 'blocked'
            ? 'blocked'
            : 'active',
        verificationStatus:
          data.verificationStatus?.toString().trim().toLowerCase() || '',
        adminBlockedAt: toIsoString(data.adminBlockedAt) ?? null,
        adminBlockedBy: data.adminBlockedBy?.toString().trim() ?? '',
        location:
          data.location && typeof data.location === 'object'
            ? { address: data.location.address?.toString().trim() ?? '' }
            : null,
      };
    }),
    listings: resultMap.products.docs.map((doc) => {
      const data = doc.data();
      const priceValue =
        typeof data.price === 'number' ? data.price : Number(data.price ?? 0);

      return {
        id: doc.id,
        category: data.category?.toString().trim() ?? 'Uncategorized',
        title: data.title?.toString().trim() ?? 'Untitled listing',
        brand: data.brand?.toString().trim() ?? 'Unknown',
        description: data.description?.toString().trim() ?? '',
        price: Number.isFinite(priceValue) ? priceValue : 0,
        location: data.location?.toString().trim() ?? 'Unknown',
        sellerId: data.sellerId?.toString().trim() ?? '',
        sellerName: data.sellerName?.toString().trim() ?? 'Seller',
        year:
          typeof data.year === 'number' ? data.year : Number(data.year ?? 0) || null,
        status: data.status?.toString().trim().toLowerCase() ?? 'active',
        adminReviewStatus:
          data.adminReviewStatus?.toString().trim().toLowerCase() ?? '',
        moderatedAt: toIsoString(data.moderatedAt) ?? null,
        moderatedBy: data.moderatedBy?.toString().trim() ?? '',
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
        isBoosted: data.isBoosted === true,
        boostPlanId: data.boostPlanId?.toString().trim() ?? '',
        boostGrantSource: data.boostGrantSource?.toString().trim() ?? '',
        boostGrantedByEmail:
          data.boostGrantedByEmail?.toString().trim() ?? '',
        boostStartedAt: toIsoString(data.boostStartedAt),
        boostExpiresAt: toIsoString(data.boostExpiresAt),
        isEditorialFeatured: data.isEditorialFeatured === true,
        editorialFeaturedAt: toIsoString(data.editorialFeaturedAt),
        editorialFeaturedByEmail:
          data.editorialFeaturedByEmail?.toString().trim() ?? '',
        editorialFeaturedNote:
          data.editorialFeaturedNote?.toString().trim() ?? '',
      };
    }),
    conversations: resultMap.chats.docs.map((doc) => {
      const data = doc.data();
      const participants = Object.values(data.participantDetails ?? {}).map((entry) => {
        if (entry && typeof entry === 'object') {
          return (
            entry.name?.toString().trim() ||
            entry.phoneNumber?.toString().trim() ||
            'User'
          );
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
    reports: resultMap.seller_reports.docs.map((doc) => {
      const data = doc.data();
      const priority = normalizePriority(
        data.priority?.toString().trim(),
        data.reason?.toString().trim(),
        data.details?.toString().trim(),
      );

      return {
        id: doc.id,
        sellerId: data.sellerId?.toString().trim() ?? '',
        sellerName: data.sellerName?.toString().trim() ?? 'Seller',
        reporterId: data.reporterId?.toString().trim() ?? '',
        reporterName: data.reporterName?.toString().trim() ?? '',
        reason: data.reason?.toString().trim() ?? 'Seller report',
        details: data.details?.toString().trim() ?? '',
        priority,
        status: data.status?.toString().trim().toLowerCase() ?? 'pending',
        createdAt: toIsoString(data.createdAt) ?? toIsoString(data.updatedAt),
        updatedAt: toIsoString(data.updatedAt) ?? toIsoString(data.createdAt),
      };
    }),
    reviews: resultMap.reviews.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        sellerId: data.sellerId?.toString().trim() ?? '',
        reviewerName: data.reviewerName?.toString().trim() ?? 'Reviewer',
        rating: Number(data.rating ?? 0),
        comment: data.comment?.toString().trim() ?? '',
        createdAt: toIsoString(data.createdAt) ?? toIsoString(data.updatedAt),
        updatedAt: toIsoString(data.updatedAt) ?? toIsoString(data.createdAt),
      };
    }),
    notifications: resultMap.notifications.docs.map((doc) => {
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
        updatedAt: toIsoString(data.updatedAt) ?? toIsoString(data.createdAt),
      };
    }),
    blockedUsers: resultMap.user_blocks.docs.map((doc) => {
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
        updatedAt: toIsoString(data.updatedAt) ?? toIsoString(data.blockedAt),
      };
    }),
  };
}

export function useAdminData({ enabled = true } = {}) {
  const [refreshKey, setRefreshKey] = useState(0);
  const [state, setState] = useState(() =>
    enabled && hasFirebaseConfig
      ? createEmptySnapshot({ source: 'firebase', loading: true })
      : {
          ...buildAdminSnapshot(mockAdminData, 'mock'),
          loading: false,
        },
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

      if (!hasFirebaseConfig || !db) {
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
              error:
                error?.message || 'Firebase data could not be loaded for the admin panel.',
            }),
          );
        }
      }
    }

    hydrate();

    return () => {
      isCancelled = true;
    };
  }, [enabled, refreshKey]);

  return {
    ...state,
    refresh() {
      setRefreshKey((current) => current + 1);
    },
  };
}
