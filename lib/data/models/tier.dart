import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum Tier {
  common('노멀', AppColors.tierCommon),
  rare('레어', AppColors.tierRare),
  epic('에픽', AppColors.tierEpic),
  legendary('전설', AppColors.tierLegendary),
  mythic('신화', AppColors.tierMythic);

  final String label;
  final Color color;
  const Tier(this.label, this.color);
}
