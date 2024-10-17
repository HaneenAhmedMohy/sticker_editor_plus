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

  @override
  void initState() {
    lastScale = widget.pictureModel.scale;
    super.initState();
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
            onScaleStart: (_) => lastScale = widget.pictureModel.scale,
            onScaleUpdate: (tap) {
              if (widget.viewOnly) return;

              setState(() {
                if (tap.pointerCount == 2) {
                  // Handle rotation
                  widget.pictureModel.angle += tap.rotation - widget.pictureModel.angle;

                  // Handle scaling
                  if ((tap.scale - lastScale!).isNegative) {
                    widget.pictureModel.scale -= 0.04;
                  } else {
                    widget.pictureModel.scale += 0.04;
                  }
                } else {
                  // // Adjust movement speed based on scale
                  // final movementFactor = 1 / widget.pictureModel.scale;

                  // // Calculate new position with scale compensation
                  // final newLeft = (widget.pictureModel.left + (tap.focalPointDelta.dx * movementFactor))
                  //     .clamp(0.0, widget.boundWidth - (50 * widget.pictureModel.scale));

                  // final newTop = (widget.pictureModel.top + (tap.focalPointDelta.dy * movementFactor))
                  //     .clamp(0.0, widget.boundHeight - (50 * widget.pictureModel.scale));

                  // // Update position
                  // widget.pictureModel.left = newLeft;
                  // widget.pictureModel.top = newTop;

                  double newLeft = widget.pictureModel.left + tap.focalPointDelta.dx;
                  double newTop = widget.pictureModel.top + tap.focalPointDelta.dy;

                  // Calculate boundaries considering the scaled size
                  double scaledWidth = 50 * widget.pictureModel.scale;
                  double scaledHeight = 50 * widget.pictureModel.scale;

                  // Clamp the positions
                  newLeft = newLeft.clamp(0.0, widget.boundWidth - scaledWidth);
                  newTop = newTop.clamp(0.0, widget.boundHeight - scaledHeight);

                  // Update the position
                  widget.pictureModel.left = newLeft;
                  widget.pictureModel.top = newTop;
                }
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
                      onPanUpdate: (tap) {
                        setState(() {
                          widget.pictureModel.angle += tap.delta.dx.isNegative ? 0.05 : -0.05;
                        });
                      },
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
                          if (tap.delta.dx.isNegative && widget.pictureModel.scale > .5) {
                            widget.pictureModel.scale -= 0.05;
                          } else if (!tap.delta.dx.isNegative && widget.pictureModel.scale < 5) {
                            widget.pictureModel.scale += 0.05;
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
