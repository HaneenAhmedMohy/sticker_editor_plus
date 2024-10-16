import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:sticker_editor_plus/src/model/picture_model.dart';

class StickerEditingBox extends StatefulWidget {
  /// Your widget should be move within this [boundWidth]
  final double boundWidth;

  /// Your widget should be move within this [boundHeight]
  final double boundHeight;

  /// This picture model where you pass necessary fields
  final PictureModel pictureModel;

  /// If you use onCancel then you Have to manage IsSelected field in PicturModel
  final Function()? onCancel;

  /// If you use onTap then you Have to manage IsSelected field in PicturModel
  final Function()? onTap;

  final bool viewOnly;

  /// Custom controller Icons
  final Icon? resizeIcon;
  final Icon? rotateIcon;
  final Icon? closeIcon;

  /// Create a [StickerEditingBox] widget
  ///
  /// [pictureModel] detail of your picture
  /// [onTap] callback function that called when you tap on [StickerEditingBox]
  /// [onCancel] callback function that called when you tap on Cross icon in [StickerEditingBox] border
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
      this.onCancel})
      : super(key: key);

  @override
  _StickerEditingBoxState createState() => _StickerEditingBoxState();
}

class _StickerEditingBoxState extends State<StickerEditingBox> {
  Offset deltaOffset = const Offset(0, 0);

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
            onScaleStart: (tap) {
              setState(() => deltaOffset = const Offset(0, 0));
            },
            onScaleUpdate: (tap) {
              if (widget.viewOnly) return;

              setState(() {
                // Handle rotation when using two fingers
                if (tap.pointerCount == 2) {
                  widget.pictureModel.angle += tap.rotation - widget.pictureModel.angle;

                  // Handle scaling
                  widget.pictureModel.scale = (tap.scale * lastScale!).clamp(0.5, 5.0);
                }

                // Calculate the new position, limiting it within the boundaries
                final newLeft = (widget.pictureModel.left + tap.focalPoint.dx - deltaOffset.dx)
                    .clamp(0.0, widget.boundWidth - 50 * widget.pictureModel.scale);
                final newTop = (widget.pictureModel.top + tap.focalPoint.dy - deltaOffset.dy)
                    .clamp(0.0, widget.boundHeight - 50 * widget.pictureModel.scale);

                // Only update the position if there’s a significant change to prevent jitter
                if ((newLeft - widget.pictureModel.left).abs() > 1.0 || (newTop - widget.pictureModel.top).abs() > 1.0) {
                  widget.pictureModel.left = newLeft;
                  widget.pictureModel.top = newTop;
                }

                deltaOffset = tap.focalPoint; // Update the deltaOffset for smoother transitions
              });

              lastScale = tap.scale;
            },
            onTap: () {
              if (widget.onTap == null) {
                if (widget.pictureModel.isSelected) {
                  setState(() => widget.pictureModel.isSelected = false);
                } else {
                  setState(() => widget.pictureModel.isSelected = true);
                }
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
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: GestureDetector(
                    onPanUpdate: (tap) {
                      if (!tap.delta.dx.isNegative) {
                        setState(() => widget.pictureModel.angle -= 0.05);
                      } else {
                        setState(() => widget.pictureModel.angle += 0.05);
                      }
                    },
                    child: widget.pictureModel.isSelected
                        ? Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black, width: 1), shape: BoxShape.circle, color: Colors.white),
                            child: widget.rotateIcon ?? const Icon(Icons.sync_alt, color: Colors.black, size: 12),
                          )
                        : Container(),
                  ),
                ),
                Positioned(
                  top: 3,
                  right: 3,
                  child: InkWell(
                    onTap: () {
                      if (widget.onCancel != null) {
                        widget.onCancel!();
                      }
                      setState(() => widget.pictureModel.isSelected = false);
                    },
                    child: widget.pictureModel.isSelected
                        ? Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black, width: 1), shape: BoxShape.circle, color: Colors.white),
                            child: widget.closeIcon ?? const Icon(Icons.close, color: Colors.black, size: 12),
                          )
                        : Container(),
                  ),
                ),
                Positioned(
                  bottom: 3,
                  right: 3,
                  child: GestureDetector(
                      onPanUpdate: (tap) {
                        if (tap.delta.dx.isNegative && widget.pictureModel.scale > .5) {
                          setState(() => widget.pictureModel.scale -= 0.05);
                        } else if (!tap.delta.dx.isNegative && widget.pictureModel.scale < 5) {
                          setState(() => widget.pictureModel.scale += 0.05);
                        }
                      },
                      child: widget.pictureModel.isSelected
                          ? Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 1), color: Colors.white, shape: BoxShape.circle),
                              child: widget.resizeIcon ?? const Icon(Icons.crop, color: Colors.black, size: 12))
                          : Container()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
