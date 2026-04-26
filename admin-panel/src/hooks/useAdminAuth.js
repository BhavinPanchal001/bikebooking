import { useEffect, useState } from 'react';
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '../lib/firebase';

const UNAUTHORIZED_ADMIN_MESSAGE = 'This account is not authorized for the admin panel.';
const BYPASS_ADMIN_AUTH =
  import.meta.env.DEV && import.meta.env.VITE_BYPASS_ADMIN_AUTH === 'true';

async function isAuthorizedAdminUser(user) {
  if (!user) {
    return false;
  }

  if (BYPASS_ADMIN_AUTH) {
    return true;
  }

  const tokenResult = await user.getIdTokenResult(true);
  if (tokenResult.claims?.admin === true) {
    return true;
  }

  if (!db) {
    return false;
  }

  const adminSnapshot = await getDoc(doc(db, 'admin_users', user.uid));
  return adminSnapshot.exists();
}

export function useAdminAuth() {
  const MOCK_UI_TEST = import.meta.env.DEV && import.meta.env.VITE_MOCK_ADMIN === 'true';
  const [user, setUser] = useState(MOCK_UI_TEST ? { email: 'test@admin.local', uid: 'mock-admin' } : null);
  const [loading, setLoading] = useState(MOCK_UI_TEST ? false : Boolean(auth));
  const [error, setError] = useState('');

  useEffect(() => {
    if (MOCK_UI_TEST) return;
    if (!auth) {
      setLoading(false);
      setError('Firebase Auth is not configured for the admin panel.');
      return undefined;
    }

    const unsubscribe = onAuthStateChanged(
      auth,
      async (nextUser) => {
        if (!nextUser) {
          setUser(null);
          setLoading(false);
          return;
        }

        try {
          const authorized = await isAuthorizedAdminUser(nextUser);
          if (!authorized) {
            setError(UNAUTHORIZED_ADMIN_MESSAGE);
            setUser(null);
            await signOut(auth);
            return;
          }

          setError('');
          setUser(nextUser);
        } catch (nextError) {
          console.error('Unable to verify admin access.', nextError);
          setError('Unable to verify whether this account can access the admin panel.');
          setUser(null);
        } finally {
          setLoading(false);
        }
      },
      (nextError) => {
        console.error('Unable to observe auth state.', nextError);
        setError('Unable to verify the current admin session.');
        setLoading(false);
      },
    );

    return unsubscribe;
  }, []);

  async function login(email, password) {
    setError('');
    if (MOCK_UI_TEST) {
      setUser({ email: email.trim() || 'test@admin.local', uid: 'mock-admin' });
      return { email: email.trim() || 'test@admin.local', uid: 'mock-admin' };
    }
    if (!auth) {
      const message = 'Firebase Auth is not configured for the admin panel.';
      setError(message);
      throw new Error(message);
    }

    try {
      const credential = await signInWithEmailAndPassword(auth, email.trim(), password);
      const authorized = await isAuthorizedAdminUser(credential.user);
      if (!authorized) {
        await signOut(auth);
        setError(UNAUTHORIZED_ADMIN_MESSAGE);
        throw new Error(UNAUTHORIZED_ADMIN_MESSAGE);
      }

      return credential.user;
    } catch (loginError) {
      const code = loginError?.code ?? '';
      const message =
        loginError?.message === UNAUTHORIZED_ADMIN_MESSAGE || code === 'permission-denied'
          ? UNAUTHORIZED_ADMIN_MESSAGE
          : code === 'auth/invalid-credential'
            ? 'Invalid email or password.'
            : code === 'auth/user-not-found'
              ? 'No admin account found for this email.'
              : code === 'auth/wrong-password'
                ? 'Incorrect password.'
                : code === 'auth/invalid-email'
                  ? 'Please enter a valid email address.'
                  : 'Sign in failed. Please check your Firebase Auth admin account.';
      setError(message);
      throw loginError;
    }
  }

  async function logout() {
    if (MOCK_UI_TEST) {
      setUser(null);
      return;
    }
    if (!auth) {
      return;
    }
    await signOut(auth);
  }

  return {
    user,
    loading,
    error,
    login,
    logout,
  };
}
