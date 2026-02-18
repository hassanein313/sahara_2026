// ============================================================
// Branches Module - Routes
// ============================================================
const router = require('express').Router();
const controller = require('./controller');
const { authenticate, authorize } = require('../../middlewares/auth');
const { validate } = require('../../middlewares/rbac');
const { auditMiddleware } = require('../../middlewares/audit');
const Joi = require('joi');

const schema = {
    body: Joi.object({
        name: Joi.string().min(2).max(100).required().label('اسم الفرع'),
        code: Joi.string().max(20).optional().label('رمز الفرع'),
        address: Joi.string().max(300).optional().label('العنوان'),
        phone: Joi.string().max(20).optional().label('الهاتف'),
        manager_id: Joi.string().uuid().allow(null).optional().label('المدير'),
        is_active: Joi.boolean().optional(),
        daily_target: Joi.number().min(0).optional().label('الهدف اليومي'),
    }),
};

router.use(authenticate);
router.get('/', controller.list);
router.post('/', authorize('admin'), validate(schema), auditMiddleware('CREATE_BRANCH', 'branches'), controller.create);
router.put('/:id', authorize('admin', 'manager'), auditMiddleware('UPDATE_BRANCH', 'branches'), controller.update);
router.delete('/:id', authorize('admin'), auditMiddleware('DELETE_BRANCH', 'branches'), controller.remove);

module.exports = router;
