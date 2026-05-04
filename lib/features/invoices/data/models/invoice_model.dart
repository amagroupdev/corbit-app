/// Re-exports the [InvoiceModel] from the legacy `settings/invoices`
/// feature so the new Wave 9 `lib/features/invoices/` module can import
/// it from its dedicated path without duplicating the model.
export 'package:orbit_app/features/settings/data/models/invoice_model.dart'
    show InvoiceModel, InvoiceItemModel;
