const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const stripe = require("stripe")(
    functions.config().stripe.secret,
);

exports.createPaymentIntent = functions.https.onCall(
    async (data, context) => {
      const amount = data.amount;

      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated.",
        );
      }

      try {
        const paymentIntent = await stripe.paymentIntents.create({
          amount,
          currency: "usd",
          payment_method_types: ["card"],
        });

        return {
          clientSecret: paymentIntent.client_secret,
        };
      } catch (error) {
        console.error("Payment Intent Error:", error);
        throw new functions.https.HttpsError(
            "internal",
            error.message,
        );
      }
    },
);
