# Smart Aquaculture Monitoring System

An IoT and Machine Learning-based aquaculture monitoring platform that collects real-time sensor data, predicts critical water quality parameters, and provides farmers with actionable insights through a mobile application.

## Overview

Traditional aquaculture monitoring relies on manual measurements, which can delay the detection of poor water conditions and negatively impact fish health. This project automates data collection, analysis, and prediction using IoT devices, Machine Learning, and a full-stack application.

The system collects sensor readings using ESP32, transmits data via MQTT, predicts key water quality parameters using a Random Forest Regression model, and visualizes the results through a Flutter mobile application.

## Features

* Real-time aquaculture sensor data collection
* ESP32-based IoT device integration
* MQTT-based data transmission
* Machine Learning predictions using Random Forest Regression
* Prediction of:

  * Dissolved Oxygen (DO)
  * Ammonia (NH₃)
  * Carbon Dioxide (CO₂)
* FastAPI backend for data processing
* MongoDB database for storage and retrieval
* Flutter mobile application for monitoring and visualization

## System Architecture

ESP32 Sensors
->
MQTT Broker
->
FastAPI Backend
->
MongoDB Database
->
Random Forest Prediction Model
->
Flutter Mobile Application

## Tech Stack

### IoT

* ESP32
* MQTT

### Backend

* FastAPI
* Python

### Machine Learning

* scikit-learn
* Random Forest Regression
* NumPy
* Pandas

### Database

* MongoDB

### Frontend

* Flutter

### Version Control

* Git
* GitHub

## Machine Learning Pipeline

1. Collect sensor readings from aquaculture ponds.
2. Preprocess and clean the collected data.
3. Train Random Forest Regression models.
4. Predict:

   * Dissolved Oxygen (DO)
   * Ammonia
   * Carbon Dioxide (CO₂)
5. Store results in MongoDB.
6. Display predictions through the Flutter application.

## Project Structure

```text
lib/                  # Flutter application
backend/              # FastAPI backend
backend/app/ml/       # Random Forest model training and prediction
docs/                 # Documentation and diagrams
```

## Documentation

### App Screenshots
[Click here to view screenshots](docs/Project%20Screenshots/)

### System Architecture
[Click here to view architecture documents](docs/Project%20Architecture/)


## Future Improvements

* Cloud deployment
* Real-time alerts and notifications
* Additional water quality parameters
* Advanced ML models
* Historical trend analysis
* Farmer recommendation system

## Contributors

Aaron George Mattappillil

## License

This project is developed for academic and research purposes.
