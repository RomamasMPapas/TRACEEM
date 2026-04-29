import 'package:flutter/material.dart';
import '../../../core/services/location_service.dart';
import '../../../core/config/philippine_regions.dart';

/// Widget to display current detected region with manual override option
/// The [RegionSelector] class is responsible for managing its respective UI components and state.
class RegionSelector extends StatelessWidget {
  final String? currentRegion;
  final VoidCallback? onRefresh;

  const RegionSelector({super.key, this.currentRegion, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            currentRegion ?? 'Detecting...',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onRefresh,
              child: const Icon(Icons.refresh, size: 16, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog to manually select a region
/// The [RegionSelectorDialog] class is responsible for managing its respective UI components and state.
class RegionSelectorDialog extends StatelessWidget {
  final String? currentRegion;

  const RegionSelectorDialog({super.key, this.currentRegion});

  @override
  Widget build(BuildContext context) {
    final regions = PhilippineRegions.allRegions;

    return AlertDialog(
      title: const Text('Select Region'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: regions.length,
          itemBuilder: (context, index) {
            final region = regions[index];
            final isSelected = region.code == currentRegion;

            return ListTile(
              leading: Icon(
                Icons.location_city,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              title: Text(region.name),
              subtitle: Text('${region.code} - ${region.capital}'),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.blue)
                  : null,
              selected: isSelected,
              onTap: () {
                Navigator.pop(context, region.code);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            // Auto-detect region
            final detectedRegion =
                await LocationService.detectCurrentRegionCode();
            if (context.mounted) {
              Navigator.pop(context, detectedRegion ?? 'Region 7');
            }
          },
          child: const Text('Auto-Detect'),
        ),
      ],
    );
  }
}
