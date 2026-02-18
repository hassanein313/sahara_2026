// ============================================================
// Users Module - Routes
// ============================================================
const router = require('express').Router();
const controller = require('./controller');
const { authenticate, authorize } = require('../../middlewares/auth');
const { validate } = require('../../middlewares/rbac');
const { auditMiddleware } = require('../../middlewares/audit');
const Joi = require('joi');

const createSchema = {
    body: Joi.object({
        name: Joi.string().min(2).max(100).required().label('الاسم'),
        email: Joi.string().email().required().label('البريد الإلكتروني'),
        password: Joi.string().min(6).required().label('كلمة المرور'),
        phone: Joi.string().allow('').optional().label('الهاتف'),
        role: Joi.string().valid('admin', 'manager', 'operator', 'viewer', 'auditor').required().label('الدور'),
        permissions: Joi.object().optional(),
    }),
};

const updateSchema = {
    params: Joi.object({ id: Joi.string().uuid().required() }),
    body: Joi.object({
        name: Joi.string().min(2).max(100).optional(),
        email: Joi.string().email().optional(),
        phone: Joi.string().allow('').optional(),
        role: Joi.string().valid('admin', 'manager', 'operator', 'viewer', 'auditor').optional(),
        is_active: Joi.boolean().optional(),
        permissions: Joi.object().optional(),
    }),
};

router.use(authenticate);
router.get('/', controller.list);
router.get('/:id', controller.getById);
router.post('/', authorize('admin'), validate(createSchema), auditMiddleware('CREATE_USER', 'users'), controller.create);
router.put('/:id', authorize('admin'), validate(updateSchema), auditMiddleware('UPDATE_USER', 'users'), controller.update);
router.delete('/:id', authorize('admin'), auditMiddleware('DELETE_USER', 'users'), controller.remove);

module.exports = router;
