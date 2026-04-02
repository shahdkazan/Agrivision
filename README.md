# 🌱 AgriVision – Smart Crop Disease Detection System

## 📌 Overview
AgriVision is a mobile-based intelligent agricultural assistant that detects crop diseases using deep learning segmentation models and provides weather-based risk analysis. The system is designed with an offline-first approach to ensure usability in low-connectivity environments.

The application is built using Flutter, integrated with TensorFlow Lite, and powered by a lightweight YOLOv8n-seg model for efficient on-device inference.

---

## 🎯 Features

- 🌿 Disease Detection (On-device AI)
  - Detects diseases from leaf images
  - Uses segmentation instead of classification
  - Draws polygons around infected regions

- 📱 Offline-First Design
  - Works without internet
  - Caches results locally
  - Syncs automatically when connection is restored

- 🌦️ Weather-Based Risk Analysis
  - Uses OpenWeather API
  - Predicts risk levels for fungal, bacterial, and pest threats

- 🔐 Authentication System
  - Farmer login using OTP (test mode)
  - Other users login using email and password

- 🧑‍🌾 Agronomist Validation
  - Experts can review predictions
  - Approve or reject diagnosis

- 🌍 Localization
  - Full Arabic support (RTL UI)

---

## 🌾 Supported Crops & Classes

Total Classes: **9**
maize fall armyworm
maize healthy
maize leaf blight
potato healthy
potato late blight
potato pest damage
tomato early blight
tomato healthy
tomato leaf miner


---

## 📊 Dataset

- Total images: 4500 unannotated 1200 annotated 
- Majority are real field images for better generalization

### Sources
- https://www.kaggle.com/datasets/manhhoangvan/yeesidtaset
- https://www.kaggle.com/datasets/abdulhasibuddin/plant-doc-dataset
- https://www.kaggle.com/datasets/arjuntejaswi/plant-village
- https://www.kaggle.com/datasets/farmannaim/maizeleaf
- https://www.kaggle.com/datasets/syedhashirali260/tomato-leaf-disease-dataset-6-classes
- https://www.kaggle.com/datasets/warcoder/potato-leaf-disease-dataset
- https://data.mendeley.com/datasets/kt64b2kh89/2
- Additional images collected manually from Google Images

---

## 🧠 Model Development
- Model: YOLOv8n-seg (Nano segmentation)
---

## 🏷️ Annotation Process

- Platform: Roboflow
- Manual annotations: ~270 images
- Auto-labeling using RF-DETR
- Final annotated dataset: 1199 images

### Dataset Composition
- 70% field images
- 30% lab images
- ~130 images per class

---

## ⚙️ Training Details

- Framework: Ultralytics YOLOv8
- Environment: Google Colab

### Configuration
- Epochs: 50
- Image size: 416
- Batch size: 16

### Augmentations
- Horizontal flip
- Brightness variation
- Scaling
- Small rotation
- Low mosaic (important for segmentation)

---

## 📈 Model Performance

| Metric | Value |
|------|------|
| mAP50 (Box) | 0.588 |
| mAP50-95 (Box) | 0.408 |
| Precision | 0.571 |
| Recall | 0.573 |

- Inference speed: ~5.5 ms per image

Exported as:
best_float16.tflite

---

## 📱 Flutter Application

### AI Pipeline
- Image preprocessing
- Model inference (TFLite)
- Post-processing (NMS + mask decoding)
- Polygon extraction using marching squares

### Output
- Annotated image with:
  - Disease regions (polygons)
  - Labels
  - Confidence scores

---

## 🌦️ Weather Risk System

- API: OpenWeather

### Inputs
- Temperature
- Humidity
- Rain
- Wind speed

### Risk Types
- Fungal
- Bacterial
- Pest

### Output
- Arabic explanations
- Risk levels:
  - Low
  - Medium
  - High

---

## ☁️ Firebase Integration

### Services
- Firebase Authentication
- Cloud Firestore

### Features
- Store diagnosis results
- Store images as Base64
- Agronomist validation workflow

---

## 🔄 Offline Sync System

- Stores results locally when offline
- Syncs automatically when internet is restored

### Components
- OfflineCacheService
- ConnectivityService
- FirebaseSyncService
- SyncService

---

## 📂 Project Structure
assets/
├── fonts/
├── models/

lib/
├── screens/
├── services/

core/
├── main.dart
├── routes.dart

---

## 📒 Training Notebook

model_training/yolov8nnotebook.ipynb

---

## 🚀 Future Improvements

- Improve model accuracy with more data
- Support more crops and diseases
- Optimize Firestore storage (avoid Base64)
  
---

## 👨‍💻 Technologies Used

- Flutter
- TensorFlow Lite
- YOLOv8 (Ultralytics)
- Firebase
- OpenWeather API
- Roboflow

---

## 📌 Conclusion

AgriVision provides an efficient and scalable solution for crop disease detection using on-device AI. The system combines segmentation-based deep learning, offline functionality, and real-world field data to support practical agricultural use.

