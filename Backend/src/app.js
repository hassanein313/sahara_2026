// ============================================================
// Sahara Fuel SaaS - Express Application
// ============================================================
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const logger = require('./config/logger');

const app = express();

// ==================== SECURITY ====================
app.use(helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
}));

app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
}));

// ==================== RATE LIMITING ====================
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_MAX) || 100,
    message: {
        success: false,
        error: 'تم تجاوز الحد الأقصى للطلبات - حاول مجدداً بعد 15 دقيقة',
        code: 'RATE_LIMITED',
    },
    standardHeaders: true,
    legacyHeaders: false,
});

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10,
    message: {
        success: false,
        error: 'محاولات تسجيل دخول كثيرة - حاول بعد 15 دقيقة',
        code: 'AUTH_RATE_LIMITED',
    },
});

app.use('/api/', limiter);
app.use('/api/auth/login', authLimiter);

// ==================== BODY PARSING ====================
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ==================== LOGGING ====================
app.use(morgan('combined', {
    stream: { write: (message) => logger.info(message.trim()) },
}));

// ==================== ROUTES ====================
app.use('/api/auth', require('./modules/auth/routes'));
app.use('/api/users', require('./modules/users/routes'));
app.use('/api/fuel', require('./modules/fuel/routes'));
app.use('/api/tanks', require('./modules/tanks/routes'));
app.use('/api/branches', require('./modules/branches/routes'));
app.use('/api/roles', require('./modules/roles/routes'));
app.use('/api/audit', require('./modules/audit/routes'));
app.use('/api/subscriptions', require('./modules/subscriptions/routes'));
app.use('/api/import', require('./modules/import/routes'));

// ==================== HEALTH CHECK ====================
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        service: 'Sahara Fuel SaaS API',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV,
    });
});

// ==================== API DOCS ====================
app.get('/api', (req, res) => {
    res.json({
        service: 'Sahara Fuel SaaS Enterprise API',
        version: '1.0.0',
        endpoints: {
            auth: {
                'POST /api/auth/login': 'تسجيل الدخول',
                'POST /api/auth/refresh': 'تجديد التوكن',
                'POST /api/auth/logout': 'تسجيل الخروج',
                'POST /api/auth/change-password': 'تغيير كلمة المرور',
                'GET /api/auth/me': 'بيانات المستخدم الحالي',
            },
            users: {
                'GET /api/users': 'قائمة المستخدمين',
                'GET /api/users/:id': 'بيانات مستخدم',
                'POST /api/users': 'إنشاء مستخدم',
                'PUT /api/users/:id': 'تحديث مستخدم',
                'DELETE /api/users/:id': 'حذف مستخدم',
            },
            fuel: {
                'GET /api/fuel': 'قائمة المعاملات',
                'GET /api/fuel/:id': 'تفاصيل معاملة',
                'POST /api/fuel': 'إنشاء معاملة',
                'PATCH /api/fuel/:id/approve': 'الموافقة على معاملة',
                'DELETE /api/fuel/:id': 'حذف معاملة',
                'GET /api/fuel/stats/summary': 'إحصائيات الوقود',
            },
            tanks: {
                'GET /api/tanks': 'قائمة الخزانات',
                'GET /api/tanks/:id': 'تفاصيل خزان',
                'POST /api/tanks': 'إنشاء خزان',
                'PUT /api/tanks/:id': 'تحديث خزان',
                'DELETE /api/tanks/:id': 'حذف خزان',
            },
            branches: {
                'GET /api/branches': 'قائمة الفروع',
                'POST /api/branches': 'إنشاء فرع',
                'PUT /api/branches/:id': 'تحديث فرع',
                'DELETE /api/branches/:id': 'حذف فرع',
            },
            roles: {
                'GET /api/roles': 'قائمة الأدوار',
                'GET /api/roles/permissions': 'قائمة الصلاحيات',
                'POST /api/roles': 'إنشاء دور',
                'PUT /api/roles/:id': 'تحديث دور',
                'DELETE /api/roles/:id': 'حذف دور',
            },
            audit: {
                'GET /api/audit': 'سجل التدقيق',
                'GET /api/audit/stats': 'إحصائيات التدقيق',
            },
            subscriptions: {
                'GET /api/subscriptions/current': 'الاشتراك الحالي',
                'GET /api/subscriptions/history': 'سجل الاشتراكات',
                'GET /api/subscriptions/plans': 'الباقات المتاحة',
            },
        },
    });
});

// ==================== 404 HANDLER ====================
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: `المسار ${req.method} ${req.originalUrl} غير موجود`,
        code: 'NOT_FOUND',
    });
});

// ==================== ERROR HANDLER ====================
app.use((err, req, res, next) => {
    logger.error('Unhandled error:', err);
    res.status(500).json({
        success: false,
        error: process.env.NODE_ENV === 'production' ? 'خطأ داخلي في النظام' : err.message,
        code: 'INTERNAL_ERROR',
    });
});

module.exports = app;
