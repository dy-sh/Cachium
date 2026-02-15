import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/models/asset.dart';

class AssetFormState {
  final String name;
  final IconData icon;
  final int colorIndex;
  final AssetStatus status;
  final String? note;
  final String? editingAssetId;
  // Original values for change tracking
  final String? originalName;
  final IconData? originalIcon;
  final int? originalColorIndex;
  final AssetStatus? originalStatus;
  final String? originalNote;

  const AssetFormState({
    this.name = '',
    this.icon = LucideIcons.box,
    this.colorIndex = 0,
    this.status = AssetStatus.active,
    this.note,
    this.editingAssetId,
    this.originalName,
    this.originalIcon,
    this.originalColorIndex,
    this.originalStatus,
    this.originalNote,
  });

  bool get isValid => name.trim().isNotEmpty;

  bool get isEditing => editingAssetId != null;

  bool get hasChanges {
    if (!isEditing) return true;
    return name != originalName ||
        icon != originalIcon ||
        colorIndex != originalColorIndex ||
        status != originalStatus ||
        note != originalNote;
  }

  bool get canSave => isValid && hasChanges;

  AssetFormState copyWith({
    String? name,
    IconData? icon,
    int? colorIndex,
    AssetStatus? status,
    String? note,
    bool clearNote = false,
    String? editingAssetId,
    String? originalName,
    IconData? originalIcon,
    int? originalColorIndex,
    AssetStatus? originalStatus,
    String? originalNote,
    bool clearOriginalNote = false,
  }) {
    return AssetFormState(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorIndex: colorIndex ?? this.colorIndex,
      status: status ?? this.status,
      note: clearNote ? null : (note ?? this.note),
      editingAssetId: editingAssetId ?? this.editingAssetId,
      originalName: originalName ?? this.originalName,
      originalIcon: originalIcon ?? this.originalIcon,
      originalColorIndex: originalColorIndex ?? this.originalColorIndex,
      originalStatus: originalStatus ?? this.originalStatus,
      originalNote: clearOriginalNote ? null : (originalNote ?? this.originalNote),
    );
  }
}

class AssetFormNotifier extends AutoDisposeNotifier<AssetFormState> {
  @override
  AssetFormState build() {
    return const AssetFormState();
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setIcon(IconData icon) {
    state = state.copyWith(icon: icon);
  }

  void setColorIndex(int index) {
    state = state.copyWith(colorIndex: index);
  }

  void setStatus(AssetStatus status) {
    state = state.copyWith(status: status);
  }

  void setNote(String? note) {
    state = state.copyWith(note: note, clearNote: note == null || note.isEmpty);
  }

  void reset() {
    state = const AssetFormState();
  }

  void initForEdit(Asset asset) {
    state = AssetFormState(
      name: asset.name,
      icon: asset.icon,
      colorIndex: asset.colorIndex,
      status: asset.status,
      note: asset.note,
      editingAssetId: asset.id,
      originalName: asset.name,
      originalIcon: asset.icon,
      originalColorIndex: asset.colorIndex,
      originalStatus: asset.status,
      originalNote: asset.note,
    );
  }
}

final assetFormProvider =
    AutoDisposeNotifierProvider<AssetFormNotifier, AssetFormState>(() {
  return AssetFormNotifier();
});
