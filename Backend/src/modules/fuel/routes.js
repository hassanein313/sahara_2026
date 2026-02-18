// ============================================================
// Fuel Module - Routes
// ============================================================
const router = require('express').Router();
const controller = require('./controller');
const { authenticate, authorize } = require('../../middlewares/auth');
const { validate } = require('../../middlewares/rbac');
const { auditMiddleware } = require('../../middlewares/audit');
const Joi = require('joi');

const createSchema = {
    body: Joi.object({
        type: Joi.string().valid('incoming', 'outgoing', 'transfer').required().label('نوع المعاملة'),
        fuel_type: Joi.string().valid('benzene', 'diesel', 'kerosene', 'gas').required().label('نوع الوقود'),
        quantity: Joi.number().positive().required().label('الكمية'),
        unit_price: Joi.number().min(0).optional().label('سعر الوحدة'),
        supplier: Joi.string().max(200).optional().label('المورّد'),
        tank_id: Joi.string().uuid().optional().label('الخزان'),
        destination_tank_id: Joi.string().uuid().optional().label('الخزان الهدف'),
        driver_name: Joi.string().max(100).optional().label('اسم السائق'),
        truck_number: Joi.string().max(50).optional().label('رقم الشاحنة'),
        density: Joi.number().min(0.5).max(1.5).optional().label('الكثافة'),
        color_rating: Joi.number().min(0).max(5).optional().label('تقييم اللون'),
        notes: Joi.string().max(500).allow('').optional().label('ملاحظات'),
    }),
};

router.use(authenticate);
router.get('/', controller.list);
router.get('/stats/summary', controller.stats);
router.get('/:id', controller.getById);
router.post('/', authorize('admin', 'manager', 'operator'), validate(createSchema), auditMiddleware('CREATE_FUEL', 'fuel'), controller.create);
router.patch('/:id/approve', authorize('admin', 'manager'), auditMiddleware('APPROVE_FUEL', 'fuel'), controller.approve);
router.delete('/:id', authorize('admin'), auditMiddleware('DELETE_FUEL', 'fuel'), controller.remove);

module.exports = router;
