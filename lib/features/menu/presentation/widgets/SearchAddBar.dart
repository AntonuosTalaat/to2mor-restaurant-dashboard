import 'package:flutter/material.dart';

class SearchAddBar extends StatelessWidget {
  final TextEditingController searchController;

  final ValueChanged<String> onSearchChanged;

  const SearchAddBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن صنف...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: onSearchChanged,  // Moved outside of InputDecoration
          ),
        ),
      ],
    );
  }
}