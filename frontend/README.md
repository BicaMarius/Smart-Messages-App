# Smart Messages App

A Flutter application for managing and summarizing social media conversations.

## Advanced Summary Feature

The Advanced Summary feature allows you to:

1. Upload one or more files containing social media conversations (supported formats: TXT, JSON, CSV)
2. Automatically extract people and conversation dates from the files
3. Select a person and date to generate a summary of your conversations with that person on that specific day

### Supported File Formats

The app supports various formats of exported social media conversations:

#### Plain Text Format:

```
Sender: Message [Timestamp]
```

Example:
```
John: Hey, how are you? [2024-03-24 10:30:00]
Me: I'm good, thanks! [2024-03-24 10:32:00]
```

#### JSON Format:

```json
{
  "messages": [
    {
      "sender": "John",
      "content": "Hey, how are you?",
      "timestamp": "2024-03-24 10:30:00"
    },
    {
      "sender": "Me",
      "content": "I'm good, thanks!",
      "timestamp": "2024-03-24 10:32:00"
    }
  ]
}
```

### Testing the Feature

You can use the "Generate Sample Data" option in the top-right menu of the Advanced Summary screen to create sample conversation data for testing.

### Privacy

All conversation data is processed locally on your device. The app only sends the selected conversation to the summarization API when you explicitly request a summary.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
