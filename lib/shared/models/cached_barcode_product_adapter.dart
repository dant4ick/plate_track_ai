import 'package:hive/hive.dart';
import 'package:plate_track_ai/shared/models/cached_barcode_product.dart';

class CachedBarcodeProductAdapter extends TypeAdapter<CachedBarcodeProduct> {
  @override
  final int typeId = 5;

  @override
  CachedBarcodeProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return CachedBarcodeProduct(
      barcode: fields[0] as String,
      productName: fields[1] as String,
      caloriesPer100g: fields[2] as double,
      proteinPer100g: fields[3] as double,
      carbsPer100g: fields[4] as double,
      fatPer100g: fields[5] as double,
      cachedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedBarcodeProduct obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.barcode);
    writer.writeByte(1);
    writer.write(obj.productName);
    writer.writeByte(2);
    writer.write(obj.caloriesPer100g);
    writer.writeByte(3);
    writer.write(obj.proteinPer100g);
    writer.writeByte(4);
    writer.write(obj.carbsPer100g);
    writer.writeByte(5);
    writer.write(obj.fatPer100g);
    writer.writeByte(6);
    writer.write(obj.cachedAt);
  }
}
