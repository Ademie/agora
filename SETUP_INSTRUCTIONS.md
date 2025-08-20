# Agora Chat SDK Setup Instructions

## Environment Variables Setup

You need to create a `.env` file in the root directory of your project with the following variables:

```env
# Agora Chat SDK Configuration
AppKey=your_agora_app_key_here
adebayoToken=your_user_token_here
```

## How to Get These Values

### 1. AppKey
1. Go to [Agora Console](https://console.agora.io/)
2. Create a new project or select an existing one
3. Go to "Project Management" → "Project Settings"
4. Copy the "App Key" value

### 2. User Token
1. In your Agora Console project, go to "Project Management" → "User Management"
2. Create a new user or select existing user "adebayo"
3. Generate a token for this user
4. Copy the token value

## Important Notes

- The `.env` file should be in the root directory of your Flutter project
- Never commit the `.env` file to version control (it should be in `.gitignore`)
- User tokens expire, so you may need to regenerate them periodically
- Make sure you're using the correct AppKey for your project

## Testing the Setup

1. Create the `.env` file with your actual values
2. Run the app: `flutter run`
3. Check the console logs for initialization messages
4. Try logging in using the "Join" button
5. Test sending messages to another user

## Troubleshooting

If you see "AppKey not found" or "User token not found" errors:
- Make sure the `.env` file exists in the project root
- Verify the variable names match exactly (case-sensitive)
- Check that the values are not empty

If login fails:
- Verify your AppKey is correct
- Check that the user token is valid and not expired
- Ensure the user ID "adebayo" exists in your Agora project
