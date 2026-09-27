import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/mindmap.dart';
import '../providers/mindmap_providers.dart';

/// Widget de visualisation de la carte mentale (Mind Map)
/// Affiche une structure hiérarchique avec des nœuds interactifs et des lignes de connexion.
class MindMapView extends ConsumerStatefulWidget {
  final MindMap mindMap; // Les données de la carte mentale à afficher
  final GlobalKey? repaintKey; // Clé pour capturer une image de la carte (export)

  const MindMapView({
    super.key,
    required this.mindMap,
    this.repaintKey,
  });

  @override
  ConsumerState<MindMapView> createState() => _MindMapViewState();
}

class _MindMapViewState extends ConsumerState<MindMapView> {
  final TransformationController _transformController = TransformationController();
  double _scale = 1.0;
  String? _selectedNodeId;
  
  // Layout constants
  static const double _level1Distance = 280;
  static const double _level2Distance = 200;
  static const double _level3Distance = 150;
  
  // Canvas size
  static const double _canvasSize = 2000;
  static const double _centerOffset = _canvasSize / 2;

  @override
  void initState() {
    super.initState();
    // Center the view on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerView();
    });
  }

  void _centerView() {
    final size = MediaQuery.of(context).size;
    final matrix = Matrix4.identity()
      ..translate(
        size.width / 2 - _centerOffset,
        size.height / 2 - _centerOffset - 50,
      );
    _transformController.value = matrix;
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  /// Get position for a node based on its level and index
  Offset _getNodePosition(MindMapNode node, MindMapNode? parent, int indexInParent, int siblingCount, double parentAngle) {
    if (node.level == 0) {
      return Offset(_centerOffset, _centerOffset);
    }
    
    final parentPos = parent != null ? _getParentPosition(parent) : Offset(_centerOffset, _centerOffset);
    
    if (node.level == 1) {
      // Level 1: spread around root in a circle
      final angleStep = (2 * math.pi) / siblingCount;
      final angle = -math.pi / 2 + indexInParent * angleStep;
      return Offset(
        parentPos.dx + math.cos(angle) * _level1Distance,
        parentPos.dy + math.sin(angle) * _level1Distance,
      );
    } else if (node.level == 2) {
      // Level 2: spread outward from parent
      final spreadAngle = math.pi / 2.5;
      final startAngle = parentAngle - spreadAngle / 2;
      final angle = siblingCount > 1 
          ? startAngle + (spreadAngle / (siblingCount - 1)) * indexInParent
          : parentAngle;
      return Offset(
        parentPos.dx + math.cos(angle) * _level2Distance,
        parentPos.dy + math.sin(angle) * _level2Distance,
      );
    } else {
      // Level 3: spread outward from parent
      final spreadAngle = math.pi / 3;
      final startAngle = parentAngle - spreadAngle / 2;
      final angle = siblingCount > 1 
          ? startAngle + (spreadAngle / (siblingCount - 1)) * indexInParent
          : parentAngle;
      return Offset(
        parentPos.dx + math.cos(angle) * _level3Distance,
        parentPos.dy + math.sin(angle) * _level3Distance,
      );
    }
  }

  Offset _getParentPosition(MindMapNode node) {
    // Simple recursive position calculation
    if (node.level == 0) {
      return Offset(_centerOffset, _centerOffset);
    }
    // For simplicity, use cached approach
    return Offset(_centerOffset, _centerOffset);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.repaintKey,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _DotPatternPainter(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
            // MindMap content
            InteractiveViewer(
              transformationController: _transformController,
              boundaryMargin: const EdgeInsets.all(500),
              minScale: 0.2,
              maxScale: 3.0,
              constrained: false,
              onInteractionUpdate: (details) {
                setState(() {
                  _scale = _transformController.value.getMaxScaleOnAxis();
                });
              },
              child: SizedBox(
                width: _canvasSize,
                height: _canvasSize,
                child: CustomPaint(
                  painter: _MindMapPainter(
                    rootNode: widget.mindMap.rootNode,
                    centerOffset: _centerOffset,
                    level1Distance: _level1Distance,
                    level2Distance: _level2Distance,
                    level3Distance: _level3Distance,
                    selectedNodeId: _selectedNodeId,
                  ),
                  child: Stack(
                    children: _buildAllNodeWidgets(),
                  ),
                ),
              ),
            ),
            // Controls
            Positioned(
              right: 16,
              bottom: 100,
              child: _buildControls(),
            ),
            // Legend
            Positioned(
              left: 16,
              bottom: 16,
              child: _buildLegend(),
            ),
            // Title
            Positioned(
              left: 16,
              top: 16,
              child: _buildTitle(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllNodeWidgets() {
    final widgets = <Widget>[];
    _buildNodeWidgetsRecursive(
      widget.mindMap.rootNode, 
      null, 
      0, 
      1, 
      0, 
      widgets,
    );
    return widgets;
  }

  void _buildNodeWidgetsRecursive(
    MindMapNode node,
    MindMapNode? parent,
    int indexInParent,
    int siblingCount,
    double parentAngle,
    List<Widget> widgets,
  ) {
    final position = _calculatePosition(node, parent, indexInParent, siblingCount, parentAngle);
    final nodeWidth = _getNodeWidth(node.level);
    final nodeHeight = _getNodeHeight(node.level);
    
    widgets.add(
      Positioned(
        left: position.dx - nodeWidth / 2,
        top: position.dy - nodeHeight / 2,
        child: _NodeWidget(
          node: node,
          isSelected: _selectedNodeId == node.id,
          onTap: () => _onNodeTap(node),
          onLongPress: () => _onNodeLongPress(node),
          onToggleExpand: () {
            ref.read(mindMapEditorProvider.notifier).toggleExpanded(node.id);
          },
        ),
      ),
    );
    
    // Build children
    if (node.isExpanded && node.children.isNotEmpty) {
      final childCount = node.children.length;
      for (int i = 0; i < childCount; i++) {
        double childAngle;
        if (node.level == 0) {
          childAngle = -math.pi / 2 + (2 * math.pi / childCount) * i;
        } else {
          final spreadAngle = node.level == 1 ? math.pi / 2.5 : math.pi / 3;
          final startAngle = parentAngle - spreadAngle / 2;
          childAngle = childCount > 1 
              ? startAngle + (spreadAngle / (childCount - 1)) * i
              : parentAngle;
        }
        
        _buildNodeWidgetsRecursive(
          node.children[i],
          node,
          i,
          childCount,
          childAngle,
          widgets,
        );
      }
    }
  }

  Offset _calculatePosition(
    MindMapNode node,
    MindMapNode? parent,
    int indexInParent,
    int siblingCount,
    double parentAngle,
  ) {
    if (node.level == 0) {
      return Offset(_centerOffset, _centerOffset);
    }
    
    final parentPos = parent != null 
        ? _findNodePosition(parent)
        : Offset(_centerOffset, _centerOffset);
    
    double distance;
    double angle;
    
    if (node.level == 1) {
      distance = _level1Distance;
      // Spread evenly around root
      angle = -math.pi / 2 + (2 * math.pi / siblingCount) * indexInParent;
    } else if (node.level == 2) {
      distance = _level2Distance;
      // Dynamic spread angle based on sibling count
      final spreadAngle = siblingCount > 3 ? math.pi / 1.8 : math.pi / 2.5;
      final startAngle = parentAngle - spreadAngle / 2;
      angle = siblingCount > 1 
          ? startAngle + (spreadAngle / (siblingCount - 1)) * indexInParent
          : parentAngle;
    } else {
      distance = _level3Distance;
      final spreadAngle = siblingCount > 3 ? math.pi / 2 : math.pi / 3;
      final startAngle = parentAngle - spreadAngle / 2;
      angle = siblingCount > 1 
          ? startAngle + (spreadAngle / (siblingCount - 1)) * indexInParent
          : parentAngle;
    }
    
    return Offset(
      parentPos.dx + math.cos(angle) * distance,
      parentPos.dy + math.sin(angle) * distance,
    );
  }

  Offset _findNodePosition(MindMapNode node) {
    // Recursively find position
    if (node.level == 0) {
      return Offset(_centerOffset, _centerOffset);
    }
    
    // Find parent and index
    final root = widget.mindMap.rootNode;
    return _findPositionInTree(root, node, null, 0, 1, 0) ?? Offset(_centerOffset, _centerOffset);
  }

  Offset? _findPositionInTree(
    MindMapNode current,
    MindMapNode target,
    MindMapNode? parent,
    int indexInParent,
    int siblingCount,
    double parentAngle,
  ) {
    if (current.id == target.id) {
      return _calculatePosition(current, parent, indexInParent, siblingCount, parentAngle);
    }
    
    final childCount = current.children.length;
    for (int i = 0; i < childCount; i++) {
      double childAngle;
      if (current.level == 0) {
        childAngle = -math.pi / 2 + (2 * math.pi / childCount) * i;
      } else {
        final spreadAngle = current.level == 1 ? math.pi / 2.5 : math.pi / 3;
        final startAngle = parentAngle - spreadAngle / 2;
        childAngle = childCount > 1 
            ? startAngle + (spreadAngle / (childCount - 1)) * i
            : parentAngle;
      }
      
      final result = _findPositionInTree(
        current.children[i],
        target,
        current,
        i,
        childCount,
        childAngle,
      );
      if (result != null) return result;
    }
    
    return null;
  }

  double _getNodeWidth(int level) {
    switch (level) {
      case 0: return 160;
      case 1: return 140;
      case 2: return 120;
      default: return 100;
    }
  }

  double _getNodeHeight(int level) {
    switch (level) {
      case 0: return 70;
      case 1: return 55;
      case 2: return 45;
      default: return 38;
    }
  }

  void _onNodeTap(MindMapNode node) {
    setState(() {
      _selectedNodeId = _selectedNodeId == node.id ? null : node.id;
    });
    _showNodeDetails(node);
  }

  void _onNodeLongPress(MindMapNode node) {
    _showNodeOptions(node);
  }

  Widget _buildControls() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Zoom In',
              onPressed: () => _zoom(1.3),
            ),
            Text('${(_scale * 100).toInt()}%', style: const TextStyle(fontSize: 11)),
            IconButton(
              icon: const Icon(Icons.remove),
              tooltip: 'Zoom Out',
              onPressed: () => _zoom(0.7),
            ),
            const Divider(height: 8),
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              tooltip: 'Center',
              onPressed: _centerView,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hierarchy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            _legendItem(Colors.blue.shade700, 'Root (L0)'),
            _legendItem(Colors.green.shade600, 'Sections (L1)'),
            _legendItem(Colors.grey.shade600, 'Sub (L2)'),
            _legendItem(Colors.grey.shade400, 'Details (L3)'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.mindMap.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.mindMap.rootNode.totalNodes} nodes',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _zoom(double factor) {
    final currentMatrix = _transformController.value.clone();
    final center = Offset(_canvasSize / 2, _canvasSize / 2);
    
    currentMatrix
      ..translate(center.dx, center.dy)
      ..scale(factor)
      ..translate(-center.dx, -center.dy);
    
    _transformController.value = currentMatrix;
    setState(() {
      _scale = (_scale * factor).clamp(0.2, 3.0);
    });
  }

  void _showNodeDetails(MindMapNode node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            _LevelBadge(level: node.level),
            const SizedBox(width: 12),
            Expanded(child: Text(node.label, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (node.details != null && node.details!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: node.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(node.details!),
              )
            else
              const Text('No details', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            const SizedBox(height: 12),
            Text('Children: ${node.children.length}', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showNodeOptions(node);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showNodeOptions(MindMapNode node) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Node'),
              onTap: () {
                Navigator.pop(context);
                _editNode(node);
              },
            ),
            if (node.level < 3)
              ListTile(
                leading: const Icon(Icons.add, color: Colors.green),
                title: const Text('Add Child'),
                onTap: () {
                  Navigator.pop(context);
                  _addChild(node);
                },
              ),
            if (node.level > 0)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mindMapEditorProvider.notifier).deleteNode(node.id);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _editNode(MindMapNode node) {
    final labelController = TextEditingController(text: node.label);
    final detailsController = TextEditingController(text: node.details ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Node'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Details', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(mindMapEditorProvider.notifier).updateNode(
                node.id,
                label: labelController.text,
                details: detailsController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addChild(MindMapNode parent) {
    final labelController = TextEditingController();
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Child to "${parent.label}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Details (optional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (labelController.text.isNotEmpty) {
                ref.read(mindMapEditorProvider.notifier).addChild(
                  parent.id,
                  MindMapNode(
                    id: 'node-${DateTime.now().millisecondsSinceEpoch}',
                    label: labelController.text,
                    details: detailsController.text.isNotEmpty ? detailsController.text : null,
                    level: parent.level + 1,
                    color: parent.color,
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Node Widget
// ============================================================================

class _NodeWidget extends StatefulWidget {
  final MindMapNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleExpand;

  const _NodeWidget({
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleExpand,
  });

  @override
  State<_NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<_NodeWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isRoot = widget.node.level == 0;
    final nodeColor = widget.node.color;
    
    final width = isRoot ? 160.0 : (140.0 - widget.node.level * 20).clamp(100.0, 140.0);
    final height = isRoot ? 70.0 : (55.0 - widget.node.level * 8).clamp(38.0, 55.0);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: height,
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [nodeColor, nodeColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(isRoot ? 18 : 12),
            boxShadow: [
              BoxShadow(
                color: nodeColor.withOpacity(widget.isSelected ? 0.5 : 0.3),
                blurRadius: widget.isSelected ? 16 : 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: widget.isSelected ? Colors.white : Colors.transparent,
              width: widget.isSelected ? 2.5 : 0,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isRoot ? 12 : 8, vertical: 6),
                  child: Text(
                    widget.node.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isRoot ? 14 : 12 - widget.node.level * 0.5,
                      fontWeight: isRoot ? FontWeight.bold : FontWeight.w600,
                      shadows: const [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (widget.node.children.isNotEmpty)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: GestureDetector(
                    onTap: widget.onToggleExpand,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedRotation(
                        turns: widget.node.isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.expand_more, color: Colors.white, size: isRoot ? 16 : 12),
                      ),
                    ),
                  ),
                ),
              if (widget.node.children.isNotEmpty)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${widget.node.children.length}',
                      style: TextStyle(color: Colors.white, fontSize: isRoot ? 10 : 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Painters
// ============================================================================

class _MindMapPainter extends CustomPainter {
  final MindMapNode rootNode;
  final double centerOffset;
  final double level1Distance;
  final double level2Distance;
  final double level3Distance;
  final String? selectedNodeId;
  
  // Cache for node positions
  final Map<String, Offset> _positionCache = {};

  _MindMapPainter({
    required this.rootNode,
    required this.centerOffset,
    required this.level1Distance,
    required this.level2Distance,
    required this.level3Distance,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _positionCache.clear();
    _calculateAllPositions(rootNode, null, 0, 1, 0);
    _drawAllConnections(canvas, rootNode);
  }

  void _calculateAllPositions(
    MindMapNode node,
    MindMapNode? parent,
    int indexInParent,
    int siblingCount,
    double parentAngle,
  ) {
    Offset position;
    
    if (node.level == 0) {
      position = Offset(centerOffset, centerOffset);
    } else {
      final parentPos = _positionCache[parent?.id] ?? Offset(centerOffset, centerOffset);
      double distance;
      double angle;
      
      if (node.level == 1) {
        distance = level1Distance;
        angle = -math.pi / 2 + (2 * math.pi / siblingCount) * indexInParent;
      } else if (node.level == 2) {
        distance = level2Distance;
        final spreadAngle = siblingCount > 3 ? math.pi / 1.8 : math.pi / 2.5;
        final startAngle = parentAngle - spreadAngle / 2;
        angle = siblingCount > 1 
            ? startAngle + (spreadAngle / (siblingCount - 1)) * indexInParent
            : parentAngle;
      } else {
        distance = level3Distance;
        final spreadAngle = siblingCount > 3 ? math.pi / 2 : math.pi / 3;
        final startAngle = parentAngle - spreadAngle / 2;
        angle = siblingCount > 1 
            ? startAngle + (spreadAngle / (siblingCount - 1)) * indexInParent
            : parentAngle;
      }
      
      position = Offset(
        parentPos.dx + math.cos(angle) * distance,
        parentPos.dy + math.sin(angle) * distance,
      );
    }
    
    _positionCache[node.id] = position;
    
    // Calculate children positions
    if (node.isExpanded && node.children.isNotEmpty) {
      final childCount = node.children.length;
      for (int i = 0; i < childCount; i++) {
        double childAngle;
        if (node.level == 0) {
          childAngle = -math.pi / 2 + (2 * math.pi / childCount) * i;
        } else {
          final spreadAngle = node.level == 1 ? math.pi / 2.5 : math.pi / 3;
          final startAngle = parentAngle - spreadAngle / 2;
          childAngle = childCount > 1 
              ? startAngle + (spreadAngle / (childCount - 1)) * i
              : parentAngle;
        }
        _calculateAllPositions(node.children[i], node, i, childCount, childAngle);
      }
    }
  }

  void _drawAllConnections(Canvas canvas, MindMapNode node) {
    if (!node.isExpanded) return;
    
    final nodePos = _positionCache[node.id];
    if (nodePos == null) return;
    
    for (final child in node.children) {
      final childPos = _positionCache[child.id];
      if (childPos == null) continue;
      
      final paint = Paint()
        ..color = child.color.withOpacity(0.6)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      
      // Draw curved line
      final path = Path()
        ..moveTo(nodePos.dx, nodePos.dy)
        ..quadraticBezierTo(
          (nodePos.dx + childPos.dx) / 2,
          (nodePos.dy + childPos.dy) / 2,
          childPos.dx,
          childPos.dy,
        );
      
      canvas.drawPath(path, paint);
      
      // Recursively draw children connections
      _drawAllConnections(canvas, child);
    }
  }

  @override
  bool shouldRepaint(covariant _MindMapPainter oldDelegate) => true;
}

class _DotPatternPainter extends CustomPainter {
  final Color color;

  _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 30.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// Helpers
// ============================================================================

class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.blue.shade700, Colors.green.shade600, Colors.grey.shade600, Colors.grey.shade400];
    final labels = ['ROOT', 'L1', 'L2', 'L3'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: colors[level.clamp(0, 3)], borderRadius: BorderRadius.circular(6)),
      child: Text(labels[level.clamp(0, 3)], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
