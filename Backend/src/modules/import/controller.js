// ============================================================
// Import Module - Controller (Bulk data import)
// ============================================================
const { v4: uuidv4 } = require('uuid');
const { query, transaction } = require('../../database/connection');
const { cacheDel } = require('../../config/redis');
const logger = require('../../config/logger');

// ==================== استيراد معاملات وقود ====================
exports.importFuel = async (req, res, next) => {
    try {
        const { records } = req.body;
        if (!Array.isArray(records) || records.length === 0) {
            return res.status(400).json({ success: false, error: 'يجب إرسال مصفوفة records', code: 'INVALID_DATA' });
        }
        if (records.length > 500) {
            return res.status(400).json({ success: false, error: 'الحد الأقصى 500 سجل في الطلب الواحد', code: 'TOO_MANY' });
        }

        const results = { imported: 0, errors: [], skipped: 0 };
        const tenantId = req.user.tenantId;
        const userId = req.user.id;

        await transaction(async (client) => {
            for (let i = 0; i < records.length; i++) {
                const r = records[i];
                try {
                    // التحقق من البيانات المطلوبة
                    if (!r.type || !r.fuel_type || !r.quantity) {
                        results.errors.push({ row: i + 1, error: 'بيانات ناقصة: type, fuel_type, quantity مطلوبة' });
                        results.skipped++;
                        continue;
                    }
                    if (!['incoming', 'outgoing', 'transfer'].includes(r.type)) {
                        results.errors.push({ row: i + 1, error: `نوع غير صالح: ${r.type}` });
                        results.skipped++;
                        continue;
                    }
                    if (!['benzene', 'diesel', 'kerosene', 'gas'].includes(r.fuel_type)) {
                        results.errors.push({ row: i + 1, error: `نوع وقود غير صالح: ${r.fuel_type}` });
                        results.skipped++;
                        continue;
                    }

                    const id = uuidv4();
                    const quantity = parseFloat(r.quantity);
                    const unitPrice = parseFloat(r.unit_price) || 0;
                    const totalPrice = quantity * unitPrice;
                    const createdAt = r.date ? new Date(r.date) : new Date();

                    // إدخال المعاملة
                    await client.query(
                        `INSERT INTO fuel_transactions (id, tenant_id, type, fuel_type, quantity, unit_price, total_price, supplier, tank_id, driver_name, truck_number, density, notes, status, created_by, created_at)
                         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,'approved',$14,$15)`,
                        [id, tenantId, r.type, r.fuel_type, quantity, unitPrice, totalPrice,
                            r.supplier || null, r.tank_id || null, r.driver_name || null,
                            r.truck_number || null, r.density || null, r.notes || null,
                            userId, createdAt]
                    );

                    // تحديث الخزان إذا محدد
                    if (r.tank_id) {
                        if (r.type === 'incoming') {
                            await client.query('UPDATE tanks SET current_level = current_level + $1, last_fill = NOW(), updated_at = NOW() WHERE id = $2 AND tenant_id = $3', [quantity, r.tank_id, tenantId]);
                        } else if (r.type === 'outgoing') {
                            await client.query('UPDATE tanks SET current_level = GREATEST(0, current_level - $1), updated_at = NOW() WHERE id = $2 AND tenant_id = $3', [quantity, r.tank_id, tenantId]);
                        }
                    }

                    results.imported++;
                } catch (err) {
                    results.errors.push({ row: i + 1, error: err.message });
                    results.skipped++;
                }
            }
        });

        await cacheDel('fuel:stats:*');
        logger.info(`[IMPORT] User ${userId} imported ${results.imported} fuel records`);

        res.json({
            success: true,
            data: results,
            message: `تم استيراد ${results.imported} سجل بنجاح${results.skipped > 0 ? ` (تم تخطي ${results.skipped})` : ''}`
        });
    } catch (error) { next(error); }
};

// ==================== استيراد خزانات ====================
exports.importTanks = async (req, res, next) => {
    try {
        const { records } = req.body;
        if (!Array.isArray(records) || records.length === 0) {
            return res.status(400).json({ success: false, error: 'يجب إرسال مصفوفة records', code: 'INVALID_DATA' });
        }

        const results = { imported: 0, errors: [], skipped: 0 };
        const tenantId = req.user.tenantId;

        await transaction(async (client) => {
            for (let i = 0; i < records.length; i++) {
                const r = records[i];
                try {
                    if (!r.name || !r.fuel_type || !r.capacity) {
                        results.errors.push({ row: i + 1, error: 'بيانات ناقصة: name, fuel_type, capacity مطلوبة' });
                        results.skipped++;
                        continue;
                    }

                    const id = uuidv4();
                    const capacity = parseFloat(r.capacity);
                    const currentLevel = parseFloat(r.current_level) || 0;
                    const status = currentLevel / capacity <= 0.1 ? 'inactive' : 'active';

                    await client.query(
                        `INSERT INTO tanks (id, tenant_id, name, location, fuel_type, capacity, current_level, min_level, max_temperature, status, branch_id, created_at)
                         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,NOW())`,
                        [id, tenantId, r.name, r.location || '', r.fuel_type, capacity, currentLevel,
                            r.min_level || capacity * 0.1, r.max_temperature || 45, status, r.branch_id || null]
                    );
                    results.imported++;
                } catch (err) {
                    results.errors.push({ row: i + 1, error: err.message });
                    results.skipped++;
                }
            }
        });

        await cacheDel(`tanks:${req.user.tenantId}*`);
        res.json({
            success: true,
            data: results,
            message: `تم استيراد ${results.imported} خزان بنجاح`
        });
    } catch (error) { next(error); }
};

// ==================== استيراد بيانات تجريبية شاملة ====================
exports.seedDemo = async (req, res, next) => {
    try {
        const tenantId = req.user.tenantId;
        const userId = req.user.id;
        const results = { tanks: 0, transactions: 0 };

        await transaction(async (client) => {
            // -------- إنشاء خزانات تجريبية --------
            const tanks = [
                { name: 'خزان البنزين الرئيسي', fuel_type: 'benzene', capacity: 50000, current_level: 35000, location: 'المنطقة أ' },
                { name: 'خزان الديزل المركزي', fuel_type: 'diesel', capacity: 80000, current_level: 52000, location: 'المنطقة ب' },
                { name: 'خزان الكيروسين', fuel_type: 'kerosene', capacity: 30000, current_level: 18000, location: 'المنطقة أ' },
                { name: 'خزان الغاز', fuel_type: 'gas', capacity: 25000, current_level: 15000, location: 'المنطقة ج' },
                { name: 'خزان البنزين الاحتياطي', fuel_type: 'benzene', capacity: 40000, current_level: 28000, location: 'المنطقة ب' },
            ];

            const tankIds = [];
            for (const t of tanks) {
                const id = uuidv4();
                tankIds.push({ id, ...t });
                await client.query(
                    `INSERT INTO tanks (id, tenant_id, name, location, fuel_type, capacity, current_level, min_level, status, created_at)
                     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'active',NOW())
                     ON CONFLICT DO NOTHING`,
                    [id, tenantId, t.name, t.location, t.fuel_type, t.capacity, t.current_level, t.capacity * 0.1]
                );
                results.tanks++;
            }

            // -------- إنشاء معاملات تجريبية لـ 30 يوم --------
            const suppliers = ['شركة النفط الوطنية', 'مصفاة البصرة', 'الشركة العامة للمنتجات النفطية', 'شركة الجنوب للنفط'];
            const drivers = ['أحمد محمد', 'حسين علي', 'كريم جاسم', 'محمد عباس'];
            const trucks = ['ب-12345', 'ن-67890', 'ك-11223', 'م-44556'];

            for (let day = 30; day >= 0; day--) {
                const date = new Date();
                date.setDate(date.getDate() - day);
                date.setHours(8 + Math.floor(Math.random() * 10), Math.floor(Math.random() * 60));

                // 2-4 معاملات لكل يوم
                const txCount = 2 + Math.floor(Math.random() * 3);
                for (let t = 0; t < txCount; t++) {
                    const tank = tankIds[Math.floor(Math.random() * tankIds.length)];
                    const type = Math.random() > 0.35 ? 'incoming' : 'outgoing';
                    const quantity = Math.round((2000 + Math.random() * 15000) / 100) * 100;
                    const unitPrice = type === 'incoming' ? Math.round(500 + Math.random() * 300) : 0;
                    const id = uuidv4();

                    await client.query(
                        `INSERT INTO fuel_transactions (id, tenant_id, type, fuel_type, quantity, unit_price, total_price, supplier, tank_id, driver_name, truck_number, status, created_by, created_at)
                         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'approved',$12,$13)`,
                        [id, tenantId, type, tank.fuel_type,
                            quantity, unitPrice, quantity * unitPrice,
                            type === 'incoming' ? suppliers[Math.floor(Math.random() * suppliers.length)] : null,
                            tank.id,
                            drivers[Math.floor(Math.random() * drivers.length)],
                            trucks[Math.floor(Math.random() * trucks.length)],
                            userId, date]
                    );
                    results.transactions++;
                }
            }
        });

        await cacheDel('fuel:stats:*');
        await cacheDel(`tanks:${tenantId}*`);

        res.json({
            success: true,
            data: results,
            message: `تم إنشاء ${results.tanks} خزان و ${results.transactions} معاملة تجريبية`
        });
    } catch (error) { next(error); }
};
