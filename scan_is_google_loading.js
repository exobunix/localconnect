const fs = require('fs');
const path = require('path');

const content = fs.readFileSync('d:\\all apps\\localconnect\\lib\\presentation\\login_screen\\login_screen.dart', 'utf8');
const lines = content.split('\n');
lines.forEach((line, idx) => {
  if (line.includes('_isGoogleLoading')) {
    console.log(`L${idx + 1}: ${line.trim()}`);
  }
});
