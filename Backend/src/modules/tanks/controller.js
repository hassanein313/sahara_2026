// ============================================================
// Tanks Module - Controller
// ============================================================
const { v4: uuidv4 } = require('uuid');
const { query } = require('../../database/connection');
const { cacheGet, cacheSet, cacheDel } = require('../../config/redis');
const logger = require('../../config/logger');

exports.list = async (req, res, next) => {
    try {
        const { status, fuel_type, branch_id } = req.query;
        const params = [req.user.tenantId]; const conds = ['t.tenant_id = $1'];
        if (status) { params.push(status); conds.push(`t.status = $${params.length}`); }
        if (fuel_type) { params.push(fuel_type); conds.push(`t.fuel_type = $${params.length}`); }
        if (branch_id) { params.push(branch_id); conds.push(`t.branch_id = $${params.length}`); }
        const result = await query(
            `SELECT t.*, b.name AS branch_name, ROUND((t.current_level / NULLIF(t.capacity,0))*100,1) AS fill_percentage
       FROM tanks t LEFT JOIN branches b ON t.branch_id = b.id
       WHERE ${conds.join(' AND ')} ORDER BY t.name ASC`, params);
        res.json({ success: true, data: result.rows });
    } catch (error) { next(error); }
};

exports.getById = async (req, res, next) => {
    try {
        const result = await query(
            `SELECT t.*, b.name AS branch_name, ROUND((t.current_level / NULLIF(t.capacity,0))*100,1) AS fill_percentage
       FROM tanks t LEFT JOIN branches b ON t.branch_id = b.id WHERE t.id = $1 AND t.tenant_id = $2`,
            [req.params.id, req.user.tenantId]);
        if (result.rows.length === 0) return res.status(404).json({ success: false, error: 'الخزان غير موجود', code: 'NOT_FOUND' });
        const ops = await query(
            `SELECT id, type, quantity, fuel_type, created_at, status FROM fuel_transactions
       WHERE (tank_id = $1 OR destination_tank_id = $1) AND tenant_id = $2 ORDER BY created_at DESC LIMIT 10`,
            [req.params.id, req.user.tenantId]);
        res.json({ success: true, data: { ...result.rows[0], recent_operations: ops.rows } });
    } catch (error) { next(error); }
};

exports.create = async (req, res, next) => {
    try {
        const id = uuidv4();
        const { name, location, fuel_type, capacity, current_level, min_level, max_temperature, branch_id } = req.body;
        const fill = (current_level || 0) / capacity;
        const status = fill <= 0.1 ? 'inactive' : 'active';
        const result = await query(
            `INSERT INTO tanks (id, tenant_id, name, location, fuel_type, capacity, current_level, min_level, max_temperature, status, branch_id, created_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,NOW()) RETURNING *`,
            [id, req.user.tenantId, name, location || '', fuel_type, capacity, current_level || 0, min_level || capacity * 0.1, max_temperature || 45, status, branch_id]);
        await cacheDel(`tanks:${req.user.tenantId}*`);
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (error) { next(error); }
};

exports.update = async (req, res, next) => {
    try {
        const fields = req.body; const updates = []; const params = []; let idx = 1;
        for (const [key, val] of Object.entries(fields)) { updates.push(`${key} = $${idx++}`); params.push(val); }
        if (updates.length === 0) return res.status(400).json({ success: false, error: 'لا توجد بيانات', code: 'NO_DATA' });
        updates.push('updated_at = NOW()');
        params.push(req.params.id, req.user.tenantId);
        const result = await query(`UPDATE tanks SET ${updates.join(', ')} WHERE id = $${idx++} AND tenant_id = $${idx} RETURNING *`, params);
        if (result.rows.length === 0) return res.status(404).json({ success: false, error: 'الخزان غير موجود', code: 'NOT_FOUND' });
        await cacheDel(`tanks:${req.user.tenantId}*`);
        res.json({ success: true, data: result.rows[0] });
    } catch (error) { next(error); }
};

exports.remove = async (req, res, next) => {
    try {
        const txnCheck = await query('SELECT COUNT(*) FROM fuel_transactions WHERE tank_id = $1', [req.params.id]);
        if (parseInt(txnCheck.rows[0].count) > 0) {
            return res.status(400).json({ success: false, error: 'لا يمكن حذف خزان مرتبط بمعاملات', code: 'HAS_TRANSACTIONS' });
        }
        const result = await query('DELETE FROM tanks WHERE id = $1 AND tenant_id = $2 RETURNING id', [req.params.id, req.user.tenantId]);
        if (result.rows.length === 0) return res.status(404).json({ success: false, error: 'الخزان غير موجود', code: 'NOT_FOUND' });
        await cacheDel(`tanks:${req.user.tenantId}*`);
        res.json({ success: true, message: 'تم حذف الخزان بنجاح' });
    } catch (error) { next(error); }
};
