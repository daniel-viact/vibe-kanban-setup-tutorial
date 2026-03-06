# Vibe Kanban - Setup Guide

This guide will walk you through running **Vibe Kanban** on your personal computer using Docker. No programming experience is needed — just follow the steps below.

---

## What You Will Need

Before you start, make sure you have the following installed on your computer:

1. **Docker Desktop** — This is the tool that runs Vibe Kanban in a container (a lightweight virtual environment).
2. **A GitHub account** — You will need a GitHub Personal Access Token to connect Vibe Kanban to your repositories.

---

## Step 1: Install Docker Desktop

If you don't have Docker installed yet:

1. Go to the Docker Desktop download page: <https://www.docker.com/products/docker-desktop/>
2. Download the version for your operating system (Windows, Mac, or Linux).
3. Run the installer and follow the on-screen instructions.
4. After installation, **open Docker Desktop** and make sure it is running. You should see the Docker icon in your system tray (Windows) or menu bar (Mac).

> **Tip:** On Windows, Docker may ask you to enable WSL 2 (Windows Subsystem for Linux). Follow the prompts to enable it — this is required for Docker to work.

---

## Step 2: Create a GitHub Personal Access Token

Vibe Kanban needs a GitHub token to interact with your repositories. Here's how to create one:

1. Go to GitHub and sign in to your account.
2. Follow this official guide to create a **Personal Access Token (classic)**: \
   <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic>
3. When selecting scopes (permissions), make sure to check **`repo`** (Full control of private repositories).
4. Click **Generate token**.
5. **Copy the token immediately** — you will not be able to see it again after you leave the page.

> **Important:** Keep your token safe and private. Do not share it with anyone.

---

## Step 3: Download the Project Files

Download or copy the following files into a new folder on your computer (for example, a folder called `vibe-kanban`):

Your folder should look like this:

```
vibe-kanban/
  docker-compose.yml
  .env
```

You can get these files by downloading this repository, or by creating them manually as described below.

---

## Step 4: Set Up Your Environment File

The `.env` file is where you store your GitHub token. Vibe Kanban reads this file automatically when it starts.

1. In your `vibe-kanban` folder, find the file called `.env.example`.
2. **Make a copy** of this file and rename the copy to `.env` (remove the `.example` part).
   - On **Windows**: Right-click the file > Copy > Paste > Rename to `.env`
   - On **Mac/Linux**: Open a terminal in the folder and run:
     ```
     cp .env.example .env
     ```
3. Open the `.env` file with any text editor (Notepad, TextEdit, VS Code, etc.).
4. Replace `your_github_token_here` with the token you copied in Step 2.

Your `.env` file should look like this:

```
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

(where `ghp_xxxx...` is your actual token)

---

## Step 5: Start Vibe Kanban

Now you are ready to start Vibe Kanban.

1. Open a terminal (command prompt) in your `vibe-kanban` folder:
   - **Windows**: Open the folder in File Explorer, click on the address bar, type `cmd`, and press Enter.
   - **Mac**: Open Finder, navigate to the folder, then right-click and select "Open Terminal Here" (or use Spotlight to open Terminal and `cd` to the folder).
   - **Linux**: Right-click in the folder and select "Open Terminal".
2. Run the following command:
   ```
   docker compose up -d
   ```
3. Wait for Docker to download the image and start the container. This may take a few minutes the first time.
4. Once you see the container is running, open your web browser and go to:
   ```
   http://localhost:3000
   ```

You should see the Vibe Kanban application.

> **Note:** The first time you run this command, Docker will download the Vibe Kanban image from the internet. This only happens once — future starts will be much faster.

---

## Step 6: Log In to Claude

Vibe Kanban uses Claude as an AI assistant. You need to log in to Claude from inside the running container.

1. Open a terminal (the same one or a new one).
2. Run the following command:
   ```
   docker exec -it viact-vibe-kanban-desktop gosu node claude
   ```
3. Follow the on-screen instructions to complete the Claude login.

> **Tip:** You only need to do this once. Your login session will be saved automatically.

---

## Stopping Vibe Kanban

When you want to stop Vibe Kanban:

1. Open a terminal in your `vibe-kanban` folder.
2. Run:
   ```
   docker compose down
   ```

This will stop the application. Your data is saved and will be available the next time you start it.

---

## Starting Vibe Kanban Again

To start Vibe Kanban again after stopping it:

1. Open a terminal in your `vibe-kanban` folder.
2. Run:
   ```
   docker compose up -d
   ```
3. Open your browser and go to `http://localhost:3000`.

---

## Troubleshooting

### "Docker is not running"
Make sure Docker Desktop is open and running before you execute any commands.

### "Port 3000 is already in use"
Another application is using port 3000. Either stop that application, or edit the `docker-compose.yml` file and change `"3000:3000"` to something like `"3001:3000"`, then access the app at `http://localhost:3001`.

### "Permission denied" errors
- On **Mac/Linux**, you may need to run the commands with `sudo` in front (e.g., `sudo docker compose up -d`).
- On **Windows**, make sure you are running the terminal as Administrator.

### The page is blank or won't load
Wait a minute after starting the container — the application may still be initializing. Try refreshing the page.

### "Invalid token" or GitHub-related errors
Double-check your `.env` file to make sure the token is correct and there are no extra spaces or characters.

---

## Summary of Commands

| Action | Command |
|---|---|
| Start Vibe Kanban | `docker compose up -d` |
| Stop Vibe Kanban | `docker compose down` |
| Log in to Claude | `docker exec -it viact-vibe-kanban-desktop gosu node claude` |
| View logs | `docker compose logs -f` |

---

That's it! You're all set to use Vibe Kanban. If you have any questions, feel free to reach out to the team.
