// ============================================================
// Import Module - Routes
// ============================================================
const router = require('express').Router();
const controller = require('./controller');
const { authenticate, authorize } = require('../../middlewares/auth');

router.use(authenticate);

// استيراد معاملات وقود (CSV/JSON)
router.post('/fuel', authorize('admin', 'manager'), controller.importFuel);

// استيراد خزانات
router.post('/tanks', authorize('admin', 'manager'), controller.importTanks);

// إنشاء بيانات تجريبية شاملة
router.post('/seed-demo', authorize('admin'), controller.seedDemo);

module.exports = router;
