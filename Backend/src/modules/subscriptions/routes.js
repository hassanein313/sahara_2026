// ============================================================
// Subscriptions Module - Routes
// ============================================================
const router = require('express').Router();
const controller = require('./controller');
const { authenticate } = require('../../middlewares/auth');

router.use(authenticate);
router.get('/current', controller.getCurrent);
router.get('/history', controller.getHistory);
router.get('/plans', controller.getPlans);

module.exports = router;
