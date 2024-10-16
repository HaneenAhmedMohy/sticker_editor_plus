import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:sticker_editor_plus/src/model/picture_model.dart';

class StickerEditingBox extends StatefulWidget {
  final double boundWidth;
  final double boundHeight;
  final PictureModel pictureModel;
  final Function()? onCancel;
  final Function()? onTap;
  final bool viewOnly;
  final Icon? resizeIcon;
  final Icon? rotateIcon;
  final Icon? closeIcon;

  const StickerEditingBox({
    Key? key,
    required this.boundWidth,
    required this.boundHeight,
    required this.pictureModel,
    this.viewOnly = false,
    this.resizeIcon,
    this.rotateIcon,
    this.closeIcon,
    this.onTap,
    this.onCancel,
  }) : super(key: key);

  @override
  _StickerEditingBoxState createState() => _StickerEditingBoxState();
}

class _StickerEditingBoxState extends State<StickerEditingBox> {
  late double _lastScale;
  late double _lastRotation;
  final double _baseSize = 50.0; // Base size of the sticker

  @override
  void initState() {
    super.initState();
    _lastScale = widget.pictureModel.scale;
    _lastRotation = widget.pictureModel.angle;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (widget.viewOnly) return;

    setState(() {
      // Handle rotation
      if (details.rotation != 0) {
        widget.pictureModel.angle += details.rotation - _lastRotation;
        _lastRotation = details.rotation;
      }

      // Handle scaling
      if (details.scale != 1) {
        final newScale = (_lastScale * details.scale).clamp(0.5, 5.0);
        widget.pictureModel.scale = newScale;
      }

      // Handle movement
      final scaledSize = _baseSize * widget.pictureModel.scale;
      final newLeft = (widget.pictureModel.left + details.focalPointDelta.dx)
          .clamp(0.0, widget.boundWidth - scaledSize);
      final newTop = (widget.pictureModel.top + details.focalPointDelta.dy)
          .clamp(0.0, widget.boundHeight - scaledSize);

      widget.pictureModel.left = newLeft;
      widget.pictureModel.top = newTop;
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastScale = widget.pictureModel.scale;
    _lastRotation = 0;
  }

  void _handleResize(Offset delta) {
    setState(() {
      final newScale = (widget.pictureModel.scale + delta.dx * 0.01).clamp(0.5, 5.0);
      final scaleDiff = newScale - widget.pictureModel.scale;
      
      // Adjust position to keep the top-left corner fixed
      widget.pictureModel.left -= (_baseSize * scaleDiff) / 2;
      widget.pictureModel.top -= (_baseSize * scaleDiff) / 2;
      
      // Ensure the sticker stays within bounds
      widget.pictureModel.left = widget.pictureModel.left.clamp(0.0, widget.boundWidth - _baseSize * newScale);
      widget.pictureModel.top = widget.pictureModel.top.clamp(0.0, widget.boundHeight - _baseSize * newScale);
      
      widget.pictureModel.scale = newScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.pictureModel.top,
      left: widget.pictureModel.left,
      child: GestureDetector(
        onScaleStart: (_) => _lastRotation = 0,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            setState(() => widget.pictureModel.isSelected = !widget.pictureModel.isSelected);
          }
        },
        child: Transform.scale(
          scale: widget.pictureModel.scale,
          child: Transform.rotate(
            angle: widget.pictureModel.angle,
            child: Stack(
              children: [
                _buildStickerImage(),
                if (widget.pictureModel.isSelected) ...[
                  _buildRotateHandle(),
                  _buildCloseButton(),
                  _buildResizeHandle(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickerImage() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: DottedBorder(
        color: widget.pictureModel.isSelected ? Colors.grey[600]! : Colors.transparent,
        padding: const EdgeInsets.all(4),
        child: widget.pictureModel.stringUrl.startsWith('http')
            ? Image.network(widget.pictureModel.stringUrl, height: _baseSize, width: _baseSize)
            : Image.asset(widget.pictureModel.stringUrl, height: _baseSize, width: _baseSize),
      ),
    );
  }

  Widget _buildRotateHandle() {
    return Positioned(
      bottom: 0,
      left: 0,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() => widget.pictureModel.angle += details.delta.dx * 0.01);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: widget.rotateIcon ?? const Icon(Icons.sync_alt, color: Colors.black, size: 12),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 3,
      right: 3,
      child: GestureDetector(
        onTap: () {
          if (widget.onCancel != null) {
            widget.onCancel!();
          }
          setState(() => widget.pictureModel.isSelected = false);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: widget.closeIcon ?? const Icon(Icons.close, color: Colors.black, size: 12),
        ),
      ),
    );
  }

  Widget _buildResizeHandle() {
    return Positioned(
      bottom: 3,
      right: 3,
      child: GestureDetector(
        onPanUpdate: (details) => _handleResize(details.delta),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: widget.resizeIcon ?? const Icon(Icons.crop, color: Colors.black, size: 12),
        ),
      ),
    );
  }
}