import { httpsCallable } from 'firebase/functions';
import { functions } from '../lib/firebase';

const ADMIN_ACTION_TIMEOUT_MS = 20000;

function getFunctionsClient() {
  if (!functions) {
    throw new Error('Firebase Functions is not configured for the admin panel.');
  }

  return functions;
}

async function withTimeout(promise, timeoutMessage, timeoutMs = ADMIN_ACTION_TIMEOUT_MS) {
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

function resolveAdminUserError(error, actionLabel) {
  const code = error?.code?.toString().trim().toLowerCase().replace('functions/', '') ?? '';

  switch (code) {
    case 'permission-denied':
      return 'This account is not allowlisted for admin user management yet.';
    case 'unauthenticated':
      return 'Your admin session expired. Please sign in again.';
    case 'not-found':
      return 'That user no longer exists in Firestore.';
    case 'invalid-argument':
      return 'The selected user action is missing a valid user ID.';
    case 'unavailable':
      return 'Cloud Functions is temporarily unavailable. Please try again.';
    case 'deadline-exceeded':
      return `${actionLabel} is taking too long. Please try again in a moment.`;
    case 'internal':
      return error?.message || `An internal error occurred during ${actionLabel.toLowerCase()}.`;
    default:
      return error?.message || `Unable to ${actionLabel.toLowerCase()}.`;
  }
}

async function callAdminUserAction(functionName, payload, actionLabel) {
  try {
    const callable = httpsCallable(getFunctionsClient(), functionName);
    const response = await withTimeout(
      callable(payload),
      `${actionLabel} is taking too long. Check your Firebase Functions deployment and try again.`,
    );
    return response?.data ?? null;
  } catch (error) {
    console.error(`Unable to ${actionLabel.toLowerCase()}.`, {
      code: error?.code,
      message: error?.message,
      details: error?.details,
      raw: error,
    });
    throw new Error(resolveAdminUserError(error, actionLabel));
  }
}

export const adminUsersService = {
  async blockUser({ userId }) {
    return callAdminUserAction('adminBlockUser', { userId }, 'Block user');
  },

  async unblockUser({ userId }) {
    return callAdminUserAction('adminUnblockUser', { userId }, 'Unblock user');
  },

  async deleteUser({ userId }) {
    return callAdminUserAction('adminDeleteUser', { userId }, 'Delete user');
  },
};
