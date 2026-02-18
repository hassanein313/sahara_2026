// ============================================================
// Subscriptions Module - Controller
// ============================================================
const { query } = require('../../database/connection');

const PLANS = [
    { id: 'trial', name: 'تجريبي', name_en: 'Trial', price: 0, duration_days: 30, max_users: 3, max_stations: 1, max_tanks: 5, features: ['لوحة التحكم', 'إدارة الخزانات', 'التقارير الأساسية'] },
    { id: 'basic', name: 'أساسي', name_en: 'Basic', price: 50000, duration_days: 365, max_users: 5, max_stations: 2, max_tanks: 10, features: ['لوحة التحكم', 'إدارة الخزانات', 'التقارير', 'إدارة المستخدمين', 'الإشعارات'] },
    { id: 'professional', name: 'احترافي', name_en: 'Professional', price: 120000, duration_days: 365, max_users: 15, max_stations: 5, max_tanks: 30, features: ['جميع ميزات الأساسي', 'التقارير المتقدمة', 'سجل التدقيق', 'إدارة الفروع', 'المزامنة السحابية', 'تصدير PDF/Excel'] },
    { id: 'enterprise', name: 'مؤسسي', name_en: 'Enterprise', price: 250000, duration_days: 365, max_users: -1, max_stations: -1, max_tanks: -1, features: ['جميع ميزات الاحترافي', 'مستخدمين غير محدود', 'محطات غير محدودة', 'خزانات غير محدودة', 'دعم فني أولوي', 'تخصيص كامل'] },
];

exports.getCurrent = async (req, res, next) => {
    try {
        const result = await query(
            `SELECT s.*, p.name AS plan_name FROM subscriptions s
       LEFT JOIN subscription_plans p ON s.plan_id = p.id
       WHERE s.tenant_id = $1 AND s.status = 'active' ORDER BY s.end_date DESC LIMIT 1`,
            [req.user.tenantId]);
        if (result.rows.length === 0) return res.json({ success: true, data: { plan: 'trial', status: 'active', message: 'باقة تجريبية' } });
        const sub = result.rows[0];
        const daysLeft = Math.max(0, Math.ceil((new Date(sub.end_date) - new Date()) / 86400000));
        res.json({ success: true, data: { ...sub, days_left: daysLeft } });
    } catch (error) { next(error); }
};

exports.getHistory = async (req, res, next) => {
    try {
        const result = await query(
            `SELECT s.*, p.name AS plan_name FROM subscriptions s
       LEFT JOIN subscription_plans p ON s.plan_id = p.id WHERE s.tenant_id = $1 ORDER BY s.created_at DESC`,
            [req.user.tenantId]);
        res.json({ success: true, data: result.rows });
    } catch (error) { next(error); }
};

exports.getPlans = async (req, res, next) => {
    try { res.json({ success: true, data: PLANS }); }
    catch (error) { next(error); }
};
