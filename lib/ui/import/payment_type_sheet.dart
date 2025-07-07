import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/payment_type.dart';
import '../../providers/pdf_import_providers.dart';
import 'package:intl/intl.dart';
import '../../model/statement_info.dart';

class PaymentTypeSheet extends ConsumerStatefulWidget {
  const PaymentTypeSheet({super.key});

  @override
  ConsumerState<PaymentTypeSheet> createState() => _PaymentTypeSheetState();
}

class _PaymentTypeSheetState extends ConsumerState<PaymentTypeSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedType =
        ref.watch(PdfImportProviders.selectedPaymentTypeProvider);
    final overwrite = ref.watch(PdfImportProviders.overwriteOptionProvider);
    final allStatements =
        ref.watch(PdfImportProviders.allStatementInfosProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titolo
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Carica dati da Estratto Conto',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          const SizedBox(height: 12), // Stacco visivo maggiore dopo il titolo

          // Selezione tipo di pagamento
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<PaymentType>(
                  segments: const [
                    ButtonSegment<PaymentType>(
                      value: PaymentType.bancomat,
                      label: Text('Bancomat'),
                      icon: Icon(Icons.credit_card),
                    ),
                    ButtonSegment<PaymentType>(
                      value: PaymentType.creditCard,
                      label: Text('Carta di Credito'),
                      icon: Icon(Icons.credit_card_outlined),
                    ),
                  ],
                  selected:
                      selectedType == null ? <PaymentType>{} : {selectedType},
                  onSelectionChanged: (Set<PaymentType> newSelection) {
                    ref
                            .read(PdfImportProviders
                                .selectedPaymentTypeProvider.notifier)
                            .state =
                        newSelection.isNotEmpty ? newSelection.first : null;
                  },
                  emptySelectionAllowed: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Opzione sovrascrittura
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: overwrite,
                      onChanged: (value) {
                        print('DEBUG: Checkbox overwrite changed to $value');
                        ref
                            .read(PdfImportProviders
                                .overwriteOptionProvider.notifier)
                            .state = value ?? false;
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Sovrascrivi movimenti esistenti di questa tipologia nell\'intervallo dell\'estratto conto',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider e sezione ultimi estratti SOLO se ci sono estratti
          allStatements.when(
            data: (statements) {
              // Prendi solo il più recente per ogni tipologia
              final byType = <String, StatementInfo>{};
              for (final s in statements) {
                print(
                    'DEBUG: StatementInfo paymentType: ${s.paymentType} (id: ${s.id}, accountHolder: ${s.accountHolder}, month: ${s.month})');
                if (s == null) continue;
                if (!byType.containsKey(s.paymentType) ||
                    (s.processedDate != null &&
                        (byType[s.paymentType]?.processedDate == null ||
                            s.processedDate.isAfter(
                                byType[s.paymentType]!.processedDate)))) {
                  byType[s.paymentType] = s;
                }
              }
              final rows = byType.values.where((info) => info != null).toList();
              rows.sort((a, b) => a.paymentType.compareTo(b.paymentType));
              if (rows.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Ultimi estratti importati',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        ...rows.map((info) {
                          final type = PaymentType.values.firstWhere(
                            (t) => t.name == info.paymentType,
                            orElse: () => PaymentType.bancomat,
                          );
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            leading: Icon(type.icon,
                                color: colorScheme.primary, size: 20),
                            title: Text(
                              type == PaymentType.bancomat
                                  ? 'Bancomat'
                                  : type == PaymentType.creditCard
                                      ? 'Carta di Credito'
                                      : type == PaymentType.bankTransfer
                                          ? 'Bonifico'
                                          : 'Contanti',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            subtitle: Text(
                              info.accountHolder,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Text(
                              info.month,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) {
              print('[PAYMENT_TYPE_SHEET][ERROR] $error\n$stack');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Errore imprevisto durante il caricamento.',
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Pulsante Avanti
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedType == null
                    ? null
                    : () {
                        Navigator.pop(context, true);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Avanti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Spazio per il safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _paymentTypeLabel(String type) {
    switch (type) {
      case 'bancomat':
        return 'Bancomat';
      case 'creditCard':
        return 'Carta di Credito';
      case 'bankTransfer':
        return 'Bonifico';
      case 'cash':
        return 'Contanti';
      default:
        return type;
    }
  }
}
