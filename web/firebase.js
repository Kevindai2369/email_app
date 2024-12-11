// firebase-config.js
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";

const firebaseConfig = {
    apiKey: "AIzaSyAhka_B5k3r3Ujw-yd4BMT6NxONODSrbFY",
    authDomain: "email-v2-b3b04.firebaseapp.com",
    databaseURL: "https://email-v2-b3b04-default-rtdb.asia-southeast1.firebasedatabase.app",
    projectId: "email-v2-b3b04",
    storageBucket: "email-v2-b3b04.firebasestorage.app",
    messagingSenderId: "353003953608",
    appId: "1:353003953608:web:6c040b5e8d9362e5ec34fd",
    measurementId: "G-QRG5LN39L1"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

export { app, analytics };
