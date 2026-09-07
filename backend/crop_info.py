"""
crop_info.py
------------
Small hand-written knowledge base used only to make the prediction
response friendlier (season, water need, a one-line description, emoji
icon for the UI). This has no effect on the ML prediction itself -
it's just presentation data keyed by the model's class labels.
"""

CROP_INFO = {
    "rice": {"icon": "🌾", "season": "Kharif (Jun - Nov)", "water": "High",
              "note": "Thrives in flooded fields with warm, humid weather."},
    "maize": {"icon": "🌽", "season": "Kharif / Rabi", "water": "Medium",
              "note": "Grows well in well-drained loamy soil with moderate rainfall."},
    "chickpea": {"icon": "🌱", "season": "Rabi (Oct - Mar)", "water": "Low",
              "note": "A cool-season legume, tolerant of dry spells."},
    "kidneybeans": {"icon": "🫘", "season": "Kharif", "water": "Medium",
              "note": "Prefers cooler climates and well-drained soil."},
    "pigeonpeas": {"icon": "🌿", "season": "Kharif", "water": "Low",
              "note": "Deep-rooted and drought resistant."},
    "mothbeans": {"icon": "🌱", "season": "Kharif", "water": "Low",
              "note": "Extremely drought tolerant, suited to arid regions."},
    "mungbean": {"icon": "🌱", "season": "Kharif / Summer", "water": "Low",
              "note": "Short duration crop, fixes nitrogen in soil."},
    "blackgram": {"icon": "🌱", "season": "Kharif", "water": "Low",
              "note": "Grows well in residual moisture after monsoon."},
    "lentil": {"icon": "🫘", "season": "Rabi", "water": "Low",
              "note": "A hardy, cool-season pulse crop."},
    "pomegranate": {"icon": "🍎", "season": "Year-round", "water": "Low",
              "note": "Drought tolerant fruit tree, likes dry climates."},
    "banana": {"icon": "🍌", "season": "Year-round", "water": "High",
              "note": "Needs consistent warmth and moisture."},
    "mango": {"icon": "🥭", "season": "Summer harvest", "water": "Medium",
              "note": "A dry spell before flowering improves fruiting."},
    "grapes": {"icon": "🍇", "season": "Year-round", "water": "Medium",
              "note": "Prefers well-drained soil and a dry ripening season."},
    "watermelon": {"icon": "🍉", "season": "Summer", "water": "Medium",
              "note": "Sandy loam soil with warm temperatures works best."},
    "muskmelon": {"icon": "🍈", "season": "Summer", "water": "Medium",
              "note": "Similar needs to watermelon, sensitive to frost."},
    "apple": {"icon": "🍎", "season": "Temperate / winter chill needed", "water": "Medium",
              "note": "Needs a cold winter period to set fruit properly."},
    "orange": {"icon": "🍊", "season": "Winter harvest", "water": "Medium",
              "note": "Subtropical climate with well-drained soil."},
    "papaya": {"icon": "🥭", "season": "Year-round", "water": "Medium",
              "note": "Fast growing, sensitive to waterlogging."},
    "coconut": {"icon": "🥥", "season": "Year-round", "water": "High",
              "note": "Coastal, humid climates with sandy soil."},
    "cotton": {"icon": "🧵", "season": "Kharif", "water": "Medium",
              "note": "Needs a long frost-free period and moderate rainfall."},
    "jute": {"icon": "🌾", "season": "Kharif", "water": "High",
              "note": "Warm, humid climate with high rainfall."},
    "coffee": {"icon": "☕", "season": "Year-round (perennial)", "water": "Medium",
              "note": "Shade-grown, prefers hilly, well-drained terrain."},
}

FERTILIZER_INFO = {
    "Urea": {"npk": "46-0-0", "note": "High-nitrogen fertilizer, good for leafy growth."},
    "DAP": {"npk": "18-46-0", "note": "Diammonium Phosphate - strong phosphorus source for root development."},
    "14-35-14": {"npk": "14-35-14", "note": "Balanced with high phosphorus, supports flowering & root growth."},
    "28-28": {"npk": "28-28-0", "note": "Equal nitrogen & phosphorus, good for early vegetative growth."},
    "17-17-17": {"npk": "17-17-17", "note": "Fully balanced NPK for general-purpose feeding."},
    "20-20": {"npk": "20-20-0", "note": "Balanced nitrogen & phosphorus, no potassium."},
    "10-26-26": {"npk": "10-26-26", "note": "High phosphorus & potassium, supports fruiting/flowering stage."},
}


def get_crop_info(label: str) -> dict:
    return CROP_INFO.get(label, {"icon": "🌱", "season": "-", "water": "-", "note": ""})


def get_fertilizer_info(label: str) -> dict:
    return FERTILIZER_INFO.get(label, {"npk": "-", "note": ""})
