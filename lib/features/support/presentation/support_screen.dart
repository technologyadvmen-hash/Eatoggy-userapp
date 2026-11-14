import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/create_ticket_request.dart';
import '../data/repositories/support_repository.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final SupportRepository _supportRepository = SupportRepositoryImpl();
  bool _isLoading = true;
  List<SupportTicket> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tickets = await _supportRepository.getMyTickets();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openCreateTicketModal({String? preselectedCategory}) {
    final subjectController = TextEditingController();
    final descController = TextEditingController();
    final orderIdController = TextEditingController();
    String category = preselectedCategory ?? 'Order Issues';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Raise Support Ticket',
                          style: GoogleFonts.outfit(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.secondaryText),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Issue Category',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      dropdownColor: AppColors.surface,
                      style: TextStyle(color: AppColors.primaryText, fontSize: 14.sp),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: [
                        'Order Issues',
                        'Payment & Refund',
                        'Subscription Inquiries',
                        'Delivery Partners',
                        'General Question',
                      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Order ID (Optional)',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: orderIdController,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: InputDecoration(
                        hintText: 'e.g. #ORD-98102',
                        hintStyle: const TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Subject',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subjectController,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Brief summary of the issue',
                        hintStyle: const TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Description',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Please describe your problem in detail...',
                        hintStyle: const TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: isSubmitting
                          ? null
                          : () async {
                              final subject = subjectController.text.trim();
                              final desc = descController.text.trim();
                              if (subject.isEmpty || desc.isEmpty) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter both subject and description'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isSubmitting = true);

                              final req = CreateTicketRequest(
                                category: category,
                                subject: subject,
                                description: desc,
                                orderId: orderIdController.text.trim().isNotEmpty
                                    ? orderIdController.text.trim()
                                    : null,
                              );

                              final nav = Navigator.of(sheetCtx);
                              final messenger = ScaffoldMessenger.of(context);
                              final router = GoRouter.of(context);

                              final newTicket = await _supportRepository.createTicket(req);
                              if (!mounted) return;

                              nav.pop();

                              setState(() {
                                _tickets.insert(0, newTicket);
                              });

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Ticket ${newTicket.id} created successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );

                              router.push('/ticket-detail', extra: newTicket);
                            },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Submit Ticket',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                context.go('/profile');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.primaryText, size: 18),
            ),
          ),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _loadTickets,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Support Tickets & Order Assistance ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Support Tickets',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openCreateTicketModal(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add, color: AppColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Raise Ticket',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_tickets.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 32.sp),
                        const SizedBox(height: 10),
                        Text(
                          'No Active Support Tickets',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Have an issue with an order or payment? Tap "Raise Ticket" above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._tickets.map((ticket) => _buildTicketCard(ticket)),

                const SizedBox(height: 28),

                // ── FAQ Categories ───────────────────────────────────────────
                Text(
                  'FAQ Categories',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFAQCard(
                  title: 'Order Issues',
                  icon: Icons.shopping_bag_outlined,
                  onTap: () => _openCreateTicketModal(preselectedCategory: 'Order Issues'),
                ),
                _buildFAQCard(
                  title: 'Payment & Refund',
                  icon: Icons.payment_outlined,
                  onTap: () => _openCreateTicketModal(preselectedCategory: 'Payment & Refund'),
                ),
                _buildFAQCard(
                  title: 'Subscription Inquiries',
                  icon: Icons.calendar_month_outlined,
                  onTap: () => _openCreateTicketModal(preselectedCategory: 'Subscription Inquiries'),
                ),
                _buildFAQCard(
                  title: 'Delivery Partners',
                  icon: Icons.local_shipping_outlined,
                  onTap: () => _openCreateTicketModal(preselectedCategory: 'Delivery Partners'),
                ),
                _buildFAQCard(
                  title: 'Account Settings',
                  icon: Icons.person_outline,
                  onTap: () => _openCreateTicketModal(preselectedCategory: 'General Question'),
                ),
                const SizedBox(height: 28),

                // ── Contact Us Directly ───────────────────────────────────────
                Text(
                  'Contact Us Directly',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildContactCard(
                        title: 'Chat Support',
                        icon: Icons.chat_bubble_outline,
                        onTap: () => _openCreateTicketModal(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildContactCard(
                        title: 'Call Helpline',
                        icon: Icons.phone_outlined,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Calling Eatoggy Concierge Helpline...'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final isOpen = ticket.status.toLowerCase() == 'open';
    return GestureDetector(
      onTap: () => context.push('/ticket-detail', extra: ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ticket.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: isOpen ? AppColors.primary : AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ticket.displayId,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket.issue,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ticket.messages.length} messages • Tap to view conversation',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard({required String title, required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('FAQ topic: "$title" details coming soon!')),
            );
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.secondaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
