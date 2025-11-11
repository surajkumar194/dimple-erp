import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MenuTab extends StatefulWidget {
  final String title;
  final Map<String, List<String>> items;

  const MenuTab({super.key, required this.title, required this.items});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  OverlayEntry? _mainMenuOverlay;
  OverlayEntry? _subMenuOverlay;
  final LayerLink _layerLink = LayerLink();

  String? _hoveredItem;

  void _showMainMenu() {
    _mainMenuOverlay = _buildMainMenu();
    Overlay.of(context).insert(_mainMenuOverlay!);
  }

  void _removeMainMenu() {
    _mainMenuOverlay?.remove();
    _mainMenuOverlay = null;
    _removeSubMenu();
    setState(() {
      _hoveredItem = null;
    });
  }

  void _showSubMenu(String parentItem, Offset offset) {
    _removeSubMenu();
    _subMenuOverlay = _buildSubMenu(parentItem, offset);
    Overlay.of(context).insert(_subMenuOverlay!);
  }

  void _removeSubMenu() {
    _subMenuOverlay?.remove();
    _subMenuOverlay = null;
  }

  OverlayEntry _buildSubMenu(String parentItem, Offset offset) {
    List<String> subItems = widget.items[parentItem] ?? [];

    return OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy,
        left: offset.dx,
        child: Material(
          elevation: 4,
          color: Colors.transparent,
          child: Container(
            width: 180,
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subItems.map((subItem) {
                return _buildMenuItem(
                  subItem,
                  hasSubmenu: false,
                  isActive: false,
                  onTap: () {
               String route = '';

  if (subItem == 'Customers Master') route = '/customers-master';


  if (route.isNotEmpty) {
    Navigator.of(context).pushNamed(route);
  }

                    _removeMainMenu();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  OverlayEntry _buildMainMenu() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeMainMenu,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              top: offset.dy + renderBox.size.height,
              left: offset.dx,
              child: MouseRegion(
                onExit: (_) => _removeMainMenu(),
                child: Material(
                  elevation: 4,
                  color: Colors.transparent,
                  child: Container(
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.items.keys.map((item) {
                        return _buildMenuItem(
                          item,
                          hasSubmenu: widget.items[item]!.isNotEmpty,
                          isActive: _hoveredItem == item,
                          onTap: () {
                            if (widget.items[item]!.isEmpty) {
                              print('${widget.title} > $item');
                              _removeMainMenu();
                            }
                          },
                          onHover: (hovering) {
                            if (hovering) {
                              setState(() {
                                _hoveredItem = item;
                              });
                              if (widget.items[item]!.isNotEmpty) {
                                final itemRenderBox =
                                    context.findRenderObject() as RenderBox;
                                final itemOffset =
                                    itemRenderBox.localToGlobal(Offset.zero);
                                _showSubMenu(item,
                                    Offset(offset.dx + 180, offset.dy + 48));
                              }
                            } else {
                              setState(() {
                                _hoveredItem = null;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String title, {
    required bool hasSubmenu,
    required bool isActive,
    VoidCallback? onTap,
    Function(bool)? onHover,
  }) {
    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xff29166f) : Colors.lightBlueAccent,
            border: const Border(
              bottom: BorderSide(color: Colors.white, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xff29166f),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              if (hasSubmenu)
                Icon(
                  isActive ? Icons.arrow_drop_down : Icons.arrow_right,
                  color: isActive ? Colors.white : const Color(0xff29166f),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
    
        child: GestureDetector(
          onTap: () {
            if (_mainMenuOverlay == null) {
              _showMainMenu();
            } else {
              _removeMainMenu();
            }
          },
          child: Column( 
              mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
              Text(
                widget.title,
                style:  TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  color: Color(0xff29166f),
                ),
              ),
                 

              Icon(
                Icons.arrow_drop_down,
                size: 16.sp,
                color: Color(0xff29166f),
              ),
            ],
          ),
        ),
      );
  }
}