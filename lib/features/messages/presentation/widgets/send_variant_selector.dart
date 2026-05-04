import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';
import 'package:orbit_app/features/messages/presentation/controllers/messages_controller.dart';

/// Compact selector that lets the user choose how the current message
/// should be sent (numbers, groups, specific group, with file, with
/// voice, with short link, attendance records, certifications, vip
/// card, excel upload).
///
/// The selector is purely presentational — it reads/writes the form
/// state through [messageFormProvider] and emits no events of its own.
/// The screen surrounding it is responsible for actually wiring the
/// extra inputs each variant requires.
class SendVariantSelector extends ConsumerWidget {
  const SendVariantSelector({
    super.key,
    this.variants = SendVariant.values,
  });

  /// Optionally restrict the list of variants offered (e.g. hide
  /// `with_voice` until the user has at least one voice recorded).
  final List<SendVariant> variants;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final form = ref.watch(messageFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.translate('sendVariantSelect'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: variants.map((variant) {
              final selected = variant == form.variant;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected,
                  label: Text(t.translate(variant.labelKey)),
                  selectedColor: AppColors.primarySurface,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  onSelected: (_) {
                    ref
                        .read(messageFormProvider.notifier)
                        .setVariant(variant);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
