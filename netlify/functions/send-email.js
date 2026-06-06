exports.handler = async (event) => {
  if (event.httpMethod !== "POST") {
    return { statusCode: 405, body: "Method Not Allowed" };
  }

  try {
    const { to, name, inviteLink, role } = JSON.parse(event.body);

    if (!to || !inviteLink) {
      return { statusCode: 400, body: JSON.stringify({ error: "Missing required fields" }) };
    }

    const htmlContent = `
<div
  style="background-color: #f6f9fc; padding: 40px 20px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;"
>
  <table
    width="100%"
    cellpadding="0"
    cellspacing="0"
    style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05); overflow: hidden;"
  >
    <tr>
      <td style="padding: 30px 40px; border-bottom: 1px solid #eeeeee;">
        <h2 style="margin: 0; color: #111827; font-size: 20px; font-weight: 600; letter-spacing: -0.5px;">QubiQOS</h2>
      </td>
    </tr>

    <tr>
      <td style="padding: 40px;">
        <p style="margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 24px;">
          Hello <strong>${name || "there"}</strong>,
        </p>

        <p style="margin: 0 0 30px; font-size: 16px; color: #374151; line-height: 24px;">
          Welcome to QubiQOS. Your account space has been successfully provisioned. To complete your setup and
          securely access your dashboard, please verify your email address by clicking the button below.
        </p>

        <table width="100%" cellpadding="0" cellspacing="0">
          <tr>
            <td style="padding-bottom: 30px;">
              <a
                href="${inviteLink}"
                style="display: inline-block; background-color: #0f172a; color: #ffffff; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-weight: 500; font-size: 16px;"
              >
                Complete Account Setup
              </a>
            </td>
          </tr>
        </table>

        <p style="margin: 0 0 10px; font-size: 14px; color: #6b7280;">Or copy and paste this link into your browser:</p>

        <p style="margin: 0 0 30px; font-size: 14px; word-break: break-all;">
          <a href="${inviteLink}" style="color: #2563eb; text-decoration: underline;">${inviteLink}</a>
        </p>

        <p style="margin: 0; font-size: 14px; color: #6b7280; line-height: 20px;">
          If you require any assistance during onboarding, please contact our support team at
          <a href="mailto:eurekamindss@gmail.com" style="color: #2563eb; text-decoration: none;">eurekamindss@gmail.com</a>.
        </p>
      </td>
    </tr>

    <tr>
      <td style="background-color: #f9fafb; padding: 30px 40px; border-top: 1px solid #eeeeee;">
        <p style="margin: 0 0 10px; font-size: 12px; color: #9ca3af; line-height: 18px;">
          © 2026 QubiQ. All rights reserved.
        </p>

        <p style="margin: 0; font-size: 12px; color: #9ca3af; line-height: 18px;">
          This email was sent to ${to}. If you did not request this invitation, please ignore this email or
          contact security.
        </p>
      </td>
    </tr>
  </table>
</div>
    `;

    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${process.env.RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: process.env.RESEND_SENDER_EMAIL || "Emmi Management <onboarding@resend.dev>",
        to: [to],
        subject: `You're invited to join as ${role || "Team Member"} | Emmi Management`,
        html: htmlContent,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error("Resend error:", errText);
      return { statusCode: 500, body: JSON.stringify({ error: errText }) };
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Email sent successfully" }),
    };
  } catch (error) {
    console.error("Email error:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
