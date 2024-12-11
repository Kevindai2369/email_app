// Firebase configuration (replace with your actual config)
const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
    databaseURL: "https://YOUR_PROJECT_ID.firebaseio.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT_ID.appspot.com",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID",
    measurementId: "YOUR_MEASUREMENT_ID"
};

// Initialize Firebase
const app = firebase.initializeApp(firebaseConfig);
const db = firebase.database(app);

// Send email function
function sendEmail() {
    const subject = document.getElementById('emailSubject').value;
    const body = document.getElementById('emailBody').value;

    if (subject && body) {
        const emailData = {
            subject: subject,
            body: body,
            timestamp: new Date().toISOString(),
            sender: 'user@example.com', // You can replace with dynamic user data if using Firebase Authentication
        };

        // Save email to Firebase Realtime Database
        const emailsRef = db.ref('emails');
        emailsRef.push(emailData);

        // Clear input fields
        document.getElementById('emailSubject').value = '';
        document.getElementById('emailBody').value = '';
        
        alert('Email Sent!');
        hideComposeEmail();
        loadEmails(); // Refresh email list
    } else {
        alert('Please fill in both subject and body');
    }
}

// Show compose email form
function showComposeEmail() {
    document.getElementById('composeEmailForm').style.display = 'block';
}

// Hide compose email form
function hideComposeEmail() {
    document.getElementById('composeEmailForm').style.display = 'none';
}

// Load emails from Firebase and display
function loadEmails() {
    const emailList = document.getElementById('emailList');
    emailList.innerHTML = ''; // Clear previous email list

    const emailsRef = db.ref('emails');
    emailsRef.on('value', (snapshot) => {
        const emails = snapshot.val();
        if (emails) {
            for (const key in emails) {
                const email = emails[key];
                const emailItem = document.createElement('div');
                emailItem.classList.add('email-item');
                emailItem.innerHTML = `
                    <h3>${email.subject}</h3>
                    <p><strong>From:</strong> ${email.sender}</p>
                    <p><strong>Body:</strong> ${email.body}</p>
                    <p><strong>Sent At:</strong> ${new Date(email.timestamp).toLocaleString()}</p>
                    <hr>
                `;
                emailList.appendChild(emailItem);
            }
        }
    });
}

// Initialize by loading emails
loadEmails();