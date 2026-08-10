// This edge function has been decommissioned.
// Phone OTP (Twilio) authentication has been replaced with
// Supabase Email Authentication + Google Sign-In.
Deno.serve(() => new Response(
  JSON.stringify({ error: 'This endpoint is no longer active.' }),
  { status: 410, headers: { 'Content-Type': 'application/json' } }
));
