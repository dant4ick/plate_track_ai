# Food nutrition model

`image2nutrition.tflite`: DINOv3 ViT-Small with Nutrition5k-trained regression heads and a learned protein correction. FP16 weights; float32 input/output.

**Input:** `image`, float32 `[1, 256, 256, 3]` (NHWC), RGB in `[0, 1]`. Apply EXIF orientation, center-crop to a square, resize to 256×256, divide RGB values by 255.

**Outputs:** five separate float32 tensors, each `[1, 1]`. Signature: `serving_default`.

| Output index | Signature name | Unit |
|---:|---|---|
| 0 | `mass_g` | g |
| 1 | `carb_per_100g` | g/100 g |
| 2 | `protein_per_100g` | g/100 g |
| 3 | `calories_per_100g` | kcal/100 g |
| 4 | `fat_per_100g` | g/100 g |

Portion totals: `value_per_100g * mass_g / 100`.
