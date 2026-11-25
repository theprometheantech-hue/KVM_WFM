// Hostinger MySQL Database Connection Pool
const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'kvm_wfm',
  port: Number(process.env.DB_PORT) || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

// Helper function to test connection
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('[DATABASE] Successfully connected to Hostinger MySQL Database!');
    connection.release();
    return true;
  } catch (err) {
    console.warn('[DATABASE] MySQL connection not active yet, using fallback/in-memory mode:', err.message);
    return false;
  }
}

module.exports = {
  pool,
  testConnection,
};
