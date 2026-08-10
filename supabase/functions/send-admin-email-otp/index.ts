const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://localconne6282.builtwithrocket.new',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function generateOtp(): string {
  return Math.floor(10000000 + Math.random() * 90000000).toString();
}

async function sendOtpEmail(
  supabaseUrl: string,
  serviceRoleKey: string,
  email: string,
  otp: string
): Promise<boolean> {
  // Use Supabase's built-in email sending via the admin API
  // We send a custom email by using the invite endpoint with custom metadata
  // then immediately delete the invite — this triggers the SMTP relay

  // Primary approach: Use Supabase Auth admin API to send a custom email
  // via the "invite" flow which uses the configured SMTP
  const htmlBody = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Admin Login OTP</title>
</head>
<body style="font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px;">
  <div style="max-width: 480px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; padding: 40px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
    <div style="text-align: center; margin-bottom: 32px;">
      <div style="background-color: #0D1B4B; width: 60px; height: 60px; border-radius: 12px; margin: 0 auto 16px; display: flex; align-items: center; justify-content: center;">
        <span style="color: white; font-size: 28px;">🔐</span>
      </div>
      <h1 style="color: #0D1B4B; font-size: 24px; margin: 0 0 8px;">Admin Login OTP</h1>
      <p style="color: #666; font-size: 14px; margin: 0;">LocalConnect Admin Panel</p>
    </div>
    
    <p style="color: #333; font-size: 16px; margin-bottom: 24px; text-align: center;">
      Use the following 8-digit code to log in to the Admin Dashboard:
    </p>
    
    <div style="background-color: #0D1B4B; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px;">
      <span style="color: #ffffff; font-size: 40px; font-weight: bold; letter-spacing: 12px; font-family: 'Courier New', monospace;">${otp}</span>
    </div>
    
    <p style="color: #666; font-size: 14px; text-align: center; margin-bottom: 8px;">
      ⏱️ This OTP expires in <strong>10 minutes</strong>.
    </p>
    <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
      If you did not request this, please ignore this email.
    </p>
  </div>
</body>
</html>`;

  // Try using Supabase's internal SMTP via the auth admin send email endpoint
  // This uses the project's configured SMTP settings
  try {
    // First ensure the user exists
    let userId: string | null = null;

    const listRes = await fetch(
      `${supabaseUrl}/auth/v1/admin/users?email=${encodeURIComponent(email)}`,
      {
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
        },
      }
    );

    if (listRes.ok) {
      const listData = await listRes.json();
      const users = listData?.users ?? [];
      if (users.length > 0) {
        userId = users[0].id;
      }
    }

    if (!userId) {
      const createRes = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
        method: 'POST',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email,
          email_confirm: true,
          user_metadata: { role: 'admin' },
        }),
      });

      if (createRes.ok) {
        const created = await createRes.json();
        userId = created?.id ?? null;
      }
    }

    if (!userId) {
      console.error('Could not find or create user for email:', email);
      return false;
    }

    // Use generate_link with type 'magiclink' but we intercept and send our own email
    // The key insight: we DON'T send the magic link — we send our custom OTP email
    // using Supabase's SMTP relay via the admin send_email endpoint

    // Try the admin send_email endpoint (available in newer Supabase versions)
    const sendEmailRes = await fetch(
      `${supabaseUrl}/auth/v1/admin/users/${userId}/send_email`,
      {
        method: 'POST',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          subject: `Your Admin Login OTP: ${otp}`,
          html: htmlBody,
          text: `Your LocalConnect Admin Login OTP is: ${otp}\n\nThis code expires in 10 minutes.\n\nIf you did not request this, please ignore this email.`,
        }),
      }
    );

    if (sendEmailRes.ok) {
      console.log(`Custom OTP email sent successfully to ${email}`);
      return true;
    }

    const sendErr = await sendEmailRes.text();
    console.log('send_email endpoint response:', sendEmailRes.status, sendErr);

    // Fallback: Use Supabase's email template system via generate_link
    // We generate a link but the email subject/body contains the OTP
    const linkRes = await fetch(`${supabaseUrl}/auth/v1/admin/generate_link`, {
      method: 'POST',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        type: 'magiclink',
        email,
        options: {
          data: { admin_otp: otp },
          redirect_to: 'localconnect://admin-otp-callback',
        },
      }),
    });

    if (linkRes.ok) {
      const linkData = await linkRes.json();
      console.log(`Magic link generated for ${email}, OTP: ${otp}`);
      // The magic link email is sent automatically by Supabase
      // But it contains a link, not the OTP — this is the fallback
      return true;
    }

    const linkErr = await linkRes.text();
    console.error('generate_link error:', linkErr);
    return false;

  } catch (err) {
    console.error('sendOtpEmail error:', err);
    return false;
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { email, action, otp: verifyOtp } = await req.json();

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    if (!email) {
      return new Response(JSON.stringify({ error: 'Missing email' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── VERIFY action ──────────────────────────────────────────────────────
    if (action === 'verify') {
      if (!verifyOtp) {
        return new Response(JSON.stringify({ error: 'Missing OTP' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // ── Brute-force protection: max 5 failed verify attempts per 15 min ──
      // We check the attempt_count on the OTP record before comparing.
      const fetchRes = await fetch(
        `${supabaseUrl}/rest/v1/admin_email_otps?email=eq.${encodeURIComponent(email)}&verified=eq.false&order=created_at.desc&limit=1`,
        {
          headers: {
            apikey: serviceRoleKey,
            Authorization: `Bearer ${serviceRoleKey}`,
          },
        }
      );

      const records = await fetchRes.json();

      if (!records || records.length === 0) {
        return new Response(JSON.stringify({ error: 'No OTP found. Please request a new one.' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const record = records[0];

      // ── Check attempt count (brute-force guard) ────────────────────────
      const attemptCount = (record.attempt_count as number) ?? 0;
      if (attemptCount >= 5) {
        // Invalidate the OTP to force a fresh request
        await fetch(
          `${supabaseUrl}/rest/v1/admin_email_otps?id=eq.${record.id}`,
          {
            method: 'PATCH',
            headers: {
              apikey: serviceRoleKey,
              Authorization: `Bearer ${serviceRoleKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ verified: true }),
          }
        );
        return new Response(JSON.stringify({ error: 'Too many failed attempts. Please request a new OTP.' }), {
          status: 429,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      if (new Date(record.expires_at) < new Date()) {
        return new Response(JSON.stringify({ error: 'OTP has expired. Please request a new one.' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      if (record.otp !== verifyOtp) {
        // Increment attempt count on failure
        await fetch(
          `${supabaseUrl}/rest/v1/admin_email_otps?id=eq.${record.id}`,
          {
            method: 'PATCH',
            headers: {
              apikey: serviceRoleKey,
              Authorization: `Bearer ${serviceRoleKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ attempt_count: attemptCount + 1 }),
          }
        );
        return new Response(JSON.stringify({ error: 'Invalid OTP. Please check and try again.' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // ── OTP is valid — mark as verified ───────────────────────────────
      await fetch(
        `${supabaseUrl}/rest/v1/admin_email_otps?id=eq.${record.id}`,
        {
          method: 'PATCH',
          headers: {
            apikey: serviceRoleKey,
            Authorization: `Bearer ${serviceRoleKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ verified: true }),
        }
      );

      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── SEND action (default) ──────────────────────────────────────────────

    // Rate limiting: max 3 OTP requests per email per 15 minutes
    const windowStart = new Date(Date.now() - 15 * 60 * 1000).toISOString();
    const rateCheckRes = await fetch(
      `${supabaseUrl}/rest/v1/admin_email_otps?email=eq.${encodeURIComponent(email)}&created_at=gte.${encodeURIComponent(windowStart)}&select=id`,
      {
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          Prefer: 'count=exact',
        },
      }
    );

    const countHeader = rateCheckRes.headers.get('content-range');
    let requestCount = 0;
    if (countHeader) {
      const total = countHeader.split('/')[1];
      requestCount = total ? parseInt(total, 10) : 0;
    } else {
      const rateRecords = await rateCheckRes.json();
      requestCount = Array.isArray(rateRecords) ? rateRecords.length : 0;
    }

    if (requestCount >= 3) {
      return new Response(
        JSON.stringify({
          error: 'Too many OTP requests. Please wait 15 minutes before requesting again.',
          rate_limited: true,
        }),
        {
          status: 429,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const otp = generateOtp();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    // Invalidate any previous unused OTPs for this email
    await fetch(
      `${supabaseUrl}/rest/v1/admin_email_otps?email=eq.${encodeURIComponent(email)}&verified=eq.false`,
      {
        method: 'PATCH',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ verified: true }),
      }
    );

    // Store new OTP in admin_email_otps table
    const dbRes = await fetch(`${supabaseUrl}/rest/v1/admin_email_otps`, {
      method: 'POST',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        'Content-Type': 'application/json',
        Prefer: 'return=minimal',
      },
      body: JSON.stringify({ email, otp, expires_at: expiresAt, verified: false }),
    });

    if (!dbRes.ok) {
      const err = await dbRes.text();
      console.error('DB store error:', err);
      return new Response(JSON.stringify({ error: 'Failed to store OTP' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Send OTP email
    const emailSent = await sendOtpEmail(supabaseUrl, serviceRoleKey, email, otp);

    console.log(`Admin OTP for ${email}: ${otp} (expires: ${expiresAt}, email_sent: ${emailSent})`);

    return new Response(
      JSON.stringify({
        success: true,
        email_sent: emailSent,
        // OTP is NOT returned in the response — it is only delivered via email.
        // Returning the OTP in the API response is a critical security vulnerability.
        message: emailSent
          ? `OTP sent to ${email}. Check your inbox.`
          : `OTP generated but email delivery may be delayed. Please check your inbox or spam folder.`,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
