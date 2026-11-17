PERMISSION_CATALOG = [

    ("tenant.view", "tenant", "view", "View company information"),
    ("tenant.manage", "tenant", "manage", "Manage company settings"),


    ("branch.view", "branch", "view", "View branches"),
    ("branch.create", "branch", "create", "Create branches"),
    ("branch.update", "branch", "update", "Update branches"),
    ("branch.delete", "branch", "delete", "Delete branches"),
    ("branch.access_all", "branch", "access_all", "Access all company branches"),


    ("user.view", "user", "view", "View users"),
    ("user.create", "user", "create", "Create users"),
    ("user.update", "user", "update", "Update users"),
    ("user.delete", "user", "delete", "Delete users"),
    ("role.manage", "role", "manage", "Manage roles"),
    ("permission.manage", "permission", "manage", "Manage permissions"),


    ("customer.view", "customer", "view", "View customers"),
    ("customer.create", "customer", "create", "Register customers"),
    ("customer.update", "customer", "update", "Update customers"),
    ("customer.delete", "customer", "delete", "Delete customers"),


    ("vehicle.view", "vehicle", "view", "View vehicles"),
    ("vehicle.create", "vehicle", "create", "Register vehicles"),
    ("vehicle.update", "vehicle", "update", "Update vehicles"),
    ("vehicle.delete", "vehicle", "delete", "Delete vehicles"),


    ("booking.view", "booking", "view", "View bookings"),
    ("booking.create", "booking", "create", "Create bookings"),
    ("booking.update", "booking", "update", "Update bookings"),
    ("booking.approve", "booking", "approve", "Approve bookings"),
    ("booking.cancel", "booking", "cancel", "Cancel bookings"),

    ("contract.view", "contract", "view", "View contracts"),
    ("contract.create", "contract", "create", "Create contracts"),
    ("contract.update", "contract", "update", "Update contracts"),
    ("contract.approve", "contract", "approve", "Approve contracts"),


    ("invoice.view", "invoice", "view", "View invoices"),
    ("invoice.create", "invoice", "create", "Create invoices"),
    ("invoice.update", "invoice", "update", "Update invoices"),
    ("payment.view", "payment", "view", "View payments"),
    ("payment.create", "payment", "create", "Record payments"),
    ("payment.refund", "payment", "refund", "Process refunds"),
    ("deposit.manage", "deposit", "manage", "Manage deposits"),


    ("maintenance.view", "maintenance", "view", "View maintenance records"),
    ("maintenance.create", "maintenance", "create", "Create maintenance records"),
    ("maintenance.update", "maintenance", "update", "Update maintenance records"),


    ("trip.view", "trip", "view", "View trips"),
    ("trip.create", "trip", "create", "Create trips"),
    ("trip.update", "trip", "update", "Update trips"),
    ("trip.complete", "trip", "complete", "Complete assigned trips"),
    ("incident.report", "incident", "report", "Report incidents"),


    ("report.view", "report", "view", "View business reports"),
    ("report.export", "report", "export", "Export business reports"),

    ("rate.manage", "rate", "manage", "Manage rental rates"),
    ("tax.manage", "tax", "manage", "Manage tax settings"),
]