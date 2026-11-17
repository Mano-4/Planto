# Planto

Planto is an iPhone app that helps you care for your plants by organizing their watering reminders in one place. Keep track of each plant’s needs and mark it as watered when you are done.

## Main Features

- Add, edit, and delete plant reminders.
- Record each plant’s name, room, light needs, watering interval, and water amount.
- Receive local watering notifications based on each plant’s watering schedule.
- Update the next reminder after marking a plant as watered.
- Check and uncheck plants and view daily completion progress.
- Swipe left on a plant to delete its reminder.
- Save plant data locally so it remains available after reopening the app.
- Welcome, empty, and all-done screens with the original Planto mascot.

## Technologies

- Swift and SwiftUI
- MVVM architecture
- Observation for view model state
- Codable, JSON, and UserDefaults for local storage
- UserNotifications for local reminders
- Native Liquid Glass controls
- Icon Composer for the app icon

## Run the App

Open `Planto.xcodeproj` in Xcode, select the Planto scheme and a supported iPhone Simulator or device, then press Run. Allow notifications when prompted to receive watering reminders.

