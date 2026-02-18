// ============================================================
// Audit Module - Routes (Read-Only)
// ============================================================
const router = require('express').Router();
const controller = require('./controller');
const { authenticate, authorize } = require('../../middlewares/auth');

router.use(authenticate);
router.use(authorize('admin', 'auditor'));
router.get('/', controller.list);
router.get('/stats', controller.stats);

module.exports = router;
