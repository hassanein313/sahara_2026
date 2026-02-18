// ============================================================
// Auth Module - Routes
// ============================================================
const router = require('express').Router();
const controller = require('./controller');
const { authenticate } = require('../../middlewares/auth');
const { validate } = require('../../middlewares/rbac');
const Joi = require('joi');

const loginSchema = {
    body: Joi.object({
        email: Joi.string().email().required().label('البريد الإلكتروني'),
        password: Joi.string().min(4).required().label('كلمة المرور'),
    }),
};

const changePasswordSchema = {
    body: Joi.object({
        currentPassword: Joi.string().required().label('كلمة المرور الحالية'),
        newPassword: Joi.string().min(6).required().label('كلمة المرور الجديدة'),
    }),
};

const refreshSchema = {
    body: Joi.object({
        refreshToken: Joi.string().required().label('توكن التجديد'),
    }),
};

router.post('/login', validate(loginSchema), controller.login);
router.post('/refresh', validate(refreshSchema), controller.refreshToken);
router.post('/logout', authenticate, controller.logout);
router.post('/change-password', authenticate, validate(changePasswordSchema), controller.changePassword);
router.get('/me', authenticate, controller.getMe);

module.exports = router;
