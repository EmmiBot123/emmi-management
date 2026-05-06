import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../Model/Marketing/school_visit_model.dart';
import '../../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../../Resources/api_endpoints.dart';
import '../../../Resources/theme_constants.dart';

class PhotosPage extends StatefulWidget {
  final SchoolVisit visit;

  const PhotosPage({super.key, required this.visit});

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String _selectedCategory = "GENERAL";

  @override
  Widget build(BuildContext context) {
    final List<String> urls = widget.visit.schoolProfile.photoUrl;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Background Glow Blobs ──
          Positioned(top: -100, right: -100, child: _buildGlowBlob(AppColors.accent.withValues(alpha: 0.1), 300)),
          Positioned(bottom: -50, left: -50, child: _buildGlowBlob(Colors.blueAccent.withValues(alpha: 0.1), 250)),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.bg,
                elevation: 0,
                pinned: true,
                centerTitle: true,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  "SITE EVIDENCE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [Shadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 10)],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildCategorySelector(),
                    const SizedBox(height: 32),
                    if (urls.isEmpty && !_isUploading)
                      _buildEmptyState()
                    else
                      _buildPhotoGrid(urls),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
          
          // ── Upload Floating Action ──
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: _buildUploadButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ["GENERAL", "CLASSROOM", "SERVER", "HARDWARE"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (v) => setState(() => _selectedCategory = cat),
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text("No photos uploaded yet", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Evidence is required for mission sign-off", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<String> urls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: urls.length + (_isUploading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isUploading && index == 0) {
          return _buildUploadingPlaceholder();
        }
        
        final urlIdx = _isUploading ? index - 1 : index;
        final url = urls[urlIdx];
        final fullUrl = "${ApiEndpoints.baseUrl}$url";

        return GestureDetector(
          onTap: () => _viewFullScreen(urls, urlIdx),
          onLongPress: () => _confirmDelete(url),
          child: Hero(
            tag: fullUrl,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(image: NetworkImage(fullUrl), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _confirmDelete(url),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadingPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
            SizedBox(height: 12),
            Text("UPLOADING...", style: TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF6E6AFF)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : _pickAndUpload,
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text("ADD SITE EVIDENCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file == null) return;

    setState(() => _isUploading = true);

    final provider = context.read<SchoolVisitProvider>();
    final result = await provider.uploadVisitImage(
      visitId: widget.visit.id!,
      filePath: file.path,
      pickedFile: file,
    );

    if (mounted) {
      if (result != null) {
        setState(() {
          widget.visit.schoolProfile.photoUrl.add(result);
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo uploaded successfully")));
      } else {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload photo"), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _confirmDelete(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Delete Photo?", style: TextStyle(color: Colors.white)),
        content: const Text("This evidence will be permanently removed.", style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final fileName = url.split('/').last;
              final success = await context.read<SchoolVisitProvider>().deleteVisitImage(
                visitId: widget.visit.id!,
                fileName: fileName,
              );
              if (success && mounted) {
                setState(() => widget.visit.schoolProfile.photoUrl.remove(url));
              }
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _viewFullScreen(List<String> urls, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenGallery(images: urls, initialIndex: index),
      ),
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({super.key, required this.images, required this.initialIndex});

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController controller;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final url = "${ApiEndpoints.baseUrl}${widget.images[index]}";
              return Center(
                child: Hero(
                  tag: url,
                  child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
