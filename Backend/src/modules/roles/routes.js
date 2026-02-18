// ============================================================
// Roles Module - Routes
// ============================================================
const router = require('express').Router();
const controller = require('./controller');
const { authenticate, authorize } = require('../../middlewares/auth');
const { validate } = require('../../middlewares/rbac');
const { auditMiddleware } = require('../../middlewares/audit');
const Joi = require('joi');

const schema = {
    body: Joi.object({
        name: Joi.string().min(2).max(50).required().label('اسم الدور'),
        description: Joi.string().max(200).optional().label('الوصف'),
        permissions: Joi.object().required().label('الصلاحيات'),
    }),
};

router.use(authenticate);
router.get('/', controller.list);
router.get('/permissions', controller.listPermissions);
router.post('/', authorize('admin'), validate(schema), auditMiddleware('CREATE_ROLE', 'roles'), controller.create);
router.put('/:id', authorize('admin'), auditMiddleware('UPDATE_ROLE', 'roles'), controller.update);
router.delete('/:id', authorize('admin'), auditMiddleware('DELETE_ROLE', 'roles'), controller.remove);

module.exports = router;
