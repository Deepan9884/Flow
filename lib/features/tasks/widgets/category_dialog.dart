import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../categories/providers/category_provider.dart';

void showManageCategoriesDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    int selectedColorValue = 0xFF0058BE;

    final colorPresets = [
      0xFF0058BE, // Vivid Blue
      0xFF10B981, // Teal
      0xFFF59E0B, // Gold
      0xFFEF4444, // Red
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
      0xFF14B8A6, // Turquoise
      0xFF6B7280, // Charcoal
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Manage Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final existing = ref.watch(categoryListProvider);
                      if (existing.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('No categories yet.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        );
                      }
                      return Container(
                        constraints: const BoxConstraints(maxHeight: 160),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: existing.map((c) {
                              return Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(c.colorValue),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(c.name, style: const TextStyle(fontSize: 13)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                    tooltip: 'Delete ${c.name}',
                                    onPressed: () {
                                      ref.read(categoryListProvider.notifier).deleteCategory(c.uuid);
                                    },
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g., Coding Tasks',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Select Tag Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.maxFinite,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colorPresets.map((hexValue) {
                        final isSelected = selectedColorValue == hexValue;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColorValue = hexValue;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(hexValue),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      ref.read(categoryListProvider.notifier).addCategory(
                            name: name,
                            colorValue: selectedColorValue,
                          );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0058BE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
}
