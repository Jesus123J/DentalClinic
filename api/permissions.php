<?php
/**
 * Matriz de permisos por rol de ProDentist.
 *
 * Regla general del sistema: NADA se elimina de la base de datos.
 * Las bajas son logicas (active = 0) y exigen un motivo; para el resto de
 * usuarios el registro desaparece, pero sigue almacenado y solo el rol
 * 'sistemas' puede verlo en la papelera y reactivarlo.
 */

const ROLE_PERMISSIONS = [
    // Ingeniero de sistemas: todo, incluida la papelera y la reactivacion.
    'sistemas' => ['*'],

    // Administrador: opera todo el negocio, pero no reactiva ni ve la papelera.
    'admin' => [
        'patients.view', 'patients.edit', 'patients.deactivate',
        'appointments.view', 'appointments.edit', 'appointments.deactivate',
        'clinical.view', 'clinical.edit', 'clinical.deactivate',
        'attachments.view', 'attachments.upload', 'attachments.deactivate',
        'sales.view', 'sales.create', 'sales.payment', 'sales.void',
        'finance.view', 'treatments.manage', 'expenses.manage',
        'users.manage', 'reports.view', 'audit.view',
    ],

    // Odontologo: lo clinico. No toca dinero ni da de baja nada.
    'odontologo' => [
        'patients.view', 'patients.edit',
        'appointments.view', 'appointments.edit',
        'clinical.view', 'clinical.edit',
        'attachments.view', 'attachments.upload',
        'reports.view',
    ],

    // Recepcion: agenda y cobra. No ve la historia clinica ni las finanzas.
    'recepcion' => [
        'patients.view', 'patients.edit',
        'appointments.view', 'appointments.edit',
        'sales.view', 'sales.create',
        'reports.view',
    ],
];

/** Etiquetas legibles de los permisos (para la app y la auditoria). */
const PERMISSION_LABELS = [
    'patients.deactivate' => 'dar de baja pacientes',
    'appointments.deactivate' => 'dar de baja citas',
    'clinical.view' => 'ver la historia clinica',
    'clinical.edit' => 'registrar en la historia clinica',
    'clinical.deactivate' => 'dar de baja registros clinicos',
    'sales.payment' => 'registrar pagos',
    'sales.void' => 'anular cobros',
    'finance.view' => 'ver finanzas',
    'treatments.manage' => 'administrar el catalogo de servicios',
    'expenses.manage' => 'administrar gastos',
    'users.manage' => 'administrar usuarios',
    'audit.view' => 'ver la auditoria',
    'trash.view' => 'ver la papelera',
    'trash.restore' => 'reactivar registros',
];

function roleCan(?string $role, string $permission): bool {
    if ($role === null) return false;
    $perms = ROLE_PERMISSIONS[$role] ?? [];
    return in_array('*', $perms, true) || in_array($permission, $perms, true);
}

/** Lista de permisos efectivos de un rol (para que la app oculte botones). */
function permissionsOf(?string $role): array {
    if ($role === null) return [];
    $perms = ROLE_PERMISSIONS[$role] ?? [];
    if (in_array('*', $perms, true)) {
        $all = [];
        foreach (ROLE_PERMISSIONS as $r => $list) {
            if ($r === 'sistemas') continue;
            $all = array_merge($all, $list);
        }
        $all = array_merge($all, ['trash.view', 'trash.restore']);
        return array_values(array_unique($all));
    }
    return $perms;
}
