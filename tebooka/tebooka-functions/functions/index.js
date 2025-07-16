const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendBookingNotification = functions.https.onCall(
    async (data, context) => {
      console.log("📨 Received booking notification request:", data);

      if (!data || typeof data !== "object") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Request data must be an object.",
        );
      }

      const fcmToken =
      typeof data.fcmToken === "string" ? data.fcmToken.trim() : "";

      const title =
      typeof data.title === "string" ?
        data.title.trim() :
        "Booking Update";

      const body =
      typeof data.body === "string" ?
        data.body.trim() :
        "You have a new booking notification.";

      if (!fcmToken) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "FCM token must be a non-empty string.",
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
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      };

      try {
        const response = await admin.messaging().send(message);
        console.log("✅ Notification sent successfully:", response);
        return {
          success: true,
          messageId: response,
        };
      } catch (error) {
        console.error("❌ Error sending notification:", error.message, error);
        throw new functions.https.HttpsError(
            "unknown",
            "Failed to send notification.",
            error,
        );
      }
    },
);
