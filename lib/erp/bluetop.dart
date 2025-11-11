// import 'package:flutter/material.dart';

// class _BlueTopBar extends StatelessWidget {
//   final List<String> items;
//   final String active;
//   final ValueChanged<String> onTap;

//   const _BlueTopBar({
//     required this.items,
//     required this.active,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 52,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF1EA7E1), Color(0xFF61C6F0)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF1EA7E1).withOpacity(0.3),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             for (final label in items)
//               _BlueTopItem(
//                 label: label,
//                 isActive: label == active,
//                 onTap: () => onTap(label),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _BlueTopItem extends StatefulWidget {
//   final String label;
//   final bool isActive;
//   final VoidCallback onTap;

//   const _BlueTopItem({
//     required this.label,
//     required this.isActive,
//     required this.onTap,
//   });

//   @override
//   State<_BlueTopItem> createState() => _BlueTopItemState();
// }

// class _BlueTopItemState extends State<_BlueTopItem> {
//   bool _hovering = false;

//   @override
//   Widget build(BuildContext context) {
//     final bg = (widget.isActive || _hovering)
//         ? Colors.white.withOpacity(0.18)
//         : Colors.transparent;

//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       onEnter: (_) => setState(() => _hovering = true),
//       onExit: (_) => setState(() => _hovering = false),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(10),
//           onTap: widget.onTap,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 180),
//             curve: Curves.easeOut,
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
//             decoration: BoxDecoration(
//               color: bg,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.label,
//                   maxLines: 1,
//                   overflow: TextOverflow.clip,
//                   style: TextStyle(
//                     fontSize: 10, // ← requested size
//                     fontWeight: widget.isActive
//                         ? FontWeight.w700
//                         : FontWeight.w600,
//                     color: Colors.white,
//                     letterSpacing: 0.2,
//                   ),
//                 ),
//                 // underline indicator
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 180),
//                   curve: Curves.easeOut,
//                   margin: const EdgeInsets.only(top: 6),
//                   height: 3,
//                   width: widget.isActive ? 28 : 0,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }