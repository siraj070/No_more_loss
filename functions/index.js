// ✅ Firebase Functions v2 syntax
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import nodemailer from "nodemailer";

initializeApp();
const db = getFirestore();

// ✅ Configure Gmail transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "sirajsyed249@gmail.com",  // your Gmail
    pass: "hzbrckbhqqkawozm",        // your Gmail App Password (no spaces)
  },
});

// ✅ Firestore Trigger - runs when shop status changes
export const sendApprovalEmail = onDocumentWritten(
  "pending_shops/{shopId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    // prevent null triggers (e.g. on delete)
    if (!before || !after) return;

    // Check if status changed to approved
    if (before.status !== "approved" && after.status === "approved") {
      const userEmail = after.email;
      const shopName = after.shopName || "your shop";

      const mailOptions = {
        from: `"Shop Approval" <sirajsyed249@gmail.com>`,
        to: userEmail,
        subject: "Shop Approved – You Can Now Sell!",
        text: `🎉 Congratulations! Your shop "${shopName}" has been approved by the admin. You can now start adding products.`,
      };

      try {
        await transporter.sendMail(mailOptions);
        console.log("✅ Email sent to:", userEmail);
      } catch (error) {
        console.error("❌ Error sending email:", error);
      }
    }
  }
);
