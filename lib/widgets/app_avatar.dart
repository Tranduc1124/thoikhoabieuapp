import 'package:flutter/material.dart';

class AppAvatar extends StatefulWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.primaryUrl,
    this.secondaryUrl,
    this.radius = 24,
    this.backgroundColor,
    this.foregroundColor,
    this.iconSize,
  });

  final String name;
  final String? primaryUrl;
  final String? secondaryUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? iconSize;

  @override
  State<AppAvatar> createState() => _AppAvatarState();
}

class _AppAvatarState extends State<AppAvatar> {
  int _urlIndex = 0;

  @override
  void didUpdateWidget(covariant AppAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryUrl != widget.primaryUrl ||
        oldWidget.secondaryUrl != widget.secondaryUrl ||
        oldWidget.name != widget.name) {
      _urlIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = [
      widget.primaryUrl,
      widget.secondaryUrl,
    ].where(_isValidRemoteUrl).cast<String>().toList(growable: false);
    final currentUrl = _urlIndex < urls.length ? urls[_urlIndex] : null;
    final fallback = _AvatarFallback(
      name: widget.name,
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      iconSize: widget.iconSize,
    );

    if (currentUrl == null) {
      return fallback;
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor:
          widget.backgroundColor ??
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
      child: ClipOval(
        child: Image.network(
          currentUrl,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: widget.radius * 2,
              height: widget.radius * 2,
              child: Center(
                child: SizedBox(
                  width: widget.radius * 0.9,
                  height: widget.radius * 0.9,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes == null
                        ? null
                        : loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            if (_urlIndex + 1 < urls.length) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _urlIndex += 1);
                }
              });
              return const SizedBox.shrink();
            }
            return fallback;
          },
        ),
      ),
    );
  }

  bool _isValidRemoteUrl(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.name,
    required this.radius,
    this.backgroundColor,
    this.foregroundColor,
    this.iconSize,
  });

  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primary.withValues(alpha: 0.14);
    final fg = foregroundColor ?? scheme.primary;
    final initial = _initial(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: initial == null
          ? Icon(
              Icons.person_rounded,
              size: iconSize ?? radius * 0.9,
              color: fg,
            )
          : Text(
              initial,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }

  String? _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.characters.first.toUpperCase();
  }
}
