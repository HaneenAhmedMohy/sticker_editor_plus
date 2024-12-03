import 'dart:math';

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
  final String? stickerName;

  const StickerEditingBox(
      {Key? key,
      required this.boundWidth,
      required this.boundHeight,
      required this.pictureModel,
      this.viewOnly = false,
      this.resizeIcon,
      this.rotateIcon,
      this.closeIcon,
      this.onTap,
      this.onCancel,
      this.stickerName})
      : super(key: key);

  @override
  _StickerEditingBoxState createState() => _StickerEditingBoxState();
}

class _StickerEditingBoxState extends State<StickerEditingBox> {
  double? lastScale;
  Offset deltaOffset = const Offset(0, 0);
  double? _initialAngle;
  Offset? _rotationStartPoint;

  @override
  void initState() {
    lastScale = widget.pictureModel.scale;
    super.initState();
  }

  double _getAngle(Offset start, Offset current) {
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    return atan2(dy, dx);
  }

  void _handleRotationStart(DragStartDetails details) {
    _rotationStartPoint = details.localPosition;
    _initialAngle = widget.pictureModel.angle - _getAngle(Offset.zero, _rotationStartPoint!);
  }

  void _handleRotationUpdate(DragUpdateDetails details) {
    if (_rotationStartPoint == null || _initialAngle == null) return;

    setState(() {
      final newAngle = _getAngle(Offset.zero, details.localPosition);
      widget.pictureModel.angle = _initialAngle! + newAngle;
    });
  }

  // Handle rotation end
  void _handleRotationEnd(DragEndDetails details) {
    _rotationStartPoint = null;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.pictureModel.top,
      left: widget.pictureModel.left,
      child: Transform.scale(
        scale: widget.pictureModel.scale,
        child: Transform.rotate(
          angle: widget.pictureModel.angle,
          child: GestureDetector(
            onScaleStart: (tap) {
              lastScale = widget.pictureModel.scale;
              setState(() => deltaOffset = Offset(tap.focalPoint.dx, tap.focalPoint.dy));
            },
            onScaleUpdate: (tap) {
              if (widget.viewOnly) {
                return;
              }

              // var intialScale = tap.scale;
              setState(() {
                if (tap.pointerCount == 2) {
                  // widget.pictureModel.angle += tap.rotation;

                  print("onScaleUpdate ==>> ${tap.scale}");
                  print(['object']);

                  if ((tap.scale - lastScale!).isNegative) {
                    widget.pictureModel.scale -= 0.04;
                  } else {
                    widget.pictureModel.scale += 0.04;
                  }

                  // widget.pictureModel.scale = tap.scale;
                }

                if ((widget.pictureModel.left + tap.focalPoint.dx - deltaOffset.dx) <= widget.boundWidth &&
                    (widget.pictureModel.left + tap.focalPoint.dx - deltaOffset.dx) > 0) {
                  widget.pictureModel.left += tap.focalPoint.dx - deltaOffset.dx;
                }
                if ((widget.pictureModel.top + tap.focalPoint.dy - deltaOffset.dy) < widget.boundHeight &&
                    (widget.pictureModel.top + tap.focalPoint.dy - deltaOffset.dy) > 0) {
                  widget.pictureModel.top += tap.focalPoint.dy - deltaOffset.dy;
                }

                deltaOffset = tap.focalPoint;
              });

              lastScale = tap.scale;
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
                      onPanStart: _handleRotationStart,
                      onPanUpdate: _handleRotationUpdate,
                      onPanEnd: _handleRotationEnd,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1), shape: BoxShape.circle, color: Colors.white),
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
                            border: Border.all(color: Colors.black, width: 1), shape: BoxShape.circle, color: Colors.white),
                        child: widget.closeIcon ?? const Icon(Icons.close, color: Colors.black, size: 12),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 3,
                    right: 3,
                    child: GestureDetector(
                      onPanUpdate: (tap) {
                        setState(() {
                          double maxScale = 1.4;

                          // Adjust the scale within the allowed range
                          if (tap.delta.dx.isNegative && widget.pictureModel.scale > 0.5) {
                            widget.pictureModel.scale = max(widget.pictureModel.scale - 0.05, 0.5);
                          } else if (!tap.delta.dx.isNegative && widget.pictureModel.scale < maxScale) {
                            widget.pictureModel.scale = min(widget.pictureModel.scale + 0.05, maxScale);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1), color: Colors.white, shape: BoxShape.circle),
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
    );
  }
}
