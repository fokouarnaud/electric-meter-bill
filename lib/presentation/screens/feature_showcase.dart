// lib/presentation/widgets/feature_showcase.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureShowcase extends StatefulWidget {
  final String featureId;
  final Widget child;
  final String title;
  final String description;
  final bool showOnlyOnce;
  final VoidCallback? onComplete;
  final bool showArrow;
  final AlignmentGeometry alignment;

  const FeatureShowcase({
    super.key,
    required this.featureId,
    required this.child,
    required this.title,
    required this.description,
    this.showOnlyOnce = true,
    this.onComplete,
    this.showArrow = true,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  State<FeatureShowcase> createState() => _FeatureShowcaseState();
}

class _FeatureShowcaseState extends State<FeatureShowcase> {
  bool _visible = false;
  bool _checked = false;
  final GlobalKey _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Vérifier l'état du tutoriel après rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShowcaseStatus();
    });
  }

  Future<void> _checkShowcaseStatus() async {
    if (_checked) return;
    
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('showcase_${widget.featureId}') ?? false;
    
    if (!shown) {
      if (mounted) {
        setState(() {
          _visible = true;
          _checked = true;
        });
      }
    }
  }

  Future<void> _dismissShowcase() async {
    setState(() => _visible = false);
    
    if (widget.showOnlyOnce) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showcase_${widget.featureId}', true);
    }
    
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Enfant cible avec clé
        KeyedSubtree(
          key: _targetKey,
          child: widget.child,
        ),
        
        // Overlay de tutoriel
        if (_visible)
          GestureDetector(
            onTap: _dismissShowcase,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black54,
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // Tooltip positionné
                  _PositionedTooltip(
                    targetKey: _targetKey,
                    title: widget.title,
                    description: widget.description,
                    showArrow: widget.showArrow,
                    alignment: widget.alignment,
                    onClose: _dismissShowcase,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PositionedTooltip extends StatefulWidget {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final VoidCallback onClose;
  final bool showArrow;
  final AlignmentGeometry alignment;

  const _PositionedTooltip({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.onClose,
    required this.showArrow,
    required this.alignment,
  });

  @override
  State<_PositionedTooltip> createState() => _PositionedTooltipState();
}

class _PositionedTooltipState extends State<_PositionedTooltip> {
  Offset _position = Offset.zero;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePosition();
    });
  }

  void _updatePosition() {
    final RenderBox? renderBox = widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      
      setState(() {
        _position = position;
        _size = size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tooltipWidth = MediaQuery.of(context).size.width * 0.75;
    
    // Calculer la position du tooltip en fonction de l'alignement
    double left = 0;
    double top = 0;
    
    switch (widget.alignment.toString()) {
      case 'Alignment.bottomCenter':
        left = _position.dx + (_size.width / 2) - (tooltipWidth / 2);
        top = _position.dy + _size.height + 16;
        break;
      case 'Alignment.topCenter':
        left = _position.dx + (_size.width / 2) - (tooltipWidth / 2);
        top = _position.dy - 120;
        break;
      case 'Alignment.centerRight':
        left = _position.dx + _size.width + 16;
        top = _position.dy + (_size.height / 2) - 60;
        break;
      case 'Alignment.centerLeft':
        left = _position.dx - tooltipWidth - 16;
        top = _position.dy + (_size.height / 2) - 60;
        break;
      default:
        left = _position.dx + (_size.width / 2) - (tooltipWidth / 2);
        top = _position.dy + _size.height + 16;
    }
    
    // S'assurer que le tooltip est toujours visible sur l'écran
    left = left.clamp(16, MediaQuery.of(context).size.width - tooltipWidth - 16);
    top = top.clamp(16, MediaQuery.of(context).size.height - 120 - 16);
    
    return Positioned(
      left: left,
      top: top,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary,
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onClose,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}