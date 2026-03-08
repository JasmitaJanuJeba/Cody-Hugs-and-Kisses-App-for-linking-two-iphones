// Cloud Functions for Firebase – index.js
// Deploy with: firebase deploy --only functions
//
// This function receives a callable request from the iOS app and forwards
// an FCM push notification to the recipient's device.
// Keeping the FCM send server-side protects the service-account credentials.

const { onCall } = require("firebase-functions/v2/https");
const { initializeApp }  = require("firebase-admin/app");
const { getMessaging }   = require("firebase-admin/messaging");

initializeApp();

exports.sendHugKiss = onCall(async (request) => {
  const { recipientToken, type, duration, intensity, pattern, senderName } = request.data;

  if (!recipientToken || !type) {
    throw new Error("Missing required fields.");
  }

  const emoji = type === "hug" ? "🤗" : "💋";

  const message = {
    token: recipientToken,

    // Visible notification (shown when app is in background/killed)
    notification: {
      title: `${emoji} ${senderName} sent you a ${type}!`,
      body:  "Open Hugs & Kisses to send one back.",
    },

    // Custom data payload – parsed by AppDelegate
    data: {
      hk_type:      type,
      hk_duration:  String(duration),
      hk_intensity: String(intensity),
      hk_pattern:   pattern,
      hk_sender:    senderName,
    },

    apns: {
      headers: {
        // content-available:1 wakes the app in background to process the payload
        "apns-priority": "10",
        "apns-push-type": "alert",
      },
      payload: {
        aps: {
          "content-available": 1,
          sound: "default",
          badge: 1,
        },
      },
    },

    android: {
      priority: "high",
    },
  };

  await getMessaging().send(message);
  return { success: true };
});
