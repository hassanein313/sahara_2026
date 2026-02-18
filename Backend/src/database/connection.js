// ============================================================
// PostgreSQL Database Connection
// ============================================================
const { Pool } = require('pg');
const logger = require('../config/logger');

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    database: process.env.DB_NAME || 'sahara_fuel',
    user: process.env.DB_USER || 'sahara_admin',
    password: process.env.DB_PASSWORD || 'your_strong_password',
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
});

async function testConnection() {
    const client = await pool.connect();
    try {
        const result = await client.query('SELECT NOW()');
        logger.info(`PostgreSQL connected at ${result.rows[0].now}`);
    } finally {
        client.release();
    }
}

async function query(text, params) {
    const start = Date.now();
    try {
        const result = await pool.query(text, params);
        const duration = Date.now() - start;
        if (duration > 1000) {
            logger.warn(`Slow query (${duration}ms): ${text.substring(0, 100)}`);
        }
        return result;
    } catch (error) {
        logger.error(`Query error: ${error.message}`, { query: text.substring(0, 200) });
        throw error;
    }
}

async function transaction(callback) {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        const result = await callback(client);
        await client.query('COMMIT');
        return result;
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}

module.exports = { pool, query, transaction, testConnection };
