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
      final newLeft = (widget.pictureModel.left + details.focalPointDelta.dx)
          .clamp(0.0, widget.boundWidth - 50 * widget.pictureModel.scale);
      final newTop = (widget.pictureModel.top + details.focalPointDelta.dy)
          .clamp(0.0, widget.boundHeight - 50 * widget.pictureModel.scale);

      widget.pictureModel.left = newLeft;
      widget.pictureModel.top = newTop;
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastScale = widget.pictureModel.scale;
    _lastRotation = 0;
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
            ? Image.network(widget.pictureModel.stringUrl, height: 50, width: 50)
            : Image.asset(widget.pictureModel.stringUrl, height: 50, width: 50),
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
          padding: const EdgeInsets.all(2),
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
          padding: const EdgeInsets.all(2),
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
        onPanUpdate: (details) {
          setState(() {
            final newScale = (widget.pictureModel.scale + details.delta.dx * 0.01).clamp(0.5, 5.0);
            widget.pictureModel.scale = newScale;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(2),
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