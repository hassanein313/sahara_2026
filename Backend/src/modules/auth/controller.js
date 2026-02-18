// ============================================================
// Auth Module - Controller
// ============================================================
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query } = require('../../database/connection');
const { cacheSet, cacheDel } = require('../../config/redis');
const { generateTokens } = require('../../middlewares/auth');
const { logAudit } = require('../../middlewares/audit');
const logger = require('../../config/logger');

exports.login = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        const result = await query(
            `SELECT id, email, name, password_hash, role, is_active, tenant_id, permissions
       FROM users WHERE email = $1`,
            [email.toLowerCase().trim()]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({ success: false, error: 'البريد الإلكتروني أو كلمة المرور غير صحيحة', code: 'INVALID_CREDENTIALS' });
        }

        const user = result.rows[0];

        if (!user.is_active) {
            return res.status(403).json({ success: false, error: 'الحساب معطّل - تواصل مع المسؤول', code: 'ACCOUNT_DISABLED' });
        }

        const validPassword = await bcrypt.compare(password, user.password_hash);
        if (!validPassword) {
            await logAudit({ userId: user.id, action: 'LOGIN_FAILED', resource: 'auth', details: { email }, ipAddress: req.ip, tenantId: user.tenant_id });
            return res.status(401).json({ success: false, error: 'البريد الإلكتروني أو كلمة المرور غير صحيحة', code: 'INVALID_CREDENTIALS' });
        }

        const tokens = generateTokens(user);
        await query('UPDATE users SET last_login = NOW() WHERE id = $1', [user.id]);
        await logAudit({ userId: user.id, action: 'LOGIN_SUCCESS', resource: 'auth', details: { email }, ipAddress: req.ip, tenantId: user.tenant_id });
        await cacheSet(`refresh:${user.id}`, tokens.refreshToken, 7 * 24 * 3600);

        res.json({
            success: true,
            data: {
                user: { id: user.id, name: user.name, email: user.email, role: user.role, permissions: user.permissions || {} },
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
            },
        });
    } catch (error) { next(error); }
};

exports.refreshToken = async (req, res, next) => {
    try {
        const { refreshToken } = req.body;
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || 'refresh_secret');

        const result = await query(
            'SELECT id, email, name, role, is_active, tenant_id FROM users WHERE id = $1 AND is_active = true',
            [decoded.id]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({ success: false, error: 'جلسة غير صالحة', code: 'INVALID_SESSION' });
        }

        const user = result.rows[0];
        const tokens = generateTokens(user);
        await cacheSet(`refresh:${user.id}`, tokens.refreshToken, 7 * 24 * 3600);

        res.json({ success: true, data: { accessToken: tokens.accessToken, refreshToken: tokens.refreshToken } });
    } catch (error) {
        if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
            return res.status(401).json({ success: false, error: 'توكن التجديد منتهي أو غير صالح', code: 'INVALID_REFRESH_TOKEN' });
        }
        next(error);
    }
};

exports.logout = async (req, res, next) => {
    try {
        await cacheDel(`refresh:${req.user.id}`);
        await logAudit({ userId: req.user.id, action: 'LOGOUT', resource: 'auth', ipAddress: req.ip, tenantId: req.user.tenantId });
        res.json({ success: true, message: 'تم تسجيل الخروج بنجاح' });
    } catch (error) { next(error); }
};

exports.changePassword = async (req, res, next) => {
    try {
        const { currentPassword, newPassword } = req.body;
        const result = await query('SELECT password_hash FROM users WHERE id = $1', [req.user.id]);
        const valid = await bcrypt.compare(currentPassword, result.rows[0].password_hash);
        if (!valid) {
            return res.status(400).json({ success: false, error: 'كلمة المرور الحالية غير صحيحة', code: 'WRONG_PASSWORD' });
        }
        const hash = await bcrypt.hash(newPassword, 12);
        await query('UPDATE users SET password_hash = $1 WHERE id = $2', [hash, req.user.id]);
        await logAudit({ userId: req.user.id, action: 'PASSWORD_CHANGED', resource: 'auth', ipAddress: req.ip, tenantId: req.user.tenantId });
        res.json({ success: true, message: 'تم تغيير كلمة المرور بنجاح' });
    } catch (error) { next(error); }
};

exports.getMe = async (req, res, next) => {
    try {
        const result = await query(
            'SELECT id, name, email, phone, role, is_active, permissions, created_at, last_login FROM users WHERE id = $1',
            [req.user.id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, error: 'المستخدم غير موجود', code: 'USER_NOT_FOUND' });
        }
        res.json({ success: true, data: result.rows[0] });
    } catch (error) { next(error); }
};
