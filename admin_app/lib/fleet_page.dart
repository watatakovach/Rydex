import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';

class FleetPage extends StatefulWidget {
  const FleetPage({super.key});

  @override
  State<FleetPage> createState() => _FleetPageState();
}

class _FleetPageState extends State<FleetPage> {
  List<dynamic> vehicles = [];

  Future<void> load() async {
    try {
      final data = await ApiService.vehicles();
      if (mounted) setState(() => vehicles = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: vehicles.isEmpty
          ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No vehicles yet')))])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (_, i) {
                final v = Map<String, dynamic>.from(vehicles[i]);
                final images = List<dynamic>.from(v['images'] ?? []);
                return Card(
                  child: ListTile(
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child: images.isEmpty
                          ? const Icon(Icons.directions_car, size: 32)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(ApiService.imageUrl(images.first['url']), fit: BoxFit.cover),
                            ),
                    ),
                    title: Text('${v['make']} ${v['model']} (${v['year']})'),
                    subtitle: Text('${v['license_plate']} · ${v['color']} · ${images.length} photo${images.length == 1 ? '' : 's'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VehicleDetailPage(vehicleId: v['id'])),
                      );
                      load();
                    },
                  ),
                );
              },
            ),
    );
  }
}

class VehicleDetailPage extends StatefulWidget {
  final int vehicleId;
  const VehicleDetailPage({super.key, required this.vehicleId});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  Map<String, dynamic>? vehicle;
  bool uploading = false;

  void showError(Object e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  Future<void> load() async {
    try {
      final data = await ApiService.vehicle(widget.vehicleId);
      if (mounted) setState(() => vehicle = data);
    } catch (e) {
      showError(e);
    }
  }

  Future<void> addPhotos() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1920);
    if (picked.isEmpty) return;
    setState(() => uploading = true);
    try {
      await ApiService.uploadVehicleImages(widget.vehicleId, picked);
      await load();
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> deletePhoto(int imageId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteVehicleImage(widget.vehicleId, imageId);
      await load();
    } catch (e) {
      showError(e);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final images = List<dynamic>.from(v?['images'] ?? []);
    return Scaffold(
      appBar: AppBar(title: Text(v == null ? 'Vehicle' : '${v['make']} ${v['model']}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: uploading ? null : addPhotos,
        icon: uploading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add_photo_alternate),
        label: Text(uploading ? 'Uploading…' : 'Add photos'),
      ),
      body: v == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Text('${v['license_plate']} · ${v['color']} · ${v['year']}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  if (images.isEmpty)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No photos yet'))),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: images.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (_, i) {
                      final img = Map<String, dynamic>.from(images[i]);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(ApiService.imageUrl(img['url']), fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton.filledTonal(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => deletePhoto(img['id']),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
