#!/bin/bash

##############################################
# Server Uptime Monitor - VPS Deployment Script
# Automates Nginx + SSL + Configuration
# Usage: bash deploy.sh
##############################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

# Get user inputs
print_header "Server Uptime Monitor - Deployment Setup"

echo -e "${YELLOW}Please provide the following information:${NC}\n"

read -p "Enter your domain name (e.g., monitor.example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    print_error "Domain cannot be empty"
    exit 1
fi

read -p "Enter your email for SSL certificate (for Let's Encrypt): " EMAIL
if [ -z "$EMAIL" ]; then
    print_error "Email cannot be empty"
    exit 1
fi

read -p "Enter your ServiceBin endpoint URL: " SERVICEBIN_URL
if [ -z "$SERVICEBIN_URL" ]; then
    print_error "ServiceBin URL cannot be empty"
    exit 1
fi

read -p "Do you want to set up basic authentication? (y/n): " AUTH_SETUP
AUTH_SETUP=${AUTH_SETUP:-n}

# Confirm settings
echo -e "\n${YELLOW}Configuration Summary:${NC}"
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo "ServiceBin URL: $SERVICEBIN_URL"
echo "Basic Auth: $AUTH_SETUP"
echo ""
read -p "Continue with deployment? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    print_warning "Deployment cancelled"
    exit 0
fi

# Start deployment
print_header "Step 1: System Updates"
apt update
apt upgrade -y
print_success "System updated"

# Install Nginx
print_header "Step 2: Installing Nginx"
apt install -y nginx
systemctl start nginx
systemctl enable nginx
print_success "Nginx installed and started"

# Create project directory
print_header "Step 3: Setting Up Project Directory"
PROJ_DIR="/var/www/uptime-monitor"
mkdir -p "$PROJ_DIR"
chmod 755 "$PROJ_DIR"
print_success "Project directory created at $PROJ_DIR"

# Create the HTML file with configured ServiceBin URL
print_header "Step 4: Creating Application File"
cat > "$PROJ_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Real-time server uptime monitoring dashboard with API analytics.">
    <meta name="theme-color" content="#0f172a">
    
    <!-- Lucide Icons CDN -->
    <script src="https://cdn.jsdelivr.net/npm/lucide@latest"></script>
    
    <!-- Open Graph Tags -->
    <meta property="og:title" content="Server Uptime Monitor">
    <meta property="og:description" content="Real-time server monitoring with response analytics.">
    <meta property="og:type" content="website">
    
    <title>Server Uptime Monitor | Real-time Analytics</title>

    <style>
        :root {
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --bg-tertiary: #334155;
            --text-primary: #f1f5f9;
            --text-secondary: #cbd5e1;
            --text-muted: #94a3b8;
            
            --success: #10b981;
            --warning: #f59e0b;
            --error: #ef4444;
            --info: #60a5fa;
            --accent-cyan: #22d3ee;
            
            --glow-success: rgba(16, 185, 129, 0.4);
            --glow-error: rgba(239, 68, 68, 0.4);
            --glow-info: rgba(96, 165, 250, 0.4);
            
            --radius-sm: 8px;
            --radius-md: 12px;
            --radius-lg: 16px;
            --radius-xl: 24px;
            
            --transition: 300ms cubic-bezier(0.4, 0, 0.2, 1);
            --shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.2);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%);
            color: var(--text-primary);
            overflow-x: hidden;
            line-height: 1.6;
            letter-spacing: -0.5px;
        }

        .background-gradient {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: -2;
            opacity: 0.05;
            mix-blend-mode: screen;
        }

        .background-blob {
            position: absolute;
            border-radius: 50%;
        }

        .blob-1 {
            width: 500px;
            height: 500px;
            background: radial-gradient(circle, #60a5fa 0%, transparent 70%);
            top: -10%;
            left: -5%;
            animation: float 20s ease-in-out infinite;
        }

        .blob-2 {
            width: 400px;
            height: 400px;
            background: radial-gradient(circle, #10b981 0%, transparent 70%);
            bottom: -5%;
            right: -10%;
            animation: float 25s ease-in-out infinite reverse;
        }

        @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-30px); }
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 24px;
            position: relative;
            z-index: 1;
        }

        header {
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            background: rgba(15, 23, 42, 0.6);
            border: 1px solid rgba(148, 163, 184, 0.12);
            border-radius: var(--radius-xl);
            padding: 24px 32px;
            margin-bottom: 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            animation: slideDown 0.6s ease-out;
            box-shadow: var(--shadow);
        }

        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .header-left {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .header-icon {
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: rgba(96, 165, 250, 0.1);
            border-radius: var(--radius-md);
        }

        .header-title h1 {
            font-size: 24px;
            font-weight: 700;
            color: var(--text-primary);
        }

        .header-title p {
            font-size: 13px;
            color: var(--text-muted);
            margin-top: 4px;
        }

        .header-right {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .status-indicator {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 10px 16px;
            background: rgba(16, 185, 129, 0.1);
            border: 1px solid rgba(16, 185, 129, 0.3);
            border-radius: var(--radius-lg);
            font-size: 13px;
            font-weight: 600;
            color: var(--success);
        }

        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--success);
            animation: pulse 2s ease-in-out infinite;
            box-shadow: 0 0 10px var(--glow-success);
        }

        @keyframes pulse {
            0%, 100% { box-shadow: 0 0 10px var(--glow-success), 0 0 0 0 rgba(16, 185, 129, 0.4); }
            50% { box-shadow: 0 0 15px var(--glow-success), 0 0 10px 10px rgba(16, 185, 129, 0); }
        }

        .refresh-btn {
            background: rgba(96, 165, 250, 0.1);
            border: 1px solid rgba(96, 165, 250, 0.3);
            color: var(--info);
            width: 40px;
            height: 40px;
            border-radius: var(--radius-md);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all var(--transition);
            font-size: 0;
        }

        .refresh-btn:hover {
            background: rgba(96, 165, 250, 0.2);
            border-color: rgba(96, 165, 250, 0.5);
        }

        .refresh-btn svg {
            width: 18px;
            height: 18px;
            stroke: currentColor;
            stroke-width: 2;
        }

        .refresh-btn.rotating svg {
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }

        .hero-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
            animation: fadeInUp 0.8s ease-out 0.1s both;
        }

        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .stat-card {
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            background: rgba(15, 23, 42, 0.5);
            border: 1px solid rgba(148, 163, 184, 0.12);
            border-radius: var(--radius-lg);
            padding: 24px;
            transition: all var(--transition);
            position: relative;
            overflow: hidden;
        }

        .stat-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: linear-gradient(90deg, transparent, var(--info), transparent);
            opacity: 0;
            transition: opacity var(--transition);
        }

        .stat-card:hover {
            border-color: var(--info);
            box-shadow: 0 0 30px var(--glow-info);
            transform: translateY(-8px);
        }

        .stat-card:hover::before {
            opacity: 1;
        }

        .stat-icon-box {
            width: 48px;
            height: 48px;
            background: rgba(96, 165, 250, 0.1);
            border-radius: var(--radius-md);
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 16px;
            color: var(--info);
        }

        .stat-icon-box svg {
            width: 24px;
            height: 24px;
            stroke: currentColor;
            stroke-width: 2;
        }

        .stat-label {
            font-size: 12px;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 8px;
            font-weight: 600;
        }

        .stat-value {
            font-size: 32px;
            font-weight: 700;
            color: var(--accent-cyan);
            font-family: 'Monaco', monospace;
            margin-bottom: 8px;
        }

        .stat-subtext {
            font-size: 12px;
            color: var(--text-muted);
        }

        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 16px;
            margin-bottom: 40px;
            animation: fadeInUp 0.8s ease-out 0.2s both;
        }

        .status-item {
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            background: rgba(15, 23, 42, 0.5);
            border: 1px solid rgba(148, 163, 184, 0.12);
            border-radius: var(--radius-lg);
            padding: 20px;
            display: flex;
            align-items: center;
            gap: 16px;
            transition: all var(--transition);
        }

        .status-item:hover {
            border-color: var(--info);
            background: rgba(15, 23, 42, 0.7);
        }

        .status-item-icon {
            width: 40px;
            height: 40px;
            border-radius: var(--radius-md);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            color: var(--info);
        }

        .status-item-icon svg {
            width: 20px;
            height: 20px;
            stroke: currentColor;
            stroke-width: 2;
        }

        .status-item-content {
            flex: 1;
            min-width: 0;
        }

        .status-item-label {
            font-size: 12px;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 4px;
        }

        .status-item-value {
            font-size: 14px;
            color: var(--text-primary);
            font-weight: 600;
            word-break: break-all;
        }

        .charts-section {
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            background: rgba(15, 23, 42, 0.5);
            border: 1px solid rgba(148, 163, 184, 0.12);
            border-radius: var(--radius-lg);
            padding: 32px;
            margin-bottom: 40px;
            animation: fadeInUp 0.8s ease-out 0.3s both;
        }

        .charts-title {
            font-size: 18px;
            font-weight: 700;
            margin-bottom: 24px;
            color: var(--text-primary);
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .charts-title-icon {
            width: 32px;
            height: 32px;
            background: rgba(96, 165, 250, 0.1);
            border-radius: var(--radius-md);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--info);
        }

        .charts-title-icon svg {
            width: 18px;
            height: 18px;
            stroke: currentColor;
            stroke-width: 2;
        }

        .chart-container {
            position: relative;
            height: 300px;
            margin-bottom: 32px;
        }

        canvas {
            width: 100% !important;
            height: 100% !important;
        }

        .chart-legend {
            display: flex;
            justify-content: center;
            gap: 24px;
            flex-wrap: wrap;
            margin-top: 16px;
            padding-top: 16px;
            border-top: 1px solid rgba(148, 163, 184, 0.12);
        }

        .legend-item {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 12px;
            color: var(--text-secondary);
        }

        .legend-color {
            width: 12px;
            height: 12px;
            border-radius: 2px;
        }

        .history-section {
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            background: rgba(15, 23, 42, 0.5);
            border: 1px solid rgba(148, 163, 184, 0.12);
            border-radius: var(--radius-lg);
            padding: 32px;
            animation: fadeInUp 0.8s ease-out 0.4s both;
        }

        .history-title {
            font-size: 18px;
            font-weight: 700;
            margin-bottom: 24px;
            color: var(--text-primary);
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .history-title-icon {
            width: 32px;
            height: 32px;
            background: rgba(96, 165, 250, 0.1);
            border-radius: var(--radius-md);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--info);
        }

        .history-title-icon svg {
            width: 18px;
            height: 18px;
            stroke: currentColor;
            stroke-width: 2;
        }

        .history-list {
            display: flex;
            flex-direction: column;
            gap: 12px;
            max-height: 400px;
            overflow-y: auto;
        }

        .history-item {
            display: grid;
            grid-template-columns: 100px 1fr auto;
            gap: 16px;
            padding: 12px;
            background: rgba(30, 41, 59, 0.5);
            border-radius: var(--radius-md);
            border: 1px solid rgba(148, 163, 184, 0.08);
            align-items: center;
            transition: all var(--transition);
        }

        .history-item:hover {
            background: rgba(30, 41, 59, 0.8);
            border-color: rgba(96, 165, 250, 0.2);
        }

        .history-time {
            font-size: 12px;
            color: var(--text-muted);
            font-family: monospace;
        }

        .history-details {
            display: flex;
            align-items: center;
            gap: 16px;
            min-width: 0;
        }

        .history-status {
            display: flex;
            align-items: center;
            gap: 8px;
            font-weight: 600;
            font-size: 13px;
        }

        .history-status.success {
            color: var(--success);
        }

        .history-status.error {
            color: var(--error);
        }

        .history-status.warning {
            color: var(--warning);
        }

        .history-status-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
        }

        .history-response {
            font-size: 12px;
            color: var(--text-secondary);
            font-family: monospace;
        }

        .history-empty {
            text-align: center;
            padding: 40px 20px;
            color: var(--text-muted);
        }

        footer {
            text-align: center;
            padding: 40px 20px;
            margin-top: 60px;
            border-top: 1px solid rgba(148, 163, 184, 0.12);
            color: var(--text-muted);
            font-size: 13px;
        }

        .footer-link {
            color: var(--accent-cyan);
            text-decoration: none;
            font-weight: 600;
            transition: color var(--transition);
        }

        .footer-link:hover {
            opacity: 0.8;
        }

        @media (max-width: 1024px) {
            .container { padding: 16px; }
            header { flex-direction: column; gap: 16px; text-align: center; }
            .header-left, .header-right { width: 100%; justify-content: center; }
            .chart-container { height: 250px; }
        }

        @media (max-width: 640px) {
            header { padding: 16px; }
            .header-title h1 { font-size: 18px; }
            .hero-stats { grid-template-columns: 1fr; gap: 16px; }
            .status-grid { grid-template-columns: 1fr; }
            .charts-section, .history-section { padding: 20px; }
            .chart-container { height: 200px; }
            .history-item { grid-template-columns: 1fr; gap: 8px; }
        }

        ::-webkit-scrollbar {
            width: 8px;
        }

        ::-webkit-scrollbar-track {
            background: transparent;
        }

        ::-webkit-scrollbar-thumb {
            background: var(--info);
            border-radius: 4px;
        }

        ::selection {
            background: var(--info);
            color: var(--bg-primary);
        }

        @media (prefers-reduced-motion: reduce) {
            * {
                animation: none !important;
                transition: none !important;
            }
        }
    </style>
</head>
<body>
    <div class="background-gradient">
        <div class="background-blob blob-1"></div>
        <div class="background-blob blob-2"></div>
    </div>

    <div class="container">
        <header>
            <div class="header-left">
                <div class="header-icon" id="headerIcon"></div>
                <div class="header-title">
                    <h1>Server Monitor</h1>
                    <p id="headerUrl">Loading configuration...</p>
                </div>
            </div>
            <div class="header-right">
                <div class="status-indicator">
                    <span class="status-dot"></span>
                    <span id="statusText">Checking...</span>
                </div>
                <button class="refresh-btn" id="refreshBtn" title="Refresh"></button>
            </div>
        </header>

        <div class="hero-stats">
            <div class="stat-card">
                <div class="stat-icon-box" id="upIcon"></div>
                <div class="stat-label">Uptime</div>
                <div class="stat-value" id="uptimePercent">--</div>
                <div class="stat-subtext">Last 24 hours</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon-box" id="avgIcon"></div>
                <div class="stat-label">Avg Response</div>
                <div class="stat-value" id="avgResponse">--</div>
                <div class="stat-subtext">milliseconds</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon-box" id="checkIcon"></div>
                <div class="stat-label">Total Checks</div>
                <div class="stat-value" id="totalChecks">0</div>
                <div class="stat-subtext">last 24 hours</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon-box" id="lastIcon"></div>
                <div class="stat-label">Last Check</div>
                <div class="stat-value" id="lastCheck">--</div>
                <div class="stat-subtext" id="lastCheckTime">--</div>
            </div>
        </div>

        <div class="status-grid">
            <div class="status-item">
                <div class="status-item-icon" id="statusIcon"></div>
                <div class="status-item-content">
                    <div class="status-item-label">Current Status</div>
                    <div class="status-item-value" id="currentStatus">--</div>
                </div>
            </div>
            <div class="status-item">
                <div class="status-item-icon" id="codeIcon"></div>
                <div class="status-item-content">
                    <div class="status-item-label">HTTP Status</div>
                    <div class="status-item-value" id="httpCode">--</div>
                </div>
            </div>
            <div class="status-item">
                <div class="status-item-icon" id="latencyIcon"></div>
                <div class="status-item-content">
                    <div class="status-item-label">Response Time</div>
                    <div class="status-item-value" id="responseTime">--</div>
                </div>
            </div>
            <div class="status-item">
                <div class="status-item-icon" id="timeIcon"></div>
                <div class="status-item-content">
                    <div class="status-item-label">Check Interval</div>
                    <div class="status-item-value">Every 60s</div>
                </div>
            </div>
        </div>

        <div class="charts-section">
            <div class="charts-title">
                <div class="charts-title-icon" id="chartIcon"></div>
                <span>Performance Metrics (Last Hour)</span>
            </div>
            <div class="chart-container">
                <canvas id="responseChart"></canvas>
            </div>
            <div class="chart-container">
                <canvas id="statusChart"></canvas>
            </div>
            <div class="chart-legend">
                <div class="legend-item">
                    <div class="legend-color" style="background: #60a5fa;"></div>
                    <span>Response Time (ms)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #10b981;"></div>
                    <span>Successful Checks</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #ef4444;"></div>
                    <span>Failed Checks</span>
                </div>
            </div>
        </div>

        <div class="history-section">
            <div class="history-title">
                <div class="history-title-icon" id="historyIcon"></div>
                <span>Request History</span>
            </div>
            <div class="history-list" id="historyList">
                <div class="history-empty">Loading history...</div>
            </div>
        </div>

        <footer>
            Powered by <a href="#" class="footer-link">Mr Frank</a> • Real-time Server Monitoring • <span id="footerTime">--:--:--</span>
        </footer>
    </div>

    <script>
        const CONFIG = {
            serviceUrl: 'SERVICEBIN_URL_PLACEHOLDER',
            checkInterval: 60000,
            historyLimit: 120,
        };

        const state = {
            history: [],
            currentStatus: null,
            lastCheck: null,
        };

        function renderIcon(elementId, iconName) {
            const element = document.getElementById(elementId);
            if (!element) return;
            
            const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                ${getIconPath(iconName)}
            </svg>`;
            element.innerHTML = svg;
        }

        function getIconPath(name) {
            const paths = {
                server: '<rect x="2" y="2" width="20" height="8"></rect><rect x="2" y="14" width="20" height="8"></rect><line x1="6" y1="6" x2="6" y2="6"></line><line x1="6" y1="18" x2="6" y2="18"></line>',
                activity: '<polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>',
                zap: '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>',
                trending: '<polyline points="23 6 13 16 8 11 2 17"></polyline><polyline points="17 6 23 6 23 12"></polyline>',
                clock: '<circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline>',
                wifi: '<path d="M5 12.55a11 11 0 0 1 14.08 0"></path><path d="M1.42 9a16 16 0 0 1 21.16 0"></path><path d="M9 20h6"></path><circle cx="12" cy="20" r="1"></circle>',
                gauge: '<circle cx="12" cy="12" r="9"></circle><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path><line x1="12" y1="17" x2="12.01" y2="17"></line>',
                barChart: '<line x1="12" y1="3" x2="12" y2="21"></line><line x1="18" y1="15" x2="18" y2="21"></line><line x1="6" y1="9" x2="6" y2="21"></line>',
                history: '<circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline>',
                heartbeat: '<polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>',
                refreshCw: '<polyline points="23 4 23 10 17 10"></polyline><polyline points="1 20 1 14 7 14"></polyline><path d="M3.51 9a9 9 0 0 1 14.85-3.36M20.49 15a9 9 0 0 1-14.85 3.36"></path>',
            };
            return paths[name] || paths.server;
        }

        function formatTime(date) {
            return date.toLocaleTimeString('en-US', { 
                hour: '2-digit', 
                minute: '2-digit', 
                second: '2-digit' 
            });
        }

        function timeAgo(date) {
            const seconds = Math.floor((new Date() - date) / 1000);
            if (seconds < 60) return `${seconds}s ago`;
            if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
            return `${Math.floor(seconds / 3600)}h ago`;
        }

        function calculateUptime() {
            if (state.history.length === 0) return 0;
            const successful = state.history.filter(h => h.status === 'success').length;
            return ((successful / state.history.length) * 100).toFixed(2);
        }

        function calculateAvgResponse() {
            if (state.history.length === 0) return 0;
            const total = state.history.reduce((sum, h) => sum + (h.responseTime || 0), 0);
            return Math.round(total / state.history.length);
        }

        async function checkServer() {
            const startTime = performance.now();
            const timestamp = new Date();

            try {
                const response = await fetch(CONFIG.serviceUrl, {
                    method: 'GET',
                    mode: 'cors',
                });

                const endTime = performance.now();
                const responseTime = Math.round(endTime - startTime);

                const checkResult = {
                    timestamp,
                    status: response.ok ? 'success' : 'error',
                    statusCode: response.status,
                    responseTime,
                    message: response.statusText || (response.ok ? 'OK' : 'Error'),
                };

                state.history.unshift(checkResult);
                if (state.history.length > CONFIG.historyLimit) {
                    state.history.pop();
                }

                state.currentStatus = checkResult;
                state.lastCheck = timestamp;

                updateUI(checkResult);
            } catch (error) {
                const checkResult = {
                    timestamp,
                    status: 'error',
                    statusCode: 0,
                    responseTime: 0,
                    message: error.message || 'Connection failed',
                };

                state.history.unshift(checkResult);
                if (state.history.length > CONFIG.historyLimit) {
                    state.history.pop();
                }

                state.currentStatus = checkResult;
                state.lastCheck = timestamp;

                updateUI(checkResult);
            }
        }

        function updateUI(checkResult) {
            const statusText = document.getElementById('statusText');
            const isOnline = checkResult.status === 'success';
            statusText.textContent = isOnline ? 'Online' : 'Offline';
            statusText.style.color = isOnline ? 'var(--success)' : 'var(--error)';

            document.getElementById('uptimePercent').textContent = calculateUptime() + '%';
            document.getElementById('avgResponse').textContent = calculateAvgResponse() + 'ms';
            document.getElementById('totalChecks').textContent = state.history.length;
            document.getElementById('lastCheck').textContent = formatTime(checkResult.timestamp);
            document.getElementById('lastCheckTime').textContent = timeAgo(checkResult.timestamp);

            document.getElementById('currentStatus').textContent = isOnline ? 'Online' : 'Offline';
            document.getElementById('currentStatus').style.color = isOnline ? 'var(--success)' : 'var(--error)';
            
            document.getElementById('httpCode').textContent = checkResult.statusCode || 'N/A';
            document.getElementById('responseTime').textContent = checkResult.responseTime + 'ms';

            updateHistory();
            updateCharts();
            document.getElementById('footerTime').textContent = formatTime(new Date());
        }

        function updateHistory() {
            const historyList = document.getElementById('historyList');
            
            if (state.history.length === 0) {
                historyList.innerHTML = '<div class="history-empty">No checks yet</div>';
                return;
            }

            historyList.innerHTML = state.history.map((check, index) => {
                const isSuccess = check.status === 'success';
                return `
                    <div class="history-item">
                        <div class="history-time">${formatTime(check.timestamp)}</div>
                        <div class="history-details">
                            <div class="history-status ${isSuccess ? 'success' : 'error'}">
                                <span class="history-status-dot" style="background: ${isSuccess ? 'var(--success)' : 'var(--error)'}"></span>
                                ${isSuccess ? 'Success' : 'Failed'}
                            </div>
                            <div class="history-response">${check.statusCode} • ${check.responseTime}ms</div>
                        </div>
                    </div>
                `;
            }).join('');
        }

        function drawSimpleChart(canvasId, data, color) {
            const canvas = document.getElementById(canvasId);
            if (!canvas) return;

            const ctx = canvas.getContext('2d');
            const width = canvas.offsetWidth;
            const height = canvas.offsetHeight;

            canvas.width = width;
            canvas.height = height;

            if (data.length === 0) {
                ctx.fillStyle = 'rgba(148, 163, 184, 0.5)';
                ctx.font = '14px sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText('No data yet', width / 2, height / 2);
                return;
            }

            const padding = 40;
            const chartWidth = width - padding * 2;
            const chartHeight = height - padding * 2;

            const maxValue = Math.max(...data);
            const minValue = Math.min(...data);
            const range = maxValue - minValue || 1;

            ctx.strokeStyle = 'rgba(148, 163, 184, 0.1)';
            ctx.lineWidth = 1;
            for (let i = 0; i <= 5; i++) {
                const y = padding + (chartHeight / 5) * i;
                ctx.beginPath();
                ctx.moveTo(padding, y);
                ctx.lineTo(width - padding, y);
                ctx.stroke();
            }

            ctx.strokeStyle = color;
            ctx.lineWidth = 3;
            ctx.lineCap = 'round';
            ctx.lineJoin = 'round';
            ctx.beginPath();

            data.forEach((value, index) => {
                const x = padding + (chartWidth / (data.length - 1 || 1)) * index;
                const y = height - padding - ((value - minValue) / range * chartHeight);

                if (index === 0) {
                    ctx.moveTo(x, y);
                } else {
                    ctx.lineTo(x, y);
                }
            });

            ctx.stroke();

            ctx.fillStyle = color + '33';
            ctx.lineTo(width - padding, height - padding);
            ctx.lineTo(padding, height - padding);
            ctx.closePath();
            ctx.fill();
        }

        function updateCharts() {
            const responseData = state.history.map(h => h.responseTime).reverse();
            const statusData = state.history.map(h => h.status === 'success' ? 1 : 0).reverse();

            drawSimpleChart('responseChart', responseData, '#60a5fa');
            drawSimpleChart('statusChart', statusData, '#10b981');
        }

        function init() {
            renderIcon('headerIcon', 'server');
            renderIcon('upIcon', 'activity');
            renderIcon('avgIcon', 'zap');
            renderIcon('checkIcon', 'trending');
            renderIcon('lastIcon', 'clock');
            renderIcon('statusIcon', 'wifi');
            renderIcon('codeIcon', 'gauge');
            renderIcon('latencyIcon', 'barChart');
            renderIcon('timeIcon', 'heartbeat');
            renderIcon('chartIcon', 'barChart');
            renderIcon('historyIcon', 'history');
            renderIcon('refreshBtn', 'refreshCw');

            document.getElementById('headerUrl').textContent = CONFIG.serviceUrl;

            checkServer();
            setInterval(checkServer, CONFIG.checkInterval);

            document.getElementById('refreshBtn').addEventListener('click', () => {
                const btn = document.getElementById('refreshBtn');
                btn.classList.add('rotating');
                checkServer();
                setTimeout(() => btn.classList.remove('rotating'), 1000);
            });

            let resizeTimer;
            window.addEventListener('resize', () => {
                clearTimeout(resizeTimer);
                resizeTimer = setTimeout(() => {
                    updateCharts();
                }, 250);
            });

            setTimeout(updateCharts, 100);
        }

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', init);
        } else {
            init();
        }
    </script>
</body>
</html>
EOF

# Replace placeholder with actual ServiceBin URL
sed -i "s|SERVICEBIN_URL_PLACEHOLDER|$SERVICEBIN_URL|g" "$PROJ_DIR/index.html"
chmod 644 "$PROJ_DIR/index.html"
print_success "Application file created with ServiceBin URL configured"

# Create Nginx configuration
print_header "Step 5: Configuring Nginx"
NGINX_CONFIG="/etc/nginx/sites-available/uptime-monitor"
cat > "$NGINX_CONFIG" << 'NGINX_EOF'
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;
    
    root /var/www/uptime-monitor;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;
    
    # Cache configuration
    location ~* \.html$ {
        expires 1h;
        add_header Cache-Control "public, max-age=3600";
    }
    
    location ~* \.(js|css|svg|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
    }
    
    # Main location
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX_EOF

# Replace domain placeholder
sed -i "s|DOMAIN_PLACEHOLDER|$DOMAIN|g" "$NGINX_CONFIG"

# Enable site
ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/uptime-monitor
rm -f /etc/nginx/sites-enabled/default

# Test configuration
if ! nginx -t > /dev/null 2>&1; then
    print_error "Nginx configuration test failed"
    exit 1
fi

systemctl reload nginx
print_success "Nginx configured for $DOMAIN"

# Basic authentication setup
if [ "$AUTH_SETUP" == "y" ] || [ "$AUTH_SETUP" == "Y" ]; then
    print_header "Step 6: Setting Up Basic Authentication"
    apt install -y apache2-utils
    
    read -p "Enter username for authentication: " AUTH_USER
    read -sp "Enter password for authentication: " AUTH_PASS
    echo ""
    
    htpasswd -bc /etc/nginx/.htpasswd "$AUTH_USER" "$AUTH_PASS"
    
    # Add auth to Nginx config
    cat >> "$NGINX_CONFIG" << 'AUTH_EOF'

    auth_basic "Uptime Monitor - Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;
AUTH_EOF
    
    systemctl reload nginx
    print_success "Basic authentication configured"
else
    print_warning "Skipped basic authentication setup"
fi

# Install SSL certificate
print_header "Step 7: Installing SSL Certificate"
apt install -y certbot python3-certbot-nginx

# Request certificate
if certbot --nginx -d "$DOMAIN" -m "$EMAIL" --agree-tos --non-interactive --redirect; then
    systemctl reload nginx
    print_success "SSL certificate installed and configured"
    
    # Enable auto-renewal
    systemctl enable certbot.timer
    systemctl start certbot.timer
    print_success "Auto-renewal configured"
else
    print_warning "SSL certificate installation had issues. Manual setup may be needed."
fi

# Create systemd service to monitor Nginx
print_header "Step 8: Setting Up Service Management"
cat > /etc/systemd/system/nginx-monitor.service << 'SERVICE_EOF'
[Unit]
Description=Nginx Restart Monitor
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'if ! systemctl is-active --quiet nginx; then systemctl start nginx; fi'

[Install]
WantedBy=multi-user.target
SERVICE_EOF

cat > /etc/cron.d/nginx-monitor << 'CRON_EOF'
*/5 * * * * root systemctl is-active --quiet nginx || systemctl start nginx
CRON_EOF

systemctl daemon-reload
print_success "Service monitoring configured"

# Create backup script
print_header "Step 9: Creating Backup Script"
mkdir -p /opt/uptime-monitor-backup
cat > /opt/uptime-monitor-backup/backup.sh << 'BACKUP_EOF'
#!/bin/bash
BACKUP_DIR="/opt/uptime-monitor-backup/backups"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/uptime-monitor-$(date +%Y%m%d-%H%M%S).tar.gz" /var/www/uptime-monitor/ /etc/nginx/sites-available/uptime-monitor
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
echo "Backup completed: $(ls -lah "$BACKUP_DIR" | tail -1)"
BACKUP_EOF

chmod +x /opt/uptime-monitor-backup/backup.sh

# Add to crontab for daily backups
echo "0 2 * * * root /opt/uptime-monitor-backup/backup.sh" >> /etc/cron.d/uptime-monitor-backup

print_success "Backup script created and scheduled daily"

# Final status
print_header "🎉 Deployment Complete!"

echo -e "${GREEN}Your uptime monitor is ready!${NC}\n"
echo "Access your dashboard at:"
echo -e "  ${BLUE}https://$DOMAIN${NC}"
echo ""
echo "Configuration Details:"
echo -e "  ServiceBin URL: ${BLUE}$SERVICEBIN_URL${NC}"
echo -e "  Project Directory: ${BLUE}$PROJ_DIR${NC}"
echo -e "  Nginx Config: ${BLUE}$NGINX_CONFIG${NC}"
echo ""
echo "Important Commands:"
echo -e "  ${YELLOW}Check status:${NC} systemctl status nginx"
echo -e "  ${YELLOW}View logs:${NC} tail -f /var/log/nginx/access.log"
echo -e "  ${YELLOW}Edit config:${NC} nano $PROJ_DIR/index.html"
echo -e "  ${YELLOW}Reload:${NC} systemctl reload nginx"
echo -e "  ${YELLOW}Manual backup:${NC} /opt/uptime-monitor-backup/backup.sh"
echo ""
echo -e "${GREEN}✓ Nginx is running${NC}"
echo -e "${GREEN}✓ SSL certificate configured${NC}"
echo -e "${GREEN}✓ ServiceBin monitoring active${NC}"
echo -e "${GREEN}✓ Auto-renewal enabled${NC}"
echo ""
echo "First check will start immediately. Watch the dashboard!"

# Print summary
echo -e "\n${BLUE}=== NEXT STEPS ===${NC}"
echo "1. Verify your domain's DNS A record points to this VPS"
echo "2. Wait 5 minutes for DNS to propagate"
echo "3. Visit https://$DOMAIN to see your dashboard"
echo "4. Monitoring will begin automatically every 60 seconds"
echo ""
