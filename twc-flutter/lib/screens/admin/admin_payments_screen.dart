import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/media_service.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = Get.find<ApiService>();
  late TabController _tabController;

  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingPayments = true;
  bool _isLoadingCourses = true;
  String _paymentStatus = 'pending';
  String _paymentType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPayments();
    _loadCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoadingPayments = true);
    try {
      final params = <String, dynamic>{};
      if (_paymentStatus != 'all') params['status'] = _paymentStatus;
      if (_paymentType != 'all') params['type_filter'] = _paymentType;
      final response = await _api.get('/admin/payments', params: params);
      if (response['success']) {
        setState(() {
          _payments = List<Map<String, dynamic>>.from(
            response['data']['payments'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error loading payments: $e');
    }
    setState(() => _isLoadingPayments = false);
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final response = await _api.get('/admin/courses');
      if (response['success']) {
        setState(() {
          _courses = List<Map<String, dynamic>>.from(
            response['data']['courses'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error loading courses: $e');
    }
    setState(() => _isLoadingCourses = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Paiements & Formations'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPayments();
              _loadCourses();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppConstants.primaryColor,
          tabs: const [
            Tab(text: 'Paiements', icon: Icon(Icons.payment)),
            Tab(text: 'Formations', icon: Icon(Icons.book)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPaymentsTab(),
          _buildCoursesTab(),
        ],
      ),
    );
  }

  // ==================== PAIEMENTS TAB ====================

  Widget _buildPaymentsTab() {
    if (_isLoadingPayments) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              // Status filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusChip('En attente', 'pending'),
                    _statusChip('Approuvés', 'completed'),
                    _statusChip('Rejetés', 'failed'),
                    _statusChip('Tous', 'all'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Type filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _typeChip('Tous', 'all'),
                    _typeChip('Manuel', 'manual'),
                    _typeChip('Chariow', 'chariow'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Payment list
        Expanded(
          child: _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun paiement trouvé',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) => _buildPaymentCard(_payments[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _statusChip(String label, String value) {
    final isSelected = _paymentStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
        selected: isSelected,
        selectedColor: AppConstants.primaryColor,
        onSelected: (_) {
          setState(() => _paymentStatus = value);
          _loadPayments();
        },
      ),
    );
  }

  Widget _typeChip(String label, String value) {
    final isSelected = _paymentType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
        selected: isSelected,
        selectedColor: Colors.blue,
        onSelected: (_) {
          setState(() => _paymentType = value);
          _loadPayments();
        },
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final user = payment['user'] ?? {};
    final meta = payment['metadata'] ?? {};
    final amount = double.tryParse('${payment['amount'] ?? 0}') ?? 0;
    final isPending = payment['status'] == 'pending';
    final statusColor = isPending
        ? Colors.orange
        : payment['status'] == 'completed'
            ? Colors.green
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(
                    isPending ? Icons.hourglass_top : Icons.receipt,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _buildPaymentName(user, meta),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    payment['status_label'] ?? payment['status'],
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            _buildDetailRow('Montant', '${NumberFormat('#,##0', 'fr_FR').format(amount)} CDF'),
            _buildDetailRow('Opérateur', meta['provider'] ?? payment['payment_method'] ?? ''),
            _buildDetailRow('ID Chariow', meta['chariow_reference'] ?? '—'),
            _buildDetailRow('Date', _formatDate(payment['created_at'])),

            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approvePayment(payment['id']),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectPayment(payment['id']),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildPaymentName(Map<String, dynamic> user, Map<String, dynamic> meta) {
    final ln = meta['last_name'] ?? '';
    final fn = meta['first_name'] ?? '';
    if (ln.isNotEmpty || fn.isNotEmpty) {
      return '$fn $ln'.trim();
    }
    return user['name'] ?? 'Inconnu';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePayment(int id) async {
    try {
      final response = await _api.post('/admin/payments/$id/approve');
      if (response['success']) {
        Get.snackbar('Succès', 'Paiement approuvé et crédité.');
        _loadPayments();
      } else {
        Get.snackbar('Erreur', response['error'] ?? 'Échec.');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  Future<void> _rejectPayment(int id) async {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le paiement'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Raison (optionnel)',
            hintText: 'Ex: Montant non reçu',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final response = await _api.post('/admin/payments/$id/reject', data: {
                  if (reasonController.text.isNotEmpty)
                    'reason': reasonController.text,
                });
                if (response['success']) {
                  Get.snackbar('Succès', 'Paiement rejeté.');
                  _loadPayments();
                } else {
                  Get.snackbar('Erreur', response['error'] ?? 'Échec.');
                }
              } catch (e) {
                Get.snackbar('Erreur', 'Erreur réseau.');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== FORMATIONS TAB ====================

  Widget _buildCoursesTab() {
    if (_isLoadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Add course button
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddCourseDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une formation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),

        // Course list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCourses,
            child: _courses.isEmpty
                ? Center(
                    child: Text(
                      'Aucune formation',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) => _buildCourseCard(_courses[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final coverImage = course['cover_image'];
    final statusColor = course['status'] == 'approved'
        ? Colors.green
        : course['status'] == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          if (coverImage != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: MediaService.resolveUrl(coverImage) ?? coverImage,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 140,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 140,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(Icons.book, size: 40, color: AppConstants.primaryColor),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        course['status'] ?? 'pending',
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Price
                Text(
                  course['is_free'] == true
                      ? 'Gratuit'
                      : '${NumberFormat('#,##0', 'fr_FR').format(double.tryParse('${course['price'] ?? 0}') ?? 0)} CDF',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Actions
                Row(
                  children: [
                    // Image button
                    _buildSmallButton(
                      Icons.image,
                      'Image',
                      () => _pickCourseImage(course['id']),
                    ),
                    const SizedBox(width: 6),

                    if (course['status'] != 'approved')
                      _buildSmallButton(
                        Icons.check_circle,
                        'Approuver',
                        () => _approveCourse(course['id']),
                        color: Colors.green,
                      ),

                    if (course['status'] != 'rejected')
                      _buildSmallButton(
                        Icons.cancel,
                        'Rejeter',
                        () => _rejectCourse(course['id']),
                        color: Colors.red,
                      ),

                    const Spacer(),

                    _buildSmallButton(
                      Icons.delete,
                      '',
                      () => _deleteCourse(course['id']),
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color ?? Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickCourseImage(int courseId) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
      if (picked == null) return;

      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      final file = File(picked.path);
      final response = await _api.uploadFile('/admin/courses/$courseId', file, 'cover_image', method: 'PUT');

      Get.back();

      if (response != null && response['success'] == true) {
        Get.snackbar('Succès', 'Image de couverture mise à jour.');
        _loadCourses();
      } else {
        Get.snackbar('Erreur', 'Échec de l\'upload.');
      }
    } catch (e) {
      Get.back();
      Get.snackbar('Erreur', 'Erreur: $e');
    }
  }

  Future<void> _approveCourse(int id) async {
    try {
      final response = await _api.post('/admin/courses/$id/approve');
      if (response['success']) {
        Get.snackbar('Succès', 'Formation approuvée.');
        _loadCourses();
      } else {
        Get.snackbar('Erreur', response['error'] ?? 'Échec.');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  Future<void> _rejectCourse(int id) async {
    try {
      final response = await _api.post('/admin/courses/$id/reject');
      if (response['success']) {
        Get.snackbar('Succès', 'Formation rejetée.');
        _loadCourses();
      } else {
        Get.snackbar('Erreur', response['error'] ?? 'Échec.');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  Future<void> _deleteCourse(int id) async {
    Get.defaultDialog(
      title: 'Supprimer ?',
      middleText: 'Supprimer cette formation définitivement ?',
      textConfirm: 'Supprimer',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        try {
          final response = await _api.delete('/admin/courses/$id');
          if (response['success']) {
            Get.snackbar('Succès', 'Formation supprimée.');
            _loadCourses();
          }
        } catch (e) {
          Get.snackbar('Erreur', 'Erreur réseau.');
        }
      },
    );
  }

  void _showAddCourseDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    String level = 'beginner';
    String category = '';
    File? pickedImage;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle formation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titre *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix (CDF)', hintText: '0 = Gratuit'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: level,
                  decoration: const InputDecoration(labelText: 'Niveau'),
                  items: const [
                    DropdownMenuItem(value: 'beginner', child: Text('Débutant')),
                    DropdownMenuItem(value: 'intermediate', child: Text('Intermédiaire')),
                    DropdownMenuItem(value: 'advanced', child: Text('Avancé')),
                    DropdownMenuItem(value: 'expert', child: Text('Expert')),
                  ],
                  onChanged: (v) => setDialogState(() => level = v ?? level),
                ),
                const SizedBox(height: 12),
                // Image picker
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
                    if (picked != null) {
                      setDialogState(() => pickedImage = File(picked.path));
                    }
                  },
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(pickedImage!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey[500]),
                              const SizedBox(height: 4),
                              Text('Image de couverture', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  Get.snackbar('Erreur', 'Titre requis.');
                  return;
                }
                Get.back();

                try {
                  // Create course first
                  final response = await _api.post('/admin/courses', data: {
                    'title': titleController.text,
                    'description': descController.text,
                    'price': double.tryParse(priceController.text) ?? 0,
                    'level': level,
                    'category': category.isNotEmpty ? category : null,
                  });

                  if (response['success'] && response['data']?['course'] != null) {
                    final courseId = response['data']['course']['id'];

                    // Upload image if picked
                    if (pickedImage != null) {
                      await _api.uploadFile('/admin/courses/$courseId', pickedImage!, 'cover_image', method: 'PUT');
                    }

                    Get.snackbar('Succès', 'Formation créée.');
                    _loadCourses();
                  } else {
                    Get.snackbar('Erreur', response['error'] ?? 'Échec.');
                  }
                } catch (e) {
                  Get.snackbar('Erreur', 'Erreur réseau.');
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return dateStr.toString();
    }
  }
}
