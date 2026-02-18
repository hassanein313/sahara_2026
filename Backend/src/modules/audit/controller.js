// ============================================================
// Audit Module - Controller (Read-Only)
// ============================================================
const { query } = require('../../database/connection');
const { cacheGet, cacheSet } = require('../../config/redis');

exports.list = async (req, res, next) => {
    try {
        const { page = 1, limit = 50, action, resource, user_id, from, to } = req.query;
        const offset = (page - 1) * limit;
        const params = [req.user.tenantId]; const conds = ['a.tenant_id = $1'];
        if (action) { params.push(action); conds.push(`a.action = $${params.length}`); }
        if (resource) { params.push(resource); conds.push(`a.resource = $${params.length}`); }
        if (user_id) { params.push(user_id); conds.push(`a.user_id = $${params.length}`); }
        if (from) { params.push(from); conds.push(`a.created_at >= $${params.length}`); }
        if (to) { params.push(to); conds.push(`a.created_at <= $${params.length}`); }
        const where = `WHERE ${conds.join(' AND ')}`;
        const countR = await query(`SELECT COUNT(*) FROM audit_logs a ${where}`, params);
        params.push(limit, offset);
        const result = await query(
            `SELECT a.*, u.name AS user_name, u.email AS user_email, u.role AS user_role
       FROM audit_logs a LEFT JOIN users u ON a.user_id = u.id ${where}
       ORDER BY a.created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`, params);
        res.json({ success: true, data: result.rows, pagination: { total: parseInt(countR.rows[0].count), page: parseInt(page), limit: parseInt(limit), pages: Math.ceil(countR.rows[0].count / limit) } });
    } catch (error) { next(error); }
};

exports.stats = async (req, res, next) => {
    try {
        const cacheKey = `audit:stats:${req.user.tenantId}`;
        const cached = await cacheGet(cacheKey);
        if (cached) return res.json({ success: true, data: cached });
        const [byAction, byUser, byDay, totals] = await Promise.all([
            query(`SELECT action, COUNT(*) AS count FROM audit_logs WHERE tenant_id = $1 AND created_at >= NOW()-INTERVAL '30 days' GROUP BY action ORDER BY count DESC LIMIT 20`, [req.user.tenantId]),
            query(`SELECT a.user_id, u.name AS user_name, COUNT(*) AS count FROM audit_logs a LEFT JOIN users u ON a.user_id=u.id WHERE a.tenant_id=$1 AND a.created_at >= NOW()-INTERVAL '30 days' GROUP BY a.user_id,u.name ORDER BY count DESC LIMIT 10`, [req.user.tenantId]),
            query(`SELECT created_at::date AS day, COUNT(*) AS count FROM audit_logs WHERE tenant_id=$1 AND created_at >= NOW()-INTERVAL '30 days' GROUP BY 1 ORDER BY day DESC`, [req.user.tenantId]),
            query(`SELECT COUNT(*) AS total, COUNT(CASE WHEN created_at::date=CURRENT_DATE THEN 1 END) AS today, COUNT(CASE WHEN created_at >= NOW()-INTERVAL '7 days' THEN 1 END) AS this_week FROM audit_logs WHERE tenant_id=$1`, [req.user.tenantId]),
        ]);
        const data = { totals: totals.rows[0], byAction: byAction.rows, byUser: byUser.rows, byDay: byDay.rows };
        await cacheSet(cacheKey, data, 300);
        res.json({ success: true, data });
    } catch (error) { next(error); }
};
