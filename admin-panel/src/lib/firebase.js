import { initializeApp } from 'firebase/app';
import { browserLocalPersistence, getAuth, setPersistence } from 'firebase/auth';
import { initializeFirestore } from 'firebase/firestore';
import { getFunctions } from 'firebase/functions';

const fallbackConfig = {
  apiKey: 'AIzaSyBOjWZF-VCYSHksyZ6x3ScJNtZcG_gKMsw',
  authDomain: 'bikenest-app.firebaseapp.com',
  projectId: 'bikenest-app',
  storageBucket: 'bikenest-app.firebasestorage.app',
  messagingSenderId: '121567378502',
  appId: '1:121567378502:android:1f9d17d4e318f4cc559e47',
};

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || fallbackConfig.apiKey,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || fallbackConfig.authDomain,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || fallbackConfig.projectId,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || fallbackConfig.storageBucket,
  messagingSenderId:
    import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || fallbackConfig.messagingSenderId,
  appId: import.meta.env.VITE_FIREBASE_APP_ID || fallbackConfig.appId,
};

export const hasFirebaseConfig = Object.values(firebaseConfig).every(Boolean);

const app = hasFirebaseConfig ? initializeApp(firebaseConfig) : null;
const db = app
  ? initializeFirestore(app, {
      experimentalAutoDetectLongPolling: true,
      useFetchStreams: false,
    })
  : null;
const auth = app ? getAuth(app) : null;
const functionsRegion =
  import.meta.env.VITE_FIREBASE_FUNCTIONS_REGION || 'us-central1';
const functions = app ? getFunctions(app, functionsRegion) : null;

if (auth) {
  setPersistence(auth, browserLocalPersistence).catch((error) => {
    console.warn('Unable to apply local auth persistence.', error);
  });
}

export { app, auth, db, functions, firebaseConfig };
