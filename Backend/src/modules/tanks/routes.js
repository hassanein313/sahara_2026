// ============================================================
// Tanks Module - Routes
// ============================================================
const router = require('express').Router();
const controller = require('./controller');
const { authenticate, authorize } = require('../../middlewares/auth');
const { validate } = require('../../middlewares/rbac');
const { auditMiddleware } = require('../../middlewares/audit');
const Joi = require('joi');

const createSchema = {
    body: Joi.object({
        name: Joi.string().min(2).max(100).required().label('اسم الخزان'),
        location: Joi.string().max(200).optional().label('الموقع'),
        fuel_type: Joi.string().valid('benzene', 'diesel', 'kerosene', 'gas').required().label('نوع الوقود'),
        capacity: Joi.number().positive().required().label('السعة'),
        current_level: Joi.number().min(0).optional().default(0).label('المستوى الحالي'),
        min_level: Joi.number().min(0).optional().label('الحد الأدنى'),
        max_temperature: Joi.number().optional().label('الحرارة القصوى'),
        branch_id: Joi.string().uuid().optional().label('الفرع'),
    }),
};

const updateSchema = {
    params: Joi.object({ id: Joi.string().uuid().required() }),
    body: Joi.object({
        name: Joi.string().min(2).max(100).optional(), location: Joi.string().max(200).optional(),
        fuel_type: Joi.string().valid('benzene', 'diesel', 'kerosene', 'gas').optional(),
        capacity: Joi.number().positive().optional(), current_level: Joi.number().min(0).optional(),
        min_level: Joi.number().min(0).optional(), max_temperature: Joi.number().optional(),
        temperature: Joi.number().optional(),
        status: Joi.string().valid('active', 'maintenance', 'inactive').optional(),
        branch_id: Joi.string().uuid().allow(null).optional(),
    }),
};

router.use(authenticate);
router.get('/', controller.list);
router.get('/:id', controller.getById);
router.post('/', authorize('admin', 'manager'), validate(createSchema), auditMiddleware('CREATE_TANK', 'tanks'), controller.create);
router.put('/:id', authorize('admin', 'manager'), validate(updateSchema), auditMiddleware('UPDATE_TANK', 'tanks'), controller.update);
router.delete('/:id', authorize('admin'), auditMiddleware('DELETE_TANK', 'tanks'), controller.remove);

module.exports = router;
