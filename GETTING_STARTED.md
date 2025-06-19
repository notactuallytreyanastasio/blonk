# Getting Started with Blonk 📡

Welcome to Blonk! This guide will help you get your own instance running in just a few minutes.

## What You'll Need

- A computer with Node.js installed (version 18 or higher)
- A Bluesky account
- Basic familiarity with using a terminal/command line

## Step 1: Get Node.js (if you don't have it)

First, check if you have Node.js installed by opening your terminal and typing:

```bash
node --version
```

If you see a version number like `v18.x.x` or higher, you're good to go! If not, download Node.js from [nodejs.org](https://nodejs.org/) and install it.

## Step 2: Download Blonk

1. Download the Blonk code from GitHub (use the green "Code" button → "Download ZIP")
2. Unzip the file to a folder on your computer
3. Open your terminal and navigate to that folder:

```bash
cd /path/to/blonk
```

## Step 3: Install Dependencies

In your terminal, run this command to install everything Blonk needs:

```bash
npm install
```

This will take a minute or two. You'll also need to install the client dependencies:

```bash
cd client
npm install
cd ..
```

## Step 4: Set Up Your Bluesky Credentials

1. Create a new file called `.env` in the main blonk folder
2. Copy and paste this into the file:

```
BLUESKY_HANDLE=your.handle.bsky.social
BLUESKY_PASSWORD=your-app-password
```

3. Replace `your.handle.bsky.social` with your Bluesky handle
4. Replace `your-app-password` with an app password from Bluesky:
   - Go to Settings → App Passwords in Bluesky
   - Create a new app password
   - Copy it and paste it in the .env file

⚠️ **Important**: Never share your .env file or commit it to git!

## Step 5: Start Blonk!

Run this single command to start everything:

```bash
npm run dev
```

You should see output like:
```
🚀 Blonk API server running at http://localhost:3001
➜  Local:   http://localhost:5173/
```

## Step 6: Open Blonk in Your Browser

Go to http://localhost:5173/ in your web browser. You should see the Blonk interface!

## What's Next?

### Creating Your First Blip
1. Click "transmit" in the navigation
2. Enter a title and optional URL/body
3. Choose a vibe (mood-based community)
4. Click "broadcast to the radar"

### Understanding Vibes
Vibes are mood-based communities, not topic-based. Examples:
- "sunset sunglasses struts" - confident golden hour energy
- "midnight snack attack" - impulsive 2am decisions
- "cozy corner contemplation" - rainy day thoughts

### Creating New Vibes
Vibes are created virally! When someone uses a hashtag like `#vibe-your_new_vibe`:
- It needs 5 different people to use it OR
- It needs to be mentioned 10 total times
- Then it automatically becomes a real vibe!

Check the "emerging" page to see vibes that are gaining momentum.

## Troubleshooting

### "npm: command not found"
You need to install Node.js first (see Step 1)

### "Cannot find module" errors
Make sure you ran `npm install` in both the main folder and the client folder

### "Authentication failed"
Double-check your Bluesky credentials in the .env file. Make sure you're using an app password, not your main password.

### Port already in use
Another program is using port 3001 or 5173. Close other development servers or change the ports in the code.

### The page is blank
Make sure both servers are running (you should see output from both when you run `npm run dev`)

## Need Help?

- Check the logs in your terminal for error messages
- Make sure you're in the right directory when running commands
- Try stopping the server (Ctrl+C) and starting it again

Enjoy exploring the vibe-based future of social media! 🌊