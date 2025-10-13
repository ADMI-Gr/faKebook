import 'package:fakebook/screens/content/post_publish_screen.dart';
import 'package:flutter/material.dart';

class CustomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavbar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  Color _iconColor(int index, BuildContext context) {
    return selectedIndex == index ? Theme.of(context).colorScheme.primary : Colors.black26;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home_outlined, color: _iconColor(0, context)),
                onPressed: () => onItemTapped(0),
              ),
              IconButton(
                icon: Icon(Icons.grid_view_rounded, color: _iconColor(1, context)),
                onPressed: () => onItemTapped(1),
              ),
              const SizedBox(width: 56),
              IconButton(
                icon: Icon(Icons.message_outlined, color: _iconColor(3, context)),
                onPressed: () => onItemTapped(3),
              ),
              IconButton(
                icon: Icon(Icons.person_outline, color: _iconColor(4, context)),
                onPressed: () => onItemTapped(4),
              ),
            ],
          ),
          Positioned(
            top: -24,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                elevation: 4,
                shape: const CircleBorder(),
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PostPublishScreen()))
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      // gradient: LinearGradient(
                      //   begin: Alignment.topLeft,
                      //   end: Alignment.bottomRight,
                      //   colors: [Color(0xFF7F7BFF), Color(0xFF6C63FF)],
                      // ),
                    ),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
