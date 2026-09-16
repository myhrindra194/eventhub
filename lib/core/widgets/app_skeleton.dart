import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Placeholder animé d'un reflet.
///
/// Pour un contenu dont la forme est connue, le squelette vaut mieux qu'un
/// indicateur de chargement : il montre *où* les choses vont apparaître, si
/// bien que la mise en page ne saute pas à l'arrivée des données et que
/// l'attente paraît plus courte. Respecte `MediaQuery.disableAnimations` — le
/// « réduire les animations » du système — en retombant sur un bloc fixe.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
    this.shape = BoxShape.rectangle,
  });

  /// Un squelette circulaire, pour les avatars.
  const Skeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = 0,
      shape = BoxShape.circle;

  /// Une ligne de faux texte.
  const Skeleton.text({super.key, this.width, this.height = 12})
    : radius = AppRadius.xs,
      shape = BoxShape.rectangle;

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: t.skeletonBase,
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.circle
            ? null
            : BorderRadius.circular(widget.radius),
      ),
    );

    if (reduceMotion) return box;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - value), 0),
              end: Alignment(1 + 2 * value, 0),
              colors: [t.skeletonBase, t.skeletonHighlight, t.skeletonBase],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// Plusieurs lignes de faux texte, la dernière plus courte — la forme qu'a
/// une vraie prose, et c'est ce qui rend un squelette crédible.
class SkeletonParagraph extends StatelessWidget {
  const SkeletonParagraph({super.key, this.lines = 3, this.spacing = 8});

  final int lines;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          FractionallySizedBox(
            widthFactor: i == lines - 1 ? 0.55 : 1,
            child: const Skeleton.text(),
          ),
        ],
      ],
    );
  }
}
