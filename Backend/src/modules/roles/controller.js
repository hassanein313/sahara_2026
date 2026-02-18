// ============================================================
// Roles Module - Controller
// ============================================================
const { v4: uuidv4 } = require('uuid');
const { query } = require('../../database/connection');
const { cacheDel } = require('../../config/redis');
const logger = require('../../config/logger');

const ALL_PERMISSIONS = {
    dashboard: { label: 'لوحة التحكم', group: 'عام' },
    incoming_report: { label: 'تقارير الوارد', group: 'التقارير' },
    sahara_balance: { label: 'رصيد صحاري', group: 'المالية' },
    union_balance: { label: 'رصيد الاتحاد', group: 'المالية' },
    tanks: { label: 'إدارة الخزانات', group: 'العمليات' },
    reports: { label: 'التقارير', group: 'التقارير' },
    advanced_reports: { label: 'تقارير متقدمة', group: 'التقارير' },
    station_manager: { label: 'إدارة المحطات', group: 'العمليات' },
    notifications: { label: 'الإشعارات', group: 'عام' },
    settings: { label: 'الإعدادات', group: 'النظام' },
    audit_trail: { label: 'سجل التدقيق', group: 'النظام' },
    users_manage: { label: 'إدارة المستخدمين', group: 'النظام' },
    branches_manage: { label: 'إدارة الفروع', group: 'النظام' },
    fuel_create: { label: 'إنشاء معاملات الوقود', group: 'العمليات' },
    fuel_approve: { label: 'الموافقة على المعاملات', group: 'العمليات' },
    fuel_delete: { label: 'حذف المعاملات', group: 'العمليات' },
    tanks_manage: { label: 'إدارة الخزانات', group: 'العمليات' },
    export_data: { label: 'تصدير البيانات', group: 'التقارير' },
};

exports.list = async (req, res, next) => {
    try {
        const result = await query(
            `SELECT r.*, (SELECT COUNT(*) FROM users u WHERE u.role = r.name AND u.tenant_id = r.tenant_id) AS user_count
       FROM roles r WHERE r.tenant_id = $1 OR r.is_system = true ORDER BY r.is_system DESC, r.name ASC`,
            [req.user.tenantId]);
        res.json({ success: true, data: result.rows });
    } catch (error) { next(error); }
};

exports.listPermissions = async (req, res, next) => {
    try {
        const groups = {};
        for (const [key, val] of Object.entries(ALL_PERMISSIONS)) {
            if (!groups[val.group]) groups[val.group] = [];
            groups[val.group].push({ key, label: val.label });
        }
        res.json({ success: true, data: { permissions: ALL_PERMISSIONS, groups } });
    } catch (error) { next(error); }
};

exports.create = async (req, res, next) => {
    try {
        const { name, description, permissions } = req.body;
        const existing = await query('SELECT id FROM roles WHERE name = $1 AND (tenant_id = $2 OR is_system = true)', [name, req.user.tenantId]);
        if (existing.rows.length > 0) return res.status(409).json({ success: false, error: 'الاسم مستخدم', code: 'ROLE_EXISTS' });
        const result = await query(
            `INSERT INTO roles (id, tenant_id, name, description, permissions, is_system, created_at)
       VALUES ($1,$2,$3,$4,$5,false,NOW()) RETURNING *`,
            [uuidv4(), req.user.tenantId, name, description || '', JSON.stringify(permissions)]);
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (error) { next(error); }
};

exports.update = async (req, res, next) => {
    try {
        const check = await query('SELECT is_system FROM roles WHERE id = $1', [req.params.id]);
        if (check.rows.length === 0) return res.status(404).json({ success: false, error: 'الدور غير موجود', code: 'NOT_FOUND' });
        if (check.rows[0].is_system) return res.status(400).json({ success: false, error: 'لا يمكن تعديل الأدوار المضمنة', code: 'SYSTEM_ROLE' });
        const { name, description, permissions } = req.body;
        const result = await query(
            `UPDATE roles SET name = COALESCE($1,name), description = COALESCE($2,description),
       permissions = COALESCE($3,permissions), updated_at = NOW() WHERE id = $4 AND tenant_id = $5 RETURNING *`,
            [name, description, permissions ? JSON.stringify(permissions) : null, req.params.id, req.user.tenantId]);
        await cacheDel('perms:*');
        res.json({ success: true, data: result.rows[0] });
    } catch (error) { next(error); }
};

exports.remove = async (req, res, next) => {
    try {
        const check = await query('SELECT is_system FROM roles WHERE id = $1', [req.params.id]);
        if (check.rows.length > 0 && check.rows[0].is_system) return res.status(400).json({ success: false, error: 'لا يمكن حذف الأدوار المضمنة', code: 'SYSTEM_ROLE' });
        const usersCheck = await query(`SELECT COUNT(*) FROM users WHERE role = (SELECT name FROM roles WHERE id = $1) AND tenant_id = $2`, [req.params.id, req.user.tenantId]);
        if (parseInt(usersCheck.rows[0].count) > 0) return res.status(400).json({ success: false, error: 'الدور مرتبط بمستخدمين', code: 'HAS_USERS' });
        const result = await query('DELETE FROM roles WHERE id = $1 AND tenant_id = $2 AND is_system = false RETURNING id', [req.params.id, req.user.tenantId]);
        if (result.rows.length === 0) return res.status(404).json({ success: false, error: 'الدور غير موجود', code: 'NOT_FOUND' });
        res.json({ success: true, message: 'تم حذف الدور بنجاح' });
    } catch (error) { next(error); }
};
