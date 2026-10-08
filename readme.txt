# 📋 Bunsen-Web-Triage

<p align="center">
  <img src="primary-logo-mgd.png" alt="Mega Genius Digital Logo" width="250">
</p>

<p align="center">
  <strong>An Enterprise Web Asset Reconnaissance Tool by Mega Genius Digital</strong>
</p>

---

A lightweight, high-performance Bash alternative to EyeWitness designed specifically for **BunsenLabs Linux** (and standard Debian-based distributions). 

Developed by **Mega Genius Digital**, this script reads a list of website URLs from a text file, automatically filters out duplicates and blank lines, validates real-time network and HTTP server status via `curl`, captures a headless background screenshot of the live website, and packages the entire dataset into a dark-themed, interactive HTML report that matches the BunsenLabs desktop aesthetic.

---

## ✨ Features
* 🏢 **Mega Genius Digital Branding:** Fully customized report layout featuring our corporate identifier and visual logo scheme.
* 🧠 **Un-Freezable Loop Fallbacks:** Protects scans against infinite JavaScript loops, streaming video lockups, or dead web-sockets by wrapping browser blocks inside strict 15-second system-level timers (`timeout`).
* 🗂️ **Anti-Overwrite Target Isolation:** Automatically places scan results into a timestamped directory format (`report_YYYYMMDD_HHMMSS`) so past sessions are never accidentally wiped out. Custom project directory names can also be passed via the command line.
* 🧹 **Automated De-Duplication:** Strips out duplicate URLs, blank lines, and whitespace comments dynamically before initiating network requests to save system bandwidth.
* 🚀 **Hands-Free Live View:** Launches your default browser instantly using `xdg-open` and utilizes an active meta-refresh engine to stream incoming screenshots and server headers live without manual intervention.
* ⚡ **Speed Optimization (Fast Mode):** Includes a toggle switch to bypass slow browser screenshot engines entirely, relying strictly on ultra-fast, data-limited `curl` headers.
* 🛑 **Graceful Interruption Handler:** Intercepts `Ctrl + C` signals safely to instantly format, close, and package a clean final report of whatever items were completed up until that exact second.

---

## ⚙️ System Dependencies

Before running the tool, ensure you have the required native Linux packages installed. Open your terminal (`Super + T`) and execute:

```bash
sudo apt update && sudo apt install -y curl chromium-browser
```
*(Note: If `chromium-browser` is unavailable in your current Debian branch repository, the script will automatically discover and use BunsenLabs' pre-installed `firefox-esr` binary instead).*

---

## 🚀 Installation & Quick Start

1. **Save the script** into your directory of choice as `bunsen_check.sh`.
2. **Add your company logo:** Place your corporate logo image in the same directory and name it `primary-logo-mgd.png`.
3. **Make the script executable:**
   ```bash
   chmod +x bunsen_check.sh
   ```
4. **Create your target list** (`urls.txt`) in the exact same directory as the script. Populate it with your web addresses:
   ```text
   https://example.com
   https://debian.org
   https://bunsenlabs.org
   ```
5. **Execute the utility:**
   ```bash
   ./bunsen_check.sh
   ```

---

## 🔧 Command Line Options

You can control the script's behavior using flexible command-line flags:

| Flag | Long Alternative | Description |
| :--- | :--- | :--- |
| `-n` | `--no-screenshot` | **Fast Mode:** Bypasses browser screenshot engines entirely, creating a header-only report instantly via `curl`. |
| `-r [sec]` | `--refresh [sec]` | **Custom Refresh:** Changes the live browser page auto-refresh rate (Default is `5` seconds). |
| `-o [name]` | `--output [name]` | **Project Name:** Specifies a custom folder name. If skipped, it defaults to a precise timestamp (`report_YYYYMMDD_HHMMSS`) to prevent overwriting past scans. |
| `-h` | `--help` | Displays the help and usage manual in the terminal. |

### 🛠️ Execution Examples

* **Default Run (Auto-timestamp directory, 5s refresh, screenshots enabled):**
  ```bash
  ./bunsen_check.sh
  ```
* **Custom Project Folder Scan:**
  ```bash
  ./bunsen_check.sh -o client_audit_alpha
  ```
* **Pure Speed Mode (No screenshots) + Ultra-Fast 2-second browser updates:**
  ```bash
  ./bunsen_check.sh -n -r 2
  ```

---

## 📂 Understanding the Output

Every scan creates a dedicated, self-contained directory containing your collected assets:

```text
📂 report_20260625_154130/          # Automatically generated unique session directory
 ├── 📄 primary-logo-mgd.png        # Copied corporate branding asset
 ├── 📂 screenshots/                # Contains processed raw .png captures (If enabled)
 │    ├── https___example_com.png
 │    ├── https___debian_org.png
 │    └── https___stuck_site.png    # Shows a timeout badge if a site hung up browser engines
 └── 📄 report.html                  # The main interactive summary dashboard
```

The compiled `report.html` is embedded with anti-caching meta tags to guarantee that your browser will never load old, cached image elements on page reload, and automatically strips out its own auto-refresh rules the second the script closes.

---

## 🏢 About Mega Genius Digital
This tool is maintained and distributed by **Mega Genius Digital**. We specialize in high-utility digital workflow solutions, DevOps scripting, and security triage automation. For updates or custom feature requests, please contact the engineering team.
