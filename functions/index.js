const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotificationOnCreate = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notification = snap.data();

    if (notification.targetRole) {
      const message = {
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          type: notification.type,
          tableId: notification.tableId,
          orderId: notification.orderId,
        },
        topic: notification.targetRole,
      };

      try {
        await admin.messaging().send(message);
        console.log(`Đã gửi thông báo đến ${notification.targetRole}`);

        // Cập nhật trạng thái trong Firestore
        await snap.ref.update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (error) {
        console.error("Lỗi gửi thông báo:", error);
        // Cập nhật trạng thái lỗi
        await snap.ref.update({
          sent: false,
          error: error.message,
        });
      }
    }
  });
