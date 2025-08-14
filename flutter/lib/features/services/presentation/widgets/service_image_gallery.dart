import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:developer' as developer;
import '../../../../core/services/image_service.dart';
import '../../../../core/theme/app_theme.dart';

class ServiceImageGallery extends StatefulWidget {
  final String serviceId;
  final bool isEditable;
  final Function(List<String>)? onImagesChanged;
  final List<String>? initialImageUrls; // Firebaseから取得済みの画像URL
  
  const ServiceImageGallery({
    super.key,
    required this.serviceId,
    this.isEditable = true,
    this.onImagesChanged,
    this.initialImageUrls,
  });
  
  @override
  State<ServiceImageGallery> createState() => _ServiceImageGalleryState();
}

class _ServiceImageGalleryState extends State<ServiceImageGallery> {
  List<ServiceImage> _images = [];
  bool _isLoading = false;
  int _selectedImageIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadImages();
  }
  
  Future<void> _loadImages() async {
    print('Loading images for service: ${widget.serviceId}');
    
    // 初期画像URLが提供されている場合は、それを使用
    if (widget.initialImageUrls != null && widget.initialImageUrls!.isNotEmpty) {
      print('Using initial image URLs from Firebase: ${widget.initialImageUrls}');
      // Firebase URLから仮のServiceImageオブジェクトを作成
      setState(() {
        _images = widget.initialImageUrls!.map((url) => ServiceImage(
          id: url.split('/').last, // URLから仮のIDを生成
          serviceId: widget.serviceId,
          localData: '', // LocalDataは空
          firebaseUrl: url,
          fileName: 'image',
          uploadedAt: DateTime.now().toIso8601String(),
          size: 0,
        )).toList();
      });
      
      // コールバックで通知
      if (widget.onImagesChanged != null) {
        widget.onImagesChanged!(widget.initialImageUrls!);
      }
      return;
    }
    
    // 初期画像URLがない場合のみ、ImageServiceから読み込み
    final imageService = Provider.of<ImageService>(context, listen: false);
    final images = await imageService.getServiceImages(widget.serviceId);
    print('Loaded ${images.length} images from ImageService');
    
    setState(() {
      _images = images;
    });
    
    // 画像URLのリストをコールバックで通知（Firebase URLのみを使用）
    if (widget.onImagesChanged != null) {
      final urls = images
          .where((img) => img.firebaseUrl.isNotEmpty)
          .map((img) => img.firebaseUrl)
          .toList();
      print('Notifying parent with Firebase URLs: $urls');
      print('Total images: ${images.length}, Images with Firebase URLs: ${urls.length}');
      widget.onImagesChanged!(urls);
    }
  }
  
  Future<void> _pickAndUploadImages() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('画像選択を開始します...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像が選択されませんでした'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      if (result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ファイルが空です'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.files.length}枚の画像を選択しました'),
          backgroundColor: Colors.blue,
        ),
      );
      
      setState(() {
        _isLoading = true;
      });
      
      final imageService = Provider.of<ImageService>(context, listen: false);
      int uploadedCount = 0;
      
      for (final file in result.files) {
        if (file.bytes != null) {
          try {
            final uploadedImage = await imageService.uploadImage(
              serviceId: widget.serviceId,
              imageData: file.bytes!,
              fileName: file.name,
            );
            uploadedCount++;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${file.name}をアップロードしました ($uploadedCount/${result.files.length})'),
                duration: const Duration(seconds: 1),
              ),
            );
          } catch (uploadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${file.name}のアップロードに失敗: $uploadError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
      
      await _loadImages();
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted && uploadedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$uploadedCount枚の画像をアップロードしました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // アップロード完了後、Firebase URLを親に通知
        if (widget.onImagesChanged != null && _images.isNotEmpty) {
          final urls = _images
              .where((img) => img.firebaseUrl.isNotEmpty)
              .map((img) => img.firebaseUrl)
              .toList();
          print('After upload - Notifying parent with Firebase URLs: $urls');
          widget.onImagesChanged!(urls);
        }
      }
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });
      
      // エラーの詳細をログに出力
      developer.log('FilePicker error', name: 'ServiceImageGallery', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像選択エラー: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  Future<void> _deleteImage(ServiceImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像の削除'),
        content: const Text('この画像を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final imageService = Provider.of<ImageService>(context, listen: false);
      await imageService.deleteImage(widget.serviceId, image.id);
      await _loadImages();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像を削除しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showImageViewer(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => ImageViewerDialog(
        images: _images,
        initialIndex: initialIndex,
        onDelete: widget.isEditable ? _deleteImage : null,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ImageService>(
      builder: (context, imageService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '商品画像',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.isEditable)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickAndUploadImages,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add_photo_alternate, size: 18),
                    label: Text(_isLoading ? 'アップロード中...' : '画像を追加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 画像グリッド
            if (_images.isEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '画像がありません',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (widget.isEditable) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _pickAndUploadImages,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('画像を追加'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: _images.length == 1 ? 300 : 400,
                child: _images.length == 1
                    ? _buildSingleImage()
                    : _buildImageGrid(),
              ),
            
            // 画像情報
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${_images.length}枚の画像',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
  
  Widget _buildSingleImage() {
    final image = _images.first;
    return InkWell(
      onTap: () => _showImageViewer(0),
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImage(image),
            ),
          ),
          if (widget.isEditable)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  onPressed: () => _deleteImage(image),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildImageGrid() {
    return Column(
      children: [
        // メイン画像
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: () => _showImageViewer(_selectedImageIndex),
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImage(_images[_selectedImageIndex]),
                  ),
                ),
                // ズームアイコン
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                if (widget.isEditable)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                        onPressed: () => _deleteImage(_images[_selectedImageIndex]),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // サムネイル
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedImageIndex;
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 4,
                  right: index == _images.length - 1 ? 0 : 4,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: _buildImage(_images[index], isThumb: true),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildImage(ServiceImage image, {bool isThumb = false}) {
    // Firebase URLがある場合はそれを使用
    if (image.firebaseUrl.isNotEmpty) {
      return Image.network(
        image.firebaseUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Firebase URLが失敗した場合はローカルデータを試す
          if (image.localData.isNotEmpty) {
            return Image.memory(
              image.imageBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(Icons.broken_image, size: isThumb ? 24 : 48),
                  ),
                );
              },
            );
          }
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(Icons.broken_image, size: isThumb ? 24 : 48),
            ),
          );
        },
      );
    }
    
    // Firebase URLがない場合はローカルデータを使用
    if (image.localData.isNotEmpty) {
      return Image.memory(
        image.imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(Icons.broken_image, size: isThumb ? 24 : 48),
            ),
          );
        },
      );
    }
    
    // どちらもない場合はプレースホルダー
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.broken_image, size: isThumb ? 24 : 48),
      ),
    );
  }
}

// 画像ビューアダイアログ
class ImageViewerDialog extends StatefulWidget {
  final List<ServiceImage> images;
  final int initialIndex;
  final Function(ServiceImage)? onDelete;
  
  const ImageViewerDialog({
    super.key,
    required this.images,
    required this.initialIndex,
    this.onDelete,
  });
  
  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Stack(
          children: [
            // 画像ビューア
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: _buildViewerImage(widget.images[index]),
                    ),
                  );
                },
              ),
            ),
            // ヘッダー
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        if (widget.onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () {
                              widget.onDelete!(widget.images[_currentIndex]);
                              Navigator.pop(context);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ナビゲーションボタン
            if (widget.images.length > 1) ...[
              // 前へボタン
              if (_currentIndex > 0)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
              // 次へボタン
              if (_currentIndex < widget.images.length - 1)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
            ],
            // 画像情報
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.images[_currentIndex].fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.images[_currentIndex].formattedSize,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildViewerImage(ServiceImage image) {
    // Firebase URLがある場合はそれを使用
    if (image.firebaseUrl.isNotEmpty) {
      return Image.network(
        image.firebaseUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white54),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Firebase URLが失敗した場合はローカルデータを試す
          if (image.localData.isNotEmpty) {
            return Image.memory(
              image.imageBytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white54,
                    ),
                  ),
                );
              },
            );
          }
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: Colors.white54,
              ),
            ),
          );
        },
      );
    }
    
    // Firebase URLがない場合はローカルデータを使用
    if (image.localData.isNotEmpty) {
      return Image.memory(
        image.imageBytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: Colors.white54,
              ),
            ),
          );
        },
      );
    }
    
    // どちらもない場合はプレースホルダー
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 64,
          color: Colors.white54,
        ),
      ),
    );
  }
}