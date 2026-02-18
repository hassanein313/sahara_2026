// ============================================================
// Branches Module - Controller
// ============================================================
const { v4: uuidv4 } = require('uuid');
const { query } = require('../../database/connection');
const logger = require('../../config/logger');

exports.list = async (req, res, next) => {
    try {
        const result = await query(
            `SELECT b.*, u.name AS manager_name,
         (SELECT COUNT(*) FROM tanks t WHERE t.branch_id = b.id) AS tank_count,
         (SELECT COUNT(*) FROM users u2 WHERE u2.branch_id = b.id) AS user_count
       FROM branches b LEFT JOIN users u ON b.manager_id = u.id
       WHERE b.tenant_id = $1 ORDER BY b.name ASC`, [req.user.tenantId]);
        res.json({ success: true, data: result.rows });
    } catch (error) { next(error); }
};

exports.create = async (req, res, next) => {
    try {
        const id = uuidv4();
        const { name, code, address, phone, manager_id, daily_target } = req.body;
        const result = await query(
            `INSERT INTO branches (id, tenant_id, name, code, address, phone, manager_id, daily_target, is_active, created_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,true,NOW()) RETURNING *`,
            [id, req.user.tenantId, name, code || '', address || '', phone || '', manager_id, daily_target || 0]);
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (error) { next(error); }
};

exports.update = async (req, res, next) => {
    try {
        const allowed = ['name', 'code', 'address', 'phone', 'manager_id', 'is_active', 'daily_target'];
        const updates = []; const params = []; let idx = 1;
        for (const [key, val] of Object.entries(req.body)) {
            if (allowed.includes(key)) { updates.push(`${key} = $${idx++}`); params.push(val); }
        }
        if (updates.length === 0) return res.status(400).json({ success: false, error: 'لا بيانات', code: 'NO_DATA' });
        updates.push('updated_at = NOW()');
        params.push(req.params.id, req.user.tenantId);
        const result = await query(`UPDATE branches SET ${updates.join(', ')} WHERE id = $${idx++} AND tenant_id = $${idx} RETURNING *`, params);
        if (result.rows.length === 0) return res.status(404).json({ success: false, error: 'الفرع غير موجود', code: 'NOT_FOUND' });
        res.json({ success: true, data: result.rows[0] });
    } catch (error) { next(error); }
};

exports.remove = async (req, res, next) => {
    try {
        const tankCheck = await query('SELECT COUNT(*) FROM tanks WHERE branch_id = $1', [req.params.id]);
        if (parseInt(tankCheck.rows[0].count) > 0) return res.status(400).json({ success: false, error: 'لا يمكن حذف فرع يحتوي خزانات', code: 'HAS_TANKS' });
        const result = await query('DELETE FROM branches WHERE id = $1 AND tenant_id = $2 RETURNING id', [req.params.id, req.user.tenantId]);
        if (result.rows.length === 0) return res.status(404).json({ success: false, error: 'الفرع غير موجود', code: 'NOT_FOUND' });
        res.json({ success: true, message: 'تم حذف الفرع بنجاح' });
    } catch (error) { next(error); }
};
