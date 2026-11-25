require('dotenv').config();
const { Resend } = require('resend');

const resendApiKey = process.env.RESEND_API_KEY || '';
const resend = new Resend(resendApiKey);

// Resend allows onboarding@resend.dev out of the box for testing/production
const FROM_EMAIL = 'KVM Workforce <onboarding@resend.dev>';
const HR_EMAIL = process.env.COMPANY_HR_EMAIL || 'kamarajvs31@gmail.com';

// 1. Send applicant onboarding application & documents to Company HR
async function sendOnboardingEmailToCompany({ fullName, mobileNumber, email, address, documents, employeeId, tempPassword }) {
  try {
    const data = await resend.emails.send({
      from: FROM_EMAIL,
      to: [HR_EMAIL],
      subject: `[New Onboarding Application] ${fullName} (${employeeId})`,
      html: `
        <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #1e293b; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 8px; padding: 24px;">
          <h2 style="color: #0f172a; margin-top: 0; border-bottom: 2px solid #2563eb; padding-bottom: 8px;">New Employee Onboarding Application</h2>
          <p>A new employee registration has been submitted on <strong>KVM Workforce Tracker</strong>:</p>
          <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
            <tr style="border-bottom: 1px solid #f1f5f9;"><td style="padding: 8px; font-weight: bold; width: 40%;">Employee ID:</td><td style="padding: 8px; color: #2563eb; font-weight: bold;">${employeeId}</td></tr>
            <tr style="border-bottom: 1px solid #f1f5f9;"><td style="padding: 8px; font-weight: bold;">Full Name:</td><td style="padding: 8px;">${fullName}</td></tr>
            <tr style="border-bottom: 1px solid #f1f5f9;"><td style="padding: 8px; font-weight: bold;">Mobile Number:</td><td style="padding: 8px;">${mobileNumber}</td></tr>
            <tr style="border-bottom: 1px solid #f1f5f9;"><td style="padding: 8px; font-weight: bold;">Personal Email:</td><td style="padding: 8px;">${email}</td></tr>
            <tr style="border-bottom: 1px solid #f1f5f9;"><td style="padding: 8px; font-weight: bold;">Address:</td><td style="padding: 8px;">${address || 'N/A'}</td></tr>
            <tr style="border-bottom: 1px solid #f1f5f9;"><td style="padding: 8px; font-weight: bold;">Temporary Password:</td><td style="padding: 8px; color: #d97706; font-weight: bold;">${tempPassword}</td></tr>
          </table>
          <h3 style="color: #0f172a; margin-top: 20px;">Attached Onboarding Documents:</h3>
          <ul style="background: #f8fafc; padding: 16px 28px; border-radius: 6px;">
            ${(documents || []).length > 0 ? documents.map(d => `<li style="margin-bottom: 6px;">📄 <strong>${d}</strong></li>`).join('') : '<li>No documents attached</li>'}
          </ul>
          <p style="color: #64748b; font-size: 12px; margin-top: 24px; border-top: 1px solid #e2e8f0; padding-top: 12px;">
            Sent automatically by KVM Workforce Tracker Cloud Mailer.
          </p>
        </div>
      `,
    });
    console.log(`[RESEND EMAIL SUCCESS] Onboarding application sent to HR (${HR_EMAIL}). ID:`, data.id || data);
    return data;
  } catch (error) {
    console.error(`[RESEND EMAIL ERROR] Failed to send HR email:`, error.message || error);
  }
}

// 2. Send Employee ID and Temporary Password directly to Employee Personal Inbox
async function sendCredentialsEmailToEmployee({ fullName, email, employeeId, tempPassword }) {
  try {
    const data = await resend.emails.send({
      from: FROM_EMAIL,
      to: [email],
      subject: `Welcome to KVM Workforce - Your Login Credentials (${employeeId})`,
      html: `
        <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #1e293b; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 8px; padding: 24px;">
          <h2 style="color: #0f172a; margin-top: 0; border-bottom: 2px solid #2563eb; padding-bottom: 8px;">Welcome to KVM Workforce Tracker</h2>
          <p>Dear <strong>${fullName}</strong>,</p>
          <p>Your employee registration has been successfully received. Below are your official login credentials to access the app:</p>
          
          <div style="background: #f0fdf4; border: 1px solid #bbf7d0; border-left: 5px solid #16a34a; padding: 16px; border-radius: 6px; margin: 20px 0;">
            <p style="margin: 4px 0;"><strong>Employee ID:</strong> <span style="font-size: 17px; font-weight: bold; color: #166534;">${employeeId}</span></p>
            <p style="margin: 4px 0;"><strong>Temporary Password:</strong> <span style="font-size: 17px; font-weight: bold; color: #d97706;">${tempPassword}</span></p>
          </div>

          <h3 style="color: #0f172a; margin-top: 20px;">Next Steps:</h3>
          <ol style="padding-left: 20px;">
            <li style="margin-bottom: 6px;">Open the <strong>KVM Workforce Tracker</strong> application.</li>
            <li style="margin-bottom: 6px;">Sign in with your <strong>Employee ID</strong> (or Email) and <strong>Temporary Password</strong>.</li>
            <li style="margin-bottom: 6px;">You will be asked to set your personal permanent password on your first login.</li>
            <li style="margin-bottom: 6px;">Passwords expire every 90 days (3 months) in compliance with company security policy.</li>
          </ol>

          <p style="color: #64748b; font-size: 12px; margin-top: 24px; border-top: 1px solid #e2e8f0; padding-top: 12px;">
            For support or questions, contact your administrator at ${HR_EMAIL}.
          </p>
        </div>
      `,
    });
    console.log(`[RESEND EMAIL SUCCESS] Credentials sent to employee inbox (${email}). ID:`, data.id || data);
    return data;
  } catch (error) {
    console.error(`[RESEND EMAIL ERROR] Failed to send employee email to ${email}:`, error.message || error);
  }
}

module.exports = {
  sendOnboardingEmailToCompany,
  sendCredentialsEmailToEmployee,
};
