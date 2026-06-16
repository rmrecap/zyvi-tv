// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChannelModelAdapter extends TypeAdapter<ChannelModel> {
  @override
  final int typeId = 0;

  @override
  ChannelModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChannelModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      logoUrl: fields[3] as String,
      sources: (fields[4] as List).cast<StreamSource>(),
      isLive: fields[5] as bool,
      updatedAt: fields[6] as DateTime,
      country: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ChannelModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.logoUrl)
      ..writeByte(4)
      ..write(obj.sources)
      ..writeByte(5)
      ..write(obj.isLive)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.country);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StreamSourceAdapter extends TypeAdapter<StreamSource> {
  @override
  final int typeId = 1;

  @override
  StreamSource read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StreamSource(
      name: fields[0] as String,
      url: fields[1] as String,
      resolutionQuality: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StreamSource obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.resolutionQuality);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
