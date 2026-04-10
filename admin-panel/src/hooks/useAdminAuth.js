import { useEffect, useState } from 'react';
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';
import { auth } from '../lib/firebase';

export function useAdminAuth() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(Boolean(auth));
  const [error, setError] = useState('');

  useEffect(() => {
    if (!auth) {
      setLoading(false);
      setError('Firebase Auth is not configured for the admin panel.');
      return undefined;
    }

    const unsubscribe = onAuthStateChanged(
      auth,
      (nextUser) => {
        setUser(nextUser);
        setLoading(false);
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
    if (!auth) {
      const message = 'Firebase Auth is not configured for the admin panel.';
      setError(message);
      throw new Error(message);
    }

    try {
      const credential = await signInWithEmailAndPassword(auth, email.trim(), password);
      return credential.user;
    } catch (loginError) {
      const code = loginError?.code ?? '';
      const message =
        code === 'auth/invalid-credential'
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
