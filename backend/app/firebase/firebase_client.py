import firebase_admin
from firebase_admin import credentials, firestore

import os
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
key_path = os.path.join(BASE_DIR, "serviceAccountKey.json")

print(f"LOADING FIREBASE KEY FROM: {key_path}")

if os.path.exists(key_path):
    try:
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("Successfully initialized Firebase Admin")
    except Exception as e:
        print(f"[WARNING] Failed to initialize Firebase: {e}")
        db = None
else:
    print(f"[WARNING] Firebase service account key not found at {key_path}. Firestore features will be disabled.")
    db = None
