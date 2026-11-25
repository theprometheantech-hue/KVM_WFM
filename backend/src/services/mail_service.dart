const nodemailer = require('nodemailer');

// Configure SMTP transport (defaults to console mailer fallback if credentials not provided in .env)
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: process.env.SMTP_PORT || 587,
  secure: false,
  auth: {
    user: process.env.SMTP_USER || 'kamarajvs31@gmail.com',
    pass: process.env.SMTP_PASS || '', // Provide Gmail App Password when ready
  },
});

async function sendOnboardingEmailToCompany({ fullName, mobileNumber, email, address, documents, employeeId, tempPassword }) {
  const mailOptions = {
    from: '"KVM Workforce Tracker" <no-reply@kvm.com>',
    to: 'kamarajvs31@gmail.com',
    subject: `[New Onboarding Application] ${fullName} (${employeeId})`,
    html: `
      <h2>New Employee Onboarding Application</h2>
      <p>A new employee has registered on <strong>KVM Workforce Tracker</strong>:</p>
      <ul>
        <li><strong>Employee ID:</strong> ${employeeId}</li>
        <li><strong>Full Name:</strong> ${fullName}</li>
        <li><strong>Mobile Number:</strong> ${mobileNumber}</li>
        <li><strong>Personal Email:</strong> ${email}</li>
        <li><strong>Address:</strong> ${address || 'N/A'}</li>
        <li><strong>Temporary Password Issued:</strong> ${tempPassword}</li>
      </ul>
      <h3>Attached Onboarding Documents:</h3>
      <ul>
        ${(documents || []).map(d => `<li>📄 ${d}</li>`).join('')}
      </ul>
      <p style="color: gray; font-size: 11px;">Sent automatically by KVM Workforce Tracker Backend.</p>
    `,
  };

  try {
    if (process.env.SMTP_PASS) {
      await transporter.sendMail(mailOptions);
      console.log(`[EMAIL SUCCESS] Onboarding application emailed directly to kamarajvs31@gmail.com`);
    } else {
      console.log(`[EMAIL READY] Formatted and routed to kamarajvs31@gmail.com (Set SMTP_PASS in .env to deliver via Gmail servers)`);
    }
  } catch (error) {
    console.error(`[EMAIL ERROR] Failed to send email to kamarajvs31@gmail.com:`, error.message);
  }
}

module.exports = {
  sendOnboardingEmailToCompany,
};

