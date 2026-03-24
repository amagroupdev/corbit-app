import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/balance/data/models/bank_model.dart';
import 'package:orbit_app/features/balance/presentation/controllers/balance_controller.dart';
import 'package:orbit_app/features/balance/presentation/widgets/payment_method_selector.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Screen for purchasing SMS balance.
///
/// Features:
/// - Amount input with live price calculation
/// - Payment method selection: Online (Noon), Bank Transfer, STC Pay, SADAD
/// - Bank Transfer: bank selection, depositor name, date, receipt upload
/// - STC Pay: phone number then OTP flow
/// - SADAD: phone + national ID
class BuyBalanceScreen extends ConsumerStatefulWidget {
  const BuyBalanceScreen({super.key});

  @override
  ConsumerState<BuyBalanceScreen> createState() => _BuyBalanceScreenState();
}

class _BuyBalanceScreenState extends ConsumerState<BuyBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  Timer? _calcDebounce;

  // Bank transfer fields
  final _depositorNameController = TextEditingController();
  final _transferDateController = TextEditingController();
  BankModel? _selectedBank;
  String? _receiptFilePath;
  String? _receiptFileName;

  // STC Pay fields
  final _stcPhoneController = TextEditingController();
  final _otpController = TextEditingController();

  // SADAD fields
  final _sadadPhoneController = TextEditingController();
  final _nationalIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(buyBalanceControllerProvider.notifier).loadInitialData();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _depositorNameController.dispose();
    _transferDateController.dispose();
    _stcPhoneController.dispose();
    _otpController.dispose();
    _sadadPhoneController.dispose();
    _nationalIdController.dispose();
    _calcDebounce?.cancel();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    _calcDebounce?.cancel();
    _calcDebounce = Timer(const Duration(milliseconds: 700), () {
      final count = int.tryParse(value);
      if (count != null && count > 0) {
        ref
            .read(buyBalanceControllerProvider.notifier)
            .calculatePurchase(count);
      }
    });
  }

  int get _amount => int.tryParse(_amountController.text) ?? 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _transferDateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _receiptFilePath = result.files.single.path;
        _receiptFileName = result.files.single.name;
      });
    }
  }

  Future<void> _handlePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_amount <= 0) return;

    final state = ref.read(buyBalanceControllerProvider);
    final notifier = ref.read(buyBalanceControllerProvider.notifier);

    switch (state.selectedPaymentMethod) {
      case 'online':
        final result = await notifier.purchaseOnline(_amount);
        if (result != null && mounted) {
          final url = result['data']?['payment_url'] ??
              result['payment_url'];
          if (url != null) {
            final paymentResult = await context.push<bool?>(
              '/payment-webview',
              extra: {
                'url': url.toString(),
                'title': AppLocalizations.of(context)!.translate('onlinePayment'),
              },
            );
            if (mounted) {
              if (paymentResult == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.translate('paymentSuccess')),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.pop();
              } else if (paymentResult == false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.translate('paymentFailed')),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
              // paymentResult == null means user closed manually – do nothing
            }
          }
        }
        break;

      case 'bank_transfer':
        if (_selectedBank == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('selectBankRequired')),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        final success = await notifier.purchaseBankTransfer(
          amount: _amount,
          bankId: _selectedBank!.id,
          depositorName: _depositorNameController.text.trim(),
          transferDate: _transferDateController.text.trim(),
          receiptFilePath: _receiptFilePath,
          receiptFileName: _receiptFileName,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('purchaseRequestSent')),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
        break;

      case 'stc_pay':
        final success = await notifier.purchaseStcPay(
          amount: _amount,
          phoneNumber: _stcPhoneController.text.trim(),
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('otpSentInfo')),
              backgroundColor: AppColors.info,
            ),
          );
        }
        break;

      case 'sadad':
        final success = await notifier.purchaseSadad(
          amount: _amount,
          phoneNumber: _sadadPhoneController.text.trim(),
          nationalId: _nationalIdController.text.trim(),
        );
        if (success && mounted) {
          final result = ref.read(buyBalanceControllerProvider).purchaseResult;
          final billRef = result?['data']?['bill_reference'] ??
              result?['bill_reference'] ??
              '';
          final expiresAt = result?['data']?['expires_at'] ??
              result?['expires_at'] ??
              '';
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                AppLocalizations.of(context)!.translate('sadadInvoiceCreated'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 48),
                  const SizedBox(height: 12),
                  if (billRef.toString().isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.translate('invoiceNumberLabel'),
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      billRef.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  if (expiresAt.toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${AppLocalizations.of(context)!.translate('validUntil')} ${expiresAt.toString().split('T').first}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.translate('payViaBankOrAtm'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppLocalizations.of(context)!.translate('done')),
                ),
              ],
            ),
          );
          if (mounted) context.pop();
        }
        break;
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    final success = await ref
        .read(buyBalanceControllerProvider.notifier)
        .verifyStcPayOtp(otp);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('purchaseSuccess')),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buyBalanceControllerProvider);
    final t = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('buyBalance'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount input (SAR)
              AppTextField(
                label: t.translate('amountSar'),
                hint: t.translate('enterAmountSar'),
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: _onAmountChanged,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t.translate('amountRequired');
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return t.translate('enterValidAmount');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price calculation card
              if (state.isCalculating)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (state.calculation != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBorder),
                  ),
                  child: Column(
                    children: [
                      _buildCalcRow(
                        t.translate('baseAmount'),
                        '${numberFormat.format(state.calculation!['base_amount'] ?? 0)} ${t.translate('sar')}',
                      ),
                      const SizedBox(height: 8),
                      _buildCalcRow(
                        t.translate('taxAmount'),
                        '${numberFormat.format(state.calculation!['vat_amount'] ?? 0)} ${t.translate('sar')}',
                      ),
                      const Divider(height: 20),
                      _buildCalcRow(
                        t.translate('totalAmount'),
                        '${numberFormat.format(state.calculation!['total_amount'] ?? 0)} ${t.translate('sar')}',
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      _buildCalcRow(
                        t.translate('smsCountLabel'),
                        '${NumberFormat('#,##0', 'ar').format(state.calculation!['total_sms_credit'] ?? 0)} ${t.translate('messageUnit')}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Payment method selector
              if (!state.awaitingOtp) ...[
                PaymentMethodSelector(
                  selectedMethod: state.selectedPaymentMethod,
                  onMethodSelected: (method) {
                    ref
                        .read(buyBalanceControllerProvider.notifier)
                        .setPaymentMethod(method);
                  },
                ),
                const SizedBox(height: 24),

                // Payment method specific fields
                _buildPaymentFields(state),
                const SizedBox(height: 24),

                // Error
                if (state.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.errorDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Purchase button
                AppButton.primary(
                  text: t.translate('confirmPurchase'),
                  onPressed: state.isPurchasing ? null : _handlePurchase,
                  isLoading: state.isPurchasing,
                  icon: Icons.shopping_cart_checkout,
                ),
              ],

              // OTP verification (STC Pay)
              if (state.awaitingOtp) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.infoBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sms_outlined, color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.translate('otpSentStcPay'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.infoDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: t.translate('otpCode'),
                  hint: t.translate('enterOtpCode'),
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 16),
                AppButton.primary(
                  text: t.translate('confirmOtp'),
                  onPressed: state.isPurchasing ? null : _handleVerifyOtp,
                  isLoading: state.isPurchasing,
                  icon: Icons.verified_outlined,
                ),
              ],

              // Price tiers info
              if (state.priceTiers.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  t.translate('priceTable'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                t.translate('quantity'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                t.translate('pricePerSms'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...state.priceTiers.map((tier) {
                        final qtyFormat = NumberFormat('#,##0', 'ar');
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.borderLight),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${qtyFormat.format(tier.fromAmount)} - ${qtyFormat.format(tier.toAmount)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${tier.pricePerSms.toStringAsFixed(3)} ${t.translate('sar')}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isBold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentFields(BuyBalanceState state) {
    switch (state.selectedPaymentMethod) {
      case 'bank_transfer':
        return _buildBankTransferFields(state);
      case 'stc_pay':
        return _buildStcPayFields();
      case 'sadad':
        return _buildSadadFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBankTransferFields(BuyBalanceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bank selection
        Text(
          AppLocalizations.of(context)!.translate('selectBank'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BankModel>(
              value: _selectedBank,
              isExpanded: true,
              hint: Text(
                AppLocalizations.of(context)!.translate('selectBank'),
                style: TextStyle(color: AppColors.inputHint),
              ),
              items: state.banks
                  .map(
                    (bank) => DropdownMenuItem<BankModel>(
                      value: bank,
                      child: Text(bank.bankName),
                    ),
                  )
                  .toList(),
              onChanged: (bank) => setState(() => _selectedBank = bank),
            ),
          ),
        ),

        // Show selected bank info
        if (_selectedBank != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBankInfoRow(
                    AppLocalizations.of(context)!.translate('accountName'), _selectedBank!.accountName),
                _buildBankInfoRow(
                    AppLocalizations.of(context)!.translate('accountNumber'), _selectedBank!.accountNumber),
                if (_selectedBank!.iban.isNotEmpty)
                  _buildBankInfoRow('IBAN', _selectedBank!.iban),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Depositor name
        AppTextField(
          label: AppLocalizations.of(context)!.translate('depositorName'),
          hint: AppLocalizations.of(context)!.translate('depositorNameHint'),
          controller: _depositorNameController,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (state.selectedPaymentMethod == 'bank_transfer' &&
                (value == null || value.trim().isEmpty)) {
              return AppLocalizations.of(context)!.translate('depositorNameRequired');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Transfer date
        AppTextField(
          label: AppLocalizations.of(context)!.translate('transferDateLabel'),
          hint: AppLocalizations.of(context)!.translate('selectDateLabel'),
          controller: _transferDateController,
          readOnly: true,
          onTap: _pickDate,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          validator: (value) {
            if (state.selectedPaymentMethod == 'bank_transfer' &&
                (value == null || value.trim().isEmpty)) {
              return AppLocalizations.of(context)!.translate('transferDateRequired');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Receipt upload
        Text(
          AppLocalizations.of(context)!.translate('receiptOptional'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickReceipt,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _receiptFileName != null
                    ? AppColors.primaryBorder
                    : AppColors.inputBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _receiptFileName != null
                      ? Icons.insert_drive_file_outlined
                      : Icons.upload_file_outlined,
                  color: _receiptFileName != null
                      ? AppColors.primary
                      : AppColors.textHint,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _receiptFileName ?? AppLocalizations.of(context)!.translate('tapToUploadReceipt'),
                    style: TextStyle(
                      fontSize: 14,
                      color: _receiptFileName != null
                          ? AppColors.textPrimary
                          : AppColors.inputHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStcPayFields() {
    return Column(
      children: [
        AppTextField(
          label: AppLocalizations.of(context)!.translate('phoneStcPay'),
          hint: '05xxxxxxxx',
          controller: _stcPhoneController,
          keyboardType: TextInputType.phone,
          validator: (value) {
            final state = ref.read(buyBalanceControllerProvider);
            if (state.selectedPaymentMethod == 'stc_pay' &&
                (value == null || value.trim().isEmpty)) {
              return AppLocalizations.of(context)!.translate('phoneRequired');
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSadadFields() {
    return Column(
      children: [
        AppTextField(
          label: AppLocalizations.of(context)!.translate('phone'),
          hint: '05xxxxxxxx',
          controller: _sadadPhoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: (value) {
            final state = ref.read(buyBalanceControllerProvider);
            if (state.selectedPaymentMethod == 'sadad' &&
                (value == null || value.trim().isEmpty)) {
              return AppLocalizations.of(context)!.translate('phoneRequired');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: AppLocalizations.of(context)!.translate('nationalId'),
          hint: AppLocalizations.of(context)!.translate('enterNationalId'),
          controller: _nationalIdController,
          keyboardType: TextInputType.number,
          maxLength: 10,
          validator: (value) {
            final state = ref.read(buyBalanceControllerProvider);
            if (state.selectedPaymentMethod == 'sadad' &&
                (value == null || value.trim().isEmpty)) {
              return AppLocalizations.of(context)!.translate('nationalIdRequired');
            }
            return null;
          },
        ),
      ],
    );
  }
}
