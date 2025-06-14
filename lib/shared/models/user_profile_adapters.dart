import 'package:hive/hive.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return UserProfile(
      id: fields[0] as String,
      age: fields[1] as int,
      weight: fields[2] as double,
      height: fields[3] as double,
      gender: fields[4] as Gender,
      activityLevel: fields[5] as ActivityLevel,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.age);
    writer.writeByte(2);
    writer.write(obj.weight);
    writer.writeByte(3);
    writer.write(obj.height);
    writer.writeByte(4);
    writer.write(obj.gender);
    writer.writeByte(5);
    writer.write(obj.activityLevel);
    writer.writeByte(6);
    writer.write(obj.createdAt);
    writer.writeByte(7);
    writer.write(obj.updatedAt);
  }
}

class GenderAdapter extends TypeAdapter<Gender> {
  @override
  final int typeId = 3;

  @override
  Gender read(BinaryReader reader) {
    final value = reader.readByte();
    return Gender.values[value];
  }

  @override
  void write(BinaryWriter writer, Gender obj) {
    writer.writeByte(obj.index);
  }
}

class ActivityLevelAdapter extends TypeAdapter<ActivityLevel> {
  @override
  final int typeId = 4;

  @override
  ActivityLevel read(BinaryReader reader) {
    final value = reader.readByte();
    return ActivityLevel.values[value];
  }

  @override
  void write(BinaryWriter writer, ActivityLevel obj) {
    writer.writeByte(obj.index);
  }
}
