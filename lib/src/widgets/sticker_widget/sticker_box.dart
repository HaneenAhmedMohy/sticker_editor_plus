import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:sticker_editor_plus/src/model/picture_model.dart';
import 'dart:math' as math;

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
  final double _controlSize = 24.0; // Size of control buttons

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
      final sensitivity = 0.01; // Adjust this value to change resize sensitivity
      final newScale = (widget.pictureModel.scale + delta.dx * sensitivity).clamp(0.5, 5.0);
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
    final scaledSize = _baseSize * widget.pictureModel.scale;

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
        child: Transform.rotate(
          angle: widget.pictureModel.angle,
          child: SizedBox(
            width: scaledSize,
            height: scaledSize,
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
            ? Image.network(widget.pictureModel.stringUrl, fit: BoxFit.contain)
            : Image.asset(widget.pictureModel.stringUrl, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildControlButton(Widget child, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _controlSize,
        height: _controlSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildRotateHandle() {
    return Positioned(
      bottom: -_controlSize / 2,
      left: -_controlSize / 2,
      child: GestureDetector(
        onPanUpdate: (details) {
          final center = Offset(_baseSize * widget.pictureModel.scale / 2, _baseSize * widget.pictureModel.scale / 2);
          final startAngle = (details.localPosition - center).direction;
          setState(() {
            final endAngle = (details.localPosition + details.delta - center).direction;
            widget.pictureModel.angle += endAngle - startAngle;
          });
        },
        child: _buildControlButton(
          widget.rotateIcon ?? const Icon(Icons.sync_alt, color: Colors.black, size: 16),
          () {},
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: -_controlSize / 2,
      right: -_controlSize / 2,
      child: _buildControlButton(
        widget.closeIcon ?? const Icon(Icons.close, color: Colors.black, size: 16),
        () {
          if (widget.onCancel != null) {
            widget.onCancel!();
          }
          setState(() => widget.pictureModel.isSelected = false);
        },
      ),
    );
  }

  Widget _buildResizeHandle() {
    return Positioned(
      bottom: -_controlSize / 2,
      right: -_controlSize / 2,
      child: GestureDetector(
        onPanUpdate: (details) {
          final localPosition = details.localPosition;
          final center = Offset(_baseSize * widget.pictureModel.scale / 2, _baseSize * widget.pictureModel.scale / 2);
          final angle = (localPosition - center).direction;
          final distance = (localPosition - center).distance;
          
          setState(() {
            final newScale = (distance / (_baseSize / 2)).clamp(0.5, 5.0);
            widget.pictureModel.scale = newScale;
            
            // Adjust position to keep the center fixed
            final newSize = _baseSize * newScale;
            widget.pictureModel.left += ((_baseSize * _lastScale) - newSize) / 2;
            widget.pictureModel.top += ((_baseSize * _lastScale) - newSize) / 2;
            
            // Ensure the sticker stays within bounds
            widget.pictureModel.left = widget.pictureModel.left.clamp(0.0, widget.boundWidth - newSize);
            widget.pictureModel.top = widget.pictureModel.top.clamp(0.0, widget.boundHeight - newSize);
            
            _lastScale = newScale;
          });
        },
        child: _buildControlButton(
          widget.resizeIcon ?? const Icon(Icons.crop, color: Colors.black, size: 16),
          () {},
        ),
      ),
    );
  }
}