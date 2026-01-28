i# SocialScheduler

**SocialScheduler** (`ssched`) is a local, terminal-based automation tool for scheduling social media posts.

Designed for developers and system administrators who prefer the command line over heavy web interfaces, SocialScheduler allows you to queue text and image posts using natural language time formats. It runs as a lightweight background daemon (Systemd) on your local machine, ensuring your data stays on your disk, not a third-party server.

## Features

* **CLI-First Workflow:** Schedule, edit, and inspect posts entirely from the terminal.
* **Natural Language Scheduling:** Supports intuitive dates like "tomorrow at 5pm", "next Tuesday", or "in 3 hours".
* **Platform Support:**
    * **Facebook:** Fully implemented (Page publishing).
    * **Twitter/X:** Configuration supported (Publishing logic coming soon).
* **Offline Queue:** All scheduled posts are stored locally in `~/.socialscheduler/queue.json`.
* **Background Automation:** Includes a Systemd user service to check for due posts automatically.
* **CRUD Management:** List, inspect, edit, or cancel pending posts using short ID lookup.

---

## Installation

### Prerequisites
* Ruby 3.0+
* Systemd (Linux)

### Setup

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/yourusername/socialscheduler.git](https://github.com/yourusername/socialscheduler.git)
    cd socialscheduler
    ```

2.  **Install dependencies:**
    ```bash
    bundle install
    ```

3.  **Run the installer:**
    This script will symlink the `ssched` command to your path and set up the systemd timer.
    ```bash
    ruby setup.rb
    ```

4.  **Configuration:**
    The installer will prompt you to set up API keys. You can also run this manually later:
    ```bash
    ssched config
    ```

---

## Usage

### Scheduling a Post
Use the `-m` (message) and `-t` (time) flags. You can also attach an image with `-i`.

```bash
# Text post
ssched -m "Deploying to production on a Friday. Wish me luck." -t "today at 4:30pm"

# Image post
ssched -m "New logo concept" -i ./assets/logo.png -t "tomorrow morning"

# Targeted platform (Defaults to Facebook)
ssched -m "Short update" -p twitter -t "now"