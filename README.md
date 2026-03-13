# TAPIN-Project-FINAL
TAPIN AI Software Development-  Le wagon final project.

## OAuth provider credentials

The Devise social sign-in buttons read credentials from either environment variables or Rails credentials.

### Option 1: Rails credentials

Run:

```bash
bin/rails credentials:edit
```

Add:

```yml
oauth:
  google:
    client_id: "your-google-client-id"
    client_secret: "your-google-client-secret"
  facebook:
    app_id: "your-facebook-app-id"
    app_secret: "your-facebook-app-secret"
  apple:
    client_id: "your-apple-client-id"
    team_id: "your-apple-team-id"
    key_id: "your-apple-key-id"
    private_key: |
      -----BEGIN PRIVATE KEY-----
      YOUR_APPLE_PRIVATE_KEY
      -----END PRIVATE KEY-----
```

### Option 2: environment variables

Export these before starting the server:

```bash
export GOOGLE_CLIENT_ID="your-google-client-id"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"

export FACEBOOK_APP_ID="your-facebook-app-id"
export FACEBOOK_APP_SECRET="your-facebook-app-secret"

export APPLE_CLIENT_ID="your-apple-client-id"
export APPLE_TEAM_ID="your-apple-team-id"
export APPLE_KEY_ID="your-apple-key-id"
export APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_APPLE_PRIVATE_KEY\n-----END PRIVATE KEY-----"
```

Then restart the app:

```bash
bin/rails s
```

### Callback URLs

Configure these in the provider dashboards:

```text
http://localhost:3000/users/auth/google_oauth2/callback
http://localhost:3000/users/auth/facebook/callback
http://localhost:3000/users/auth/apple/callback
```
