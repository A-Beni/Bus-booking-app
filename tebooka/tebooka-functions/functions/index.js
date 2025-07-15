const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendBookingNotification = functions.https.onCall(
    async (data, context) => {
      const fcmToken = data.fcmToken;
      const title = data.title;
      const body = data.body;

      if (!fcmToken) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "FCM token is required",
        );
      }

      const message = {
        token: fcmToken,
        notification: {
          title,
          body,
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "default_channel",
          },
        },
      };

      try {
        const response = await admin.messaging().send(message);
        console.log("✅ Notification sent:", response);
        return {success: true};
      } catch (error) {
        console.error("❌ Error sending notification:", error);
        throw new functions.https.HttpsError(
            "unknown",
            error.message,
            error,
        );
      }
    },
);
