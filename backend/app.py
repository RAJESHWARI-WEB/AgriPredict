"""
app.py
------
Flask backend for the Crop & Fertilizer Recommendation System.

Endpoints
---------
GET  /api/health                 -> simple health check
GET  /api/meta                   -> soil types / crop types / class lists (for building dropdowns)
POST /api/predict/crop           -> {N,P,K,temperature,humidity,ph,rainfall} -> top crop suggestions
POST /api/predict/fertilizer     -> {temperature,humidity,moisture,soil_type,crop_type,nitrogen,potassium,phosphorous}
                                     -> top fertilizer suggestions

The same models trained by train_model.py are loaded from ./models.
Also serves the static web frontend from ../web so the whole thing can
be run with a single `python app.py`.
"""

import json
import os
import pickle

import numpy as np
import pandas as pd
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS

from crop_info import get_crop_info, get_fertilizer_info

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, "models")
WEB_DIR = os.path.join(os.path.dirname(BASE_DIR), "web")

app = Flask(__name__, static_folder=WEB_DIR, static_url_path="")
CORS(app)


def _load(name):
    with open(os.path.join(MODELS_DIR, name), "rb") as f:
        return pickle.load(f)


# ---------------------------------------------------------------------
# Load models & encoders once at startup
# ---------------------------------------------------------------------
crop_model = _load("crop_model.pkl")
fertilizer_model = _load("fertilizer_model.pkl")
soil_encoder = _load("soil_encoder.pkl")
crop_type_encoder = _load("crop_type_encoder.pkl")

with open(os.path.join(MODELS_DIR, "meta.json")) as f:
    META = json.load(f)


# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------
def bad_request(message, code=400):
    return jsonify({"error": message}), code


def require_fields(data, fields):
    missing = [f for f in fields if f not in data or data[f] in (None, "")]
    return missing


def top_n_predictions(model, features, feature_names, n=3):
    """Return top-n (label, probability) predictions for a single sample."""
    row = pd.DataFrame([features], columns=feature_names)
    proba = model.predict_proba(row)[0]
    classes = model.classes_
    order = np.argsort(proba)[::-1][:n]
    return [(str(classes[i]), float(round(proba[i] * 100, 2))) for i in order]


# ---------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------
@app.route("/api/health")
def health():
    return jsonify({"status": "ok"})


@app.route("/api/meta")
def meta():
    return jsonify(META)


@app.route("/api/predict/crop", methods=["POST"])
def predict_crop():
    data = request.get_json(silent=True) or {}
    fields = ["N", "P", "K", "temperature", "humidity", "ph", "rainfall"]

    missing = require_fields(data, fields)
    if missing:
        return bad_request(f"Missing/empty field(s): {', '.join(missing)}")

    try:
        values = [float(data[f]) for f in fields]
    except (TypeError, ValueError):
        return bad_request("All fields must be numeric.")

    N, P, K, temperature, humidity, ph, rainfall = values
    if not (0 <= ph <= 14):
        return bad_request("pH must be between 0 and 14.")
    if not (0 <= humidity <= 100):
        return bad_request("Humidity must be a percentage between 0 and 100.")

    top = top_n_predictions(crop_model, values, META["crop_features"], n=3)
    best_label, best_conf = top[0]

    return jsonify({
        "recommended_crop": best_label,
        "confidence": best_conf,
        "top_matches": [
            {"crop": label, "confidence": conf, **get_crop_info(label)}
            for label, conf in top
        ],
        "info": get_crop_info(best_label),
    })


@app.route("/api/predict/fertilizer", methods=["POST"])
def predict_fertilizer():
    data = request.get_json(silent=True) or {}
    numeric_fields = ["temperature", "humidity", "moisture", "nitrogen", "potassium", "phosphorous"]
    categorical_fields = ["soil_type", "crop_type"]

    missing = require_fields(data, numeric_fields + categorical_fields)
    if missing:
        return bad_request(f"Missing/empty field(s): {', '.join(missing)}")

    try:
        numeric_values = [float(data[f]) for f in numeric_fields]
    except (TypeError, ValueError):
        return bad_request("Temperature/humidity/moisture/nitrogen/potassium/phosphorous must be numeric.")

    soil_type = str(data["soil_type"]).strip()
    crop_type = str(data["crop_type"]).strip()

    if soil_type not in soil_encoder.classes_:
        return bad_request(f"Unknown soil_type '{soil_type}'. Valid: {list(soil_encoder.classes_)}")
    if crop_type not in crop_type_encoder.classes_:
        return bad_request(f"Unknown crop_type '{crop_type}'. Valid: {list(crop_type_encoder.classes_)}")

    soil_enc = int(soil_encoder.transform([soil_type])[0])
    crop_enc = int(crop_type_encoder.transform([crop_type])[0])

    features = numeric_values + [soil_enc, crop_enc]
    top = top_n_predictions(fertilizer_model, features, META["fertilizer_features"], n=3)
    best_label, best_conf = top[0]

    return jsonify({
        "recommended_fertilizer": best_label,
        "confidence": best_conf,
        "top_matches": [
            {"fertilizer": label, "confidence": conf, **get_fertilizer_info(label)}
            for label, conf in top
        ],
        "info": get_fertilizer_info(best_label),
    })


# ---------------------------------------------------------------------
# Serve the frontend (so `python app.py` alone runs the whole project)
# ---------------------------------------------------------------------
@app.route("/")
def index():
    return send_from_directory(WEB_DIR, "index.html")


@app.route("/<path:path>")
def static_files(path):
    return send_from_directory(WEB_DIR, path)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    debug = os.environ.get("FLASK_DEBUG", "true").lower() == "true"
    app.run(debug=debug, host="0.0.0.0", port=port)
