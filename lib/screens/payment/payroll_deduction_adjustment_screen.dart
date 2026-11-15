import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scaffold.dart';

enum _AdjustmentAction { increase, decrease, discontinue }

enum _PayrollView { overview, form, review, requests }

class PayrollDeductionAdjustmentScreen extends StatefulWidget {
  const PayrollDeductionAdjustmentScreen({super.key});

  @override
  State<PayrollDeductionAdjustmentScreen> createState() =>
      _PayrollDeductionAdjustmentScreenState();
}

class _PayrollDeductionAdjustmentScreenState
    extends State<PayrollDeductionAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deductionController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  _PayrollView _view = _PayrollView.overview;
  _AdjustmentAction _action = _AdjustmentAction.increase;
  DateTime? _effectiveMonth;
  bool _consentGiven = false;

  @override
  void dispose() {
    _deductionController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Payroll Deduction Adjustment',
      backRoute: '/home',
      child: ColoredBox(
        color: const Color(0xFFF4F7F4),
        child: switch (_view) {
          _PayrollView.overview => _buildOverview(context),
          _PayrollView.form => _buildForm(context),
          _PayrollView.review => _buildReview(context),
          _PayrollView.requests => _buildRequests(context),
        },
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _prototypeNotice(theme),
        const SizedBox(height: 20),
        Text(
          'Manage a salary deduction',
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF1D2B23),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Prepare a request to increase, decrease, or discontinue an eligible deduction.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF66766C),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        _OverviewAction(
          icon: Icons.edit_note_rounded,
          title: 'Start an adjustment request',
          subtitle: 'Review the request details before confirming',
          onTap: () => setState(() => _view = _PayrollView.form),
        ),
        const SizedBox(height: 12),
        _OverviewAction(
          icon: Icons.history_rounded,
          title: 'My requests',
          subtitle: 'View request status and review history',
          onTap: () => setState(() => _view = _PayrollView.requests),
        ),
        const SizedBox(height: 20),
        _InformationCard(
          icon: Icons.info_outline_rounded,
          title: 'How this workflow works',
          lines: const [
            'A request is not a payroll instruction or a completed deduction change.',
            'An approval alone does not mean payroll has processed the change.',
            'This preview does not connect to an authorized payroll channel.',
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Workflow status labels',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF26372D),
          ),
        ),
        const SizedBox(height: 10),
        const _StatusList(),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final needsAmount = _action != _AdjustmentAction.discontinue;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _prototypeNotice(theme),
          const SizedBox(height: 18),
          Text(
            'Request details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D2B23),
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel('Adjustment'),
          const SizedBox(height: 8),
          DropdownButtonFormField<_AdjustmentAction>(
            initialValue: _action,
            decoration: _inputDecoration('Choose an action'),
            items: const [
              DropdownMenuItem(
                value: _AdjustmentAction.increase,
                child: Text('Increase deduction'),
              ),
              DropdownMenuItem(
                value: _AdjustmentAction.decrease,
                child: Text('Decrease deduction'),
              ),
              DropdownMenuItem(
                value: _AdjustmentAction.discontinue,
                child: Text('Discontinue deduction'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _action = value);
            },
          ),
          const SizedBox(height: 16),
          _FieldLabel('Deduction type or code'),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('payroll-deduction-code'),
            controller: _deductionController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [LengthLimitingTextInputFormatter(40)],
            decoration: _inputDecoration(
              'Enter deduction name or code',
              helper:
                  'Eligibility and the deduction code cannot be verified in this preview.',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a deduction type or code'
                : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel('Current amount'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E7E2)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: Color(0xFF708077),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Unavailable — no verified payroll data connected',
                    style: TextStyle(color: Color(0xFF66766C), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (needsAmount) ...[
            const SizedBox(height: 16),
            _FieldLabel(
              _action == _AdjustmentAction.increase
                  ? 'Requested new amount'
                  : 'Requested reduced amount',
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('payroll-requested-amount'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: _inputDecoration('GH₵ 0.00'),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount greater than zero';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          _FieldLabel('Effective month'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _selectEffectiveMonth(context),
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(
              _effectiveMonth == null
                  ? 'Choose effective month'
                  : _monthLabel(_effectiveMonth!),
            ),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              foregroundColor: const Color(0xFF286B45),
              side: const BorderSide(color: Color(0xFFE0E7E2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (_effectiveMonth == null)
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 12),
              child: Text(
                'Choose the month when you want the change to take effect.',
                style: TextStyle(fontSize: 12, color: Color(0xFF708077)),
              ),
            ),
          const SizedBox(height: 16),
          _FieldLabel('Reason for request'),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('payroll-request-reason'),
            controller: _reasonController,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            decoration: _inputDecoration(
              'Explain why you are requesting this change',
            ),
            validator: (value) => value == null || value.trim().length < 5
                ? 'Please provide a reason'
                : null,
          ),
          const SizedBox(height: 12),
          _InformationCard(
            icon: Icons.attach_file_rounded,
            title: 'Supporting document',
            lines: const [
              'Document upload is not available in this preview. Do not attach or enter sensitive documents here.',
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE5EBE6)),
            ),
            clipBehavior: Clip.antiAlias,
            child: CheckboxListTile(
              value: _consentGiven,
              onChanged: (value) =>
                  setState(() => _consentGiven = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              title: const Text(
                'I confirm this is my request and consent to its review.',
                style: TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final formValid = _formKey.currentState?.validate() ?? false;
              if (!formValid || _effectiveMonth == null || !_consentGiven) {
                if (!_consentGiven || _effectiveMonth == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Choose an effective month and provide consent to continue.',
                      ),
                    ),
                  );
                }
                return;
              }
              setState(() => _view = _PayrollView.review);
            },
            style: _primaryButtonStyle,
            child: const Text('Review request'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _view = _PayrollView.overview),
            child: const Text('Cancel preview'),
          ),
        ],
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _prototypeNotice(theme),
        const SizedBox(height: 18),
        Text(
          'Review your request',
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF1D2B23),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Check the information below. Nothing will be submitted or saved.',
          style: TextStyle(color: Color(0xFF66766C)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5EBE6)),
          ),
          child: Column(
            children: [
              _ReviewRow(label: 'Action', value: _actionLabel(_action)),
              _ReviewRow(
                label: 'Deduction',
                value: _deductionController.text.trim(),
              ),
              if (_action != _AdjustmentAction.discontinue)
                _ReviewRow(
                  label: 'Requested amount',
                  value: 'GH₵ ${_amountController.text.trim()}',
                ),
              _ReviewRow(
                label: 'Current amount',
                value: 'Unavailable — not verified',
              ),
              _ReviewRow(
                label: 'Effective month',
                value: _monthLabel(_effectiveMonth!),
              ),
              _ReviewRow(
                label: 'Reason',
                value: _reasonController.text.trim(),
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _InformationCard(
          icon: Icons.warning_amber_rounded,
          title: 'Preview only',
          lines: [
            'Confirming this screen will not create a request, reference number, or payroll change.',
            'The production workflow needs verified employee authorization and a protected backend.',
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _showPreviewConfirmation,
          style: _primaryButtonStyle,
          child: const Text('Confirm preview'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => setState(() => _view = _PayrollView.form),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            foregroundColor: const Color(0xFF286B45),
            side: const BorderSide(color: Color(0xFF286B45)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Edit request'),
        ),
      ],
    );
  }

  Widget _buildRequests(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _prototypeNotice(theme),
        const SizedBox(height: 18),
        Text(
          'My requests',
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF1D2B23),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const _InformationCard(
          icon: Icons.inbox_outlined,
          title: 'No live requests available',
          lines: [
            'This preview does not load, save, or display employee request records.',
            'Request history and status updates require a protected backend connection.',
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => setState(() => _view = _PayrollView.overview),
          child: const Text('Back to payroll options'),
        ),
      ],
    );
  }

  Widget _prototypeNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DDAF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.visibility_outlined, color: Color(0xFF966A17)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview only — not an authorized payroll service',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF795410),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'No role-based access, employee records, document upload, or submission is connected.',
                  style: TextStyle(
                    color: Color(0xFF795410),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectEffectiveMonth(BuildContext context) async {
    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month + 1);
    final selected = await showDatePicker(
      context: context,
      initialDate: _effectiveMonth ?? firstMonth,
      firstDate: firstMonth,
      lastDate: DateTime(now.year + 5, 12),
      helpText: 'Choose an effective month',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (selected == null || !mounted) return;
    setState(() => _effectiveMonth = DateTime(selected.year, selected.month));
  }

  Future<void> _showPreviewConfirmation() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF286B45)),
        title: const Text('Preview complete'),
        content: const Text(
          'No request was created, saved, or sent. Connect an authorized payroll backend before using this workflow with employee data.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) setState(() => _view = _PayrollView.overview);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  static InputDecoration _inputDecoration(String hint, {String? helper}) {
    return InputDecoration(
      hintText: hint,
      helperText: helper,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E7E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E7E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF286B45), width: 1.5),
      ),
    );
  }

  static String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String _actionLabel(_AdjustmentAction action) => switch (action) {
    _AdjustmentAction.increase => 'Increase',
    _AdjustmentAction.decrease => 'Decrease',
    _AdjustmentAction.discontinue => 'Discontinue',
  };
}

const _primaryButtonStyle = ButtonStyle(
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 15)),
  backgroundColor: WidgetStatePropertyAll(Color(0xFF286B45)),
  foregroundColor: WidgetStatePropertyAll(Colors.white),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
  ),
);

class _OverviewAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OverviewAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EBE6)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF286B45)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF26372D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF708077),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF708077)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;

  const _InformationCard({
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBE6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF528265), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF26372D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: Color(0xFF66766C),
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusList extends StatelessWidget {
  const _StatusList();

  static const _statuses = [
    'Draft',
    'Submitted',
    'Under Review',
    'Returned for Correction',
    'Approved',
    'Rejected',
    'Sent to Payroll',
    'Processed',
    'Failed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statuses
          .map(
            (status) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5EBE6)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Color(0xFF53675A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF26372D),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _ReviewRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF0F3F1))),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF708077), fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF26372D),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
