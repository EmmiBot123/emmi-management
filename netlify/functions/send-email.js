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
      <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08);">
        
        <div style="background: linear-gradient(135deg, #0984E3 0%, #6C5CE7 100%); padding: 40px 32px; text-align: center;">
          <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 700;">
            Welcome to the Team! 🎉
          </h1>
          <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0; font-size: 15px;">
            You've been invited to join the management platform
          </p>
        </div>

        <div style="padding: 36px 32px;">
          <p style="color: #2D3436; font-size: 16px; line-height: 1.6; margin: 0 0 24px;">
            Hi <strong>${name || "there"}</strong>,
          </p>
          
          <p style="color: #636E72; font-size: 15px; line-height: 1.7; margin: 0 0 12px;">
            You have been invited to join as <strong style="color: #0984E3;">${role || "Team Member"}</strong>. 
            Click the button below to create your account and get started.
          </p>

          <div style="text-align: center; margin: 32px 0;">
            <a href="${inviteLink}" 
               style="display: inline-block; background: linear-gradient(135deg, #0984E3 0%, #6C5CE7 100%); color: #ffffff; text-decoration: none; padding: 14px 40px; border-radius: 12px; font-size: 16px; font-weight: 600; box-shadow: 0 4px 16px rgba(9,132,227,0.35);">
              Create Your Account →
            </a>
          </div>

          <p style="color: #B2BEC3; font-size: 13px; line-height: 1.6; margin: 24px 0 0; text-align: center;">
            This invitation link will expire in 7 days.<br/>
            If you didn't expect this email, you can safely ignore it.
          </p>
        </div>

        <div style="background: #F8F9FA; padding: 20px 32px; text-align: center; border-top: 1px solid #EEE;">
          <p style="color: #B2BEC3; font-size: 12px; margin: 0;">
            Emmi Management Platform • Powered by Eureka Minds
          </p>
        </div>
      </div>
    `;

    const response = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "api-key": process.env.BREVO_API_KEY,
      },
      body: JSON.stringify({
        sender: {
          name: "Emmi Management",
          email: process.env.BREVO_SENDER_EMAIL,
        },
        to: [{ email: to, name: name || "" }],
        subject: `You're invited to join as ${role || "Team Member"} | Emmi Management`,
        htmlContent: htmlContent,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error("Brevo error:", errText);
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
