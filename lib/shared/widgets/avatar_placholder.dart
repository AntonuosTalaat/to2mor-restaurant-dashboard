import 'package:flutter/material.dart';

class AvatarPlaceholder extends StatelessWidget {
  const AvatarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/avatar.png', fit: BoxFit.cover);
  }
}
