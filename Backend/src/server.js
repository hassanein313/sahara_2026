// ============================================================
// Sahara Fuel SaaS - Server Entry Point
// ============================================================
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const app = require('./app');
const { pool, testConnection } = require('./database/connection');
const { connectRedis } = require('./config/redis');
const logger = require('./config/logger');

const PORT = process.env.PORT || 3000;

async function startServer() {
    try {
        await testConnection();
        logger.info('✅ PostgreSQL متصل');

        await connectRedis();
        logger.info('✅ Redis متصل');

        app.listen(PORT, '0.0.0.0', () => {
            logger.info(`🚀 Sahara Fuel SaaS API يعمل على المنفذ ${PORT}`);
            logger.info(`📍 البيئة: ${process.env.NODE_ENV || 'development'}`);
            logger.info(`📖 API Docs: http://localhost:${PORT}/api`);
            logger.info(`💚 Health: http://localhost:${PORT}/api/health`);
        });
    } catch (error) {
        logger.error('❌ فشل تشغيل السيرفر:', error);
        process.exit(1);
    }
}

process.on('SIGTERM', async () => {
    logger.info('🛑 إيقاف السيرفر...');
    await pool.end();
    process.exit(0);
});

process.on('SIGINT', async () => {
    logger.info('🛑 إيقاف السيرفر...');
    await pool.end();
    process.exit(0);
});

process.on('unhandledRejection', (reason) => {
    logger.error('Unhandled Rejection:', reason);
});

startServer();
