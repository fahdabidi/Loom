import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_design_system/loom_design_system.dart';

InterestChipItem mapInterestToken(InterestToken token) {
  return InterestChipItem(
    id: token.id,
    label: token.label,
    category: token.category,
  );
}
