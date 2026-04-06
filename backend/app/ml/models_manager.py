import joblib
import os

MODELS_DIR = "e:/src/Aquaculture Project/backend/app/ml/models"

def save_model(model, name):
    os.makedirs(MODELS_DIR, exist_ok=True)
    path = os.path.join(MODELS_DIR, f"{name}.joblib")
    joblib.dump(model, path)
    return path

def load_model(name):
    path = os.path.join(MODELS_DIR, f"{name}.joblib")
    if os.path.exists(path):
        return joblib.load(path)
    return None

def load_all_artifacts():
    return {
        'reg_model': load_model('reg_model'),
        'clf_ammonia': load_model('clf_ammonia'),
        'clf_do_bin': load_model('clf_do_bin'),
        'clf_do_multi': load_model('clf_do_multi'),
        'scaler': load_model('scaler'),
        'stats': joblib.load(os.path.join(MODELS_DIR, "training_stats.joblib")) if os.path.exists(os.path.join(MODELS_DIR, "training_stats.joblib")) else {}
    }
