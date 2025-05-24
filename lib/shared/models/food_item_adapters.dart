import 'package:hive/hive.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';

// Manual implementation of the Hive TypeAdapters
class FoodItemAdapter extends TypeAdapter<FoodItem> {
  @override
  final int typeId = 0;

  @override
  FoodItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return FoodItem(
      id: fields[0] as String,
      name: fields[1] as String,
      calories: fields[2] as double,
      nutritionFacts: fields[3] as NutritionFacts,
      timestamp: fields[4] as DateTime,
      imagePath: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FoodItem obj) {
    writer.writeByte(6);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
    writer.writeByte(2);
    writer.write(obj.calories);
    writer.writeByte(3);
    writer.write(obj.nutritionFacts);
    writer.writeByte(4);
    writer.write(obj.timestamp);
    writer.writeByte(5);
    writer.write(obj.imagePath);
  }
}

class NutritionFactsAdapter extends TypeAdapter<NutritionFacts> {
  @override
  final int typeId = 1;

  @override
  NutritionFacts read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return NutritionFacts(
      protein: fields[0] as double,
      carbohydrates: fields[1] as double,
      fat: fields[2] as double,
      mass: fields[3] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, NutritionFacts obj) {
    writer.writeByte(4);
    writer.writeByte(0);
    writer.write(obj.protein);
    writer.writeByte(1);
    writer.write(obj.carbohydrates);
    writer.writeByte(2);
    writer.write(obj.fat);
    writer.writeByte(3);
    writer.write(obj.mass);
  }
}