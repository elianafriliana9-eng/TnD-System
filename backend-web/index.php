<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TnD System API</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 600px;
            width: 100%;
            text-align: center;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1.1em;
        }
        .status {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
            font-weight: bold;
        }
        .links {
            margin-top: 30px;
        }
        .link-button {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 12px 30px;
            border-radius: 50px;
            text-decoration: none;
            margin: 10px;
            transition: all 0.3s ease;
            font-weight: 500;
        }
        .link-button:hover {
            background: #764ba2;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }
        .info {
            margin-top: 30px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 10px;
            text-align: left;
        }
        .info h3 {
            color: #667eea;
            margin-bottom: 15px;
        }
        .info p {
            color: #666;
            line-height: 1.6;
            margin: 5px 0;
        }
        .footer {
            margin-top: 30px;
            color: #999;
            font-size: 0.9em;
        }
        .warning {
            background: #fff3cd;
            color: #856404;
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
            border-left: 4px solid #ffc107;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 TnD System</h1>
        <p class="subtitle">Training & Development Management API</p>
        
        <div class="status">
            ✅ API Server is Running
        </div>

        <div class="warning">
            ⚠️ <strong>Notice:</strong> SSL Certificate not installed yet. Connection is not secure.
        </div>

        <div class="links">
            <a href="/test-environment.php" class="link-button">🔍 Test Environment</a>
            <a href="/api" class="link-button">📡 API Documentation</a>
        </div>

        <div class="info">
            <h3>API Endpoints</h3>
            <p><strong>Base URL:</strong> http://tndsystem.online/api</p>
            <p><strong>Authentication:</strong> /api/auth/login.php</p>
            <p><strong>Users:</strong> /api/users.php</p>
            <p><strong>Outlets:</strong> /api/outlets.php</p>
            <p><strong>Visits:</strong> /api/visits.php</p>
            <p><strong>Training:</strong> /api/training/</p>
        </div>

        <div class="info">
            <h3>Server Information</h3>
            <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
            <p><strong>Server:</strong> <?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'; ?></p>
            <p><strong>Status:</strong> <span style="color: #28a745;">● Online</span></p>
        </div>

        <div class="footer">
            <p>TnD System © 2025 | Version 1.0</p>
            <p>Powered by PHP & Flutter</p>
        </div>
    </div>
</body>
</html>
