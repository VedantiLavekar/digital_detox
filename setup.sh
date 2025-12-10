#!/bin/bash
# Development Setup Script for Digital Detox App

echo "🔐 Setting up Digital Detox App with secure Firebase configuration..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please edit .env file with your actual Firebase keys!"
    echo "📍 Location: $(pwd)/.env"
else
    echo "✅ .env file already exists"
fi

# Check if google-services.json exists
if [ ! -f "android/app/google-services.json" ]; then
    echo "⚠️  Missing google-services.json file!"
    echo "📥 Please download it from Firebase Console and place it at:"
    echo "📍 $(pwd)/android/app/google-services.json"
else
    echo "✅ google-services.json file found"
fi

# Install dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

echo "🎉 Setup complete! Remember to:"
echo "1. Fill in your .env file with real Firebase keys"
echo "2. Place google-services.json in android/app/"
echo "3. Never commit .env or google-services.json to git"
echo "4. Run: flutter run --dart-define-from-file=.env"