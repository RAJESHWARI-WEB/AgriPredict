"""
train_model.py
----------------
Trains the two ML models used by the app:

1. Crop Recommendation model
   Input : N, P, K, temperature, humidity, ph, rainfall
   Output: recommended crop (22 classes)

2. Fertilizer Recommendation model
   Input : Temparature, Humidity, Moisture, Soil Type, Crop Type,
            Nitrogen, Potassium, Phosphorous
   Output: recommended fertilizer (7 classes)

Both are trained with RandomForestClassifier (more stable than a single
DecisionTree on small/medium tabular data) and saved together with the
label encoders needed to decode categorical fields at inference time.

Run:  python train_model.py
"""

import json
import pickle

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score

RANDOM_STATE = 42

print("=" * 55)
print("Training Crop & Fertilizer Recommendation Models")
print("=" * 55)

# ---------------------------------------------------------------------
# 1. CROP RECOMMENDATION MODEL
# ---------------------------------------------------------------------
print("\n[1/2] Crop recommendation model")

crop_df = pd.read_csv("dataset/Crop_recommendation.csv")
crop_df.columns = [c.strip() for c in crop_df.columns]

CROP_FEATURES = ["N", "P", "K", "temperature", "humidity", "ph", "rainfall"]

X_crop = crop_df[CROP_FEATURES]
y_crop = crop_df["label"]

X_train, X_test, y_train, y_test = train_test_split(
    X_crop, y_crop, test_size=0.2, random_state=RANDOM_STATE, stratify=y_crop
)

crop_model = RandomForestClassifier(
    n_estimators=200, random_state=RANDOM_STATE, max_depth=None
)
crop_model.fit(X_train, y_train)

crop_acc = accuracy_score(y_test, crop_model.predict(X_test))
print(f"   Test accuracy: {crop_acc * 100:.2f}%")

# ---------------------------------------------------------------------
# 2. FERTILIZER RECOMMENDATION MODEL
# ---------------------------------------------------------------------
print("\n[2/2] Fertilizer recommendation model")

fert_df = pd.read_csv("dataset/Fertilizer Prediction.csv")
fert_df.columns = [c.strip() for c in fert_df.columns]
# normalise the odd column name from the source CSV
fert_df.rename(columns={"Temparature": "Temperature"}, inplace=True)

FERT_NUMERIC = ["Temperature", "Humidity", "Moisture", "Nitrogen", "Potassium", "Phosphorous"]
FERT_CATEGORICAL = ["Soil Type", "Crop Type"]

soil_encoder = LabelEncoder()
crop_type_encoder = LabelEncoder()

fert_df["Soil Type_enc"] = soil_encoder.fit_transform(fert_df["Soil Type"])
fert_df["Crop Type_enc"] = crop_type_encoder.fit_transform(fert_df["Crop Type"])

FERT_FEATURES = FERT_NUMERIC + ["Soil Type_enc", "Crop Type_enc"]

X_fert = fert_df[FERT_FEATURES]
y_fert = fert_df["Fertilizer Name"]

X_train_f, X_test_f, y_train_f, y_test_f = train_test_split(
    X_fert, y_fert, test_size=0.2, random_state=RANDOM_STATE, stratify=y_fert
)

fert_model = RandomForestClassifier(
    n_estimators=200, random_state=RANDOM_STATE, max_depth=None
)
fert_model.fit(X_train_f, y_train_f)

fert_acc = accuracy_score(y_test_f, fert_model.predict(X_test_f))
print(f"   Test accuracy: {fert_acc * 100:.2f}%")

# ---------------------------------------------------------------------
# 3. SAVE ARTIFACTS
# ---------------------------------------------------------------------
print("\nSaving model artifacts to ./models ...")

with open("models/crop_model.pkl", "wb") as f:
    pickle.dump(crop_model, f)

with open("models/fertilizer_model.pkl", "wb") as f:
    pickle.dump(fert_model, f)

with open("models/soil_encoder.pkl", "wb") as f:
    pickle.dump(soil_encoder, f)

with open("models/crop_type_encoder.pkl", "wb") as f:
    pickle.dump(crop_type_encoder, f)

meta = {
    "crop_features": CROP_FEATURES,
    "crop_classes": sorted(crop_model.classes_.tolist()),
    "crop_accuracy": round(crop_acc, 4),
    "fertilizer_features": FERT_FEATURES,
    "fertilizer_classes": sorted(fert_model.classes_.tolist()),
    "fertilizer_accuracy": round(fert_acc, 4),
    "soil_types": soil_encoder.classes_.tolist(),
    "crop_types": crop_type_encoder.classes_.tolist(),
}
with open("models/meta.json", "w") as f:
    json.dump(meta, f, indent=2)

print("Done. Models trained and saved successfully!")
print(f"  - Crop classes:       {len(meta['crop_classes'])}")
print(f"  - Fertilizer classes: {len(meta['fertilizer_classes'])}")
