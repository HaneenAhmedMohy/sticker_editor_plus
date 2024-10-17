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
  double? lastScale;
  Offset? lastFocalPoint;
  bool isDragging = false;

  @override
  void initState() {
    lastScale = widget.pictureModel.scale;
    super.initState();
  }

  void _handleDrag(Offset delta) {
    if (widget.viewOnly) return;

    setState(() {
      // Calculate new positions
      double newLeft = widget.pictureModel.left + delta.dx;
      double newTop = widget.pictureModel.top + delta.dy;

      // Calculate boundaries considering the scaled size
      double scaledWidth = 50 * widget.pictureModel.scale;
      double scaledHeight = 50 * widget.pictureModel.scale;

      // Clamp the positions
      newLeft = newLeft.clamp(0.0, widget.boundWidth - scaledWidth);
      newTop = newTop.clamp(0.0, widget.boundHeight - scaledHeight);

      // Update the position
      widget.pictureModel.left = newLeft;
      widget.pictureModel.top = newTop;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.pictureModel.top,
      left: widget.pictureModel.left,
      child: GestureDetector(
        onPanStart: (details) {
          isDragging = true;
          lastFocalPoint = details.localPosition;
        },
        onPanUpdate: (details) {
          if (isDragging) {
            final delta = details.delta;
            _handleDrag(delta);
          }
        },
        onPanEnd: (details) {
          isDragging = false;
          lastFocalPoint = null;
        },
        child: Transform.scale(
          scale: widget.pictureModel.scale,
          child: Transform.rotate(
            angle: widget.pictureModel.angle,
            child: GestureDetector(
              onScaleStart: (details) {
                lastScale = widget.pictureModel.scale;
                lastFocalPoint = details.localFocalPoint;
              },
              onScaleUpdate: (details) {
                if (widget.viewOnly) return;

                setState(() {
                  if (details.pointerCount == 2) {
                    // Handle rotation
                    widget.pictureModel.angle += details.rotation;

                    // Handle scaling
                    double newScale = lastScale! * details.scale;
                    // Clamp the scale between 0.5 and 5.0
                    widget.pictureModel.scale = newScale.clamp(0.5, 5.0);
                  }
                });
              },
              onTap: () {
                if (widget.onTap == null) {
                  setState(() => widget.pictureModel.isSelected = !widget.pictureModel.isSelected);
                } else {
                  widget.onTap!();
                }
              },
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: DottedBorder(
                      color: widget.pictureModel.isSelected ? Colors.grey[600]! : Colors.transparent,
                      padding: const EdgeInsets.all(4),
                      child: widget.pictureModel.stringUrl.startsWith('http')
                          ? Image.network(widget.pictureModel.stringUrl, height: 50, width: 50)
                          : Image.asset(widget.pictureModel.stringUrl, height: 50, width: 50),
                    ),
                  ),
                  if (widget.pictureModel.isSelected) ...[
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            widget.pictureModel.angle += details.delta.dx.isNegative ? 0.05 : -0.05;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1),
                            shape: BoxShape.circle,
                            color: Colors.white
                          ),
                          child: widget.rotateIcon ?? const Icon(Icons.sync_alt, color: Colors.black, size: 12),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 3,
                      right: 3,
                      child: InkWell(
                        onTap: () {
                          if (widget.onCancel != null) widget.onCancel!();
                          setState(() => widget.pictureModel.isSelected = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1),
                            shape: BoxShape.circle,
                            color: Colors.white
                          ),
                          child: widget.closeIcon ?? const Icon(Icons.close, color: Colors.black, size: 12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 3,
                      right: 3,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            double scaleDelta = details.delta.dx * 0.01;
                            double newScale = widget.pictureModel.scale + scaleDelta;
                            widget.pictureModel.scale = newScale.clamp(0.5, 5.0);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1),
                            color: Colors.white,
                            shape: BoxShape.circle
                          ),
                          child: widget.resizeIcon ?? const Icon(Icons.crop, color: Colors.black, size: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}