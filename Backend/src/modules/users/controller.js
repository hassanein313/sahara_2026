// ============================================================
// Users Module - Controller
// ============================================================
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { query } = require('../../database/connection');
const { cacheDel } = require('../../config/redis');
const { getDefaultPermissions } = require('../../middlewares/rbac');
const logger = require('../../config/logger');

exports.list = async (req, res, next) => {
    try {
        const { page = 1, limit = 50, role, search } = req.query;
        const offset = (page - 1) * limit;
        const params = [req.user.tenantId];
        const conditions = ['tenant_id = $1'];

        if (role) { params.push(role); conditions.push(`role = $${params.length}`); }
        if (search) { params.push(`%${search}%`); conditions.push(`(name ILIKE $${params.length} OR email ILIKE $${params.length})`); }

        const where = `WHERE ${conditions.join(' AND ')}`;
        const countResult = await query(`SELECT COUNT(*) FROM users ${where}`, params);
        params.push(limit, offset);
        const result = await query(
            `SELECT id, name, email, phone, role, is_active, permissions, created_at, last_login
       FROM users ${where} ORDER BY created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`,
            params
        );

        res.json({
            success: true, data: result.rows,
            pagination: { total: parseInt(countResult.rows[0].count), page: parseInt(page), limit: parseInt(limit), pages: Math.ceil(countResult.rows[0].count / limit) },
        });
    } catch (error) { next(error); }
};

exports.getById = async (req, res, next) => {
    try {
        const result = await query(
            'SELECT id, name, email, phone, role, is_active, permissions, created_at, last_login FROM users WHERE id = $1 AND tenant_id = $2',
            [req.params.id, req.user.tenantId]
        );
        if (result.rows.length === 0) return res.status(404).json({ success: false, error: 'المستخدم غير موجود', code: 'USER_NOT_FOUND' });
        res.json({ success: true, data: result.rows[0] });
    } catch (error) { next(error); }
};

exports.create = async (req, res, next) => {
    try {
        const { name, email, password, phone, role, permissions } = req.body;
        const existing = await query('SELECT id FROM users WHERE email = $1', [email.toLowerCase()]);
        if (existing.rows.length > 0) {
            return res.status(409).json({ success: false, error: 'البريد الإلكتروني مستخدم مسبقاً', code: 'EMAIL_EXISTS' });
        }

        const id = uuidv4();
        const passwordHash = await bcrypt.hash(password, 12);
        const userPerms = permissions || getDefaultPermissions(role);

        const result = await query(
            `INSERT INTO users (id, name, email, password_hash, phone, role, is_active, permissions, tenant_id, created_at)
       VALUES ($1,$2,$3,$4,$5,$6,true,$7,$8,NOW())
       RETURNING id, name, email, phone, role, is_active, permissions, created_at`,
            [id, name, email.toLowerCase(), passwordHash, phone || '', role, JSON.stringify(userPerms), req.user.tenantId]
        );

        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (error) { next(error); }
};

exports.update = async (req, res, next) => {
    try {
        const { name, email, phone, role, is_active, permissions } = req.body;
        const updates = []; const params = []; let idx = 1;

        if (name !== undefined) { updates.push(`name = $${idx++}`); params.push(name); }
        if (email !== undefined) { updates.push(`email = $${idx++}`); params.push(email.toLowerCase()); }
        if (phone !== undefined) { updates.push(`phone = $${idx++}`); params.push(phone); }
        if (role !== undefined) { updates.push(`role = $${idx++}`); params.push(role); }
        if (is_active !== undefined) { updates.push(`is_active = $${idx++}`); params.push(is_active); }
        if (permissions !== undefined) { updates.push(`permissions = $${idx++}`); params.push(JSON.stringify(permissions)); }

        if (updates.length === 0) return res.status(400).json({ success: false, error: 'لا توجد بيانات للتحديث', code: 'NO_DATA' });

        updates.push('updated_at = NOW()');
        params.push(req.params.id, req.user.tenantId);

        const result = await query(
            `UPDATE users SET ${updates.join(', ')} WHERE id = $${idx++} AND tenant_id = $${idx} RETURNING id, name, email, phone, role, is_active, permissions, created_at, updated_at`,
            params
        );

        if (result.rows.length === 0) return res.status(404).json({ success: false, error: 'المستخدم غير موجود', code: 'USER_NOT_FOUND' });
        await cacheDel(`perms:${req.params.id}`);
        res.json({ success: true, data: result.rows[0] });
    } catch (error) { next(error); }
};

exports.remove = async (req, res, next) => {
    try {
        if (req.params.id === req.user.id) {
            return res.status(400).json({ success: false, error: 'لا يمكنك حذف حسابك بنفسك', code: 'CANNOT_DELETE_SELF' });
        }
        const result = await query('DELETE FROM users WHERE id = $1 AND tenant_id = $2 RETURNING id', [req.params.id, req.user.tenantId]);
        if (result.rows.length === 0) return res.status(404).json({ success: false, error: 'المستخدم غير موجود', code: 'USER_NOT_FOUND' });
        await cacheDel(`perms:${req.params.id}`);
        res.json({ success: true, message: 'تم حذف المستخدم بنجاح' });
    } catch (error) { next(error); }
};
