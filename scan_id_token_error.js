const fs = require('fs');
const path = require('path');

function scanDir(dir) {
  if (dir.includes('node_modules') || dir.includes('.git') || dir.includes('build') || dir.includes('.dart_tool')) return;
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      scanDir(fullPath);
    } else {
      if (file.endsWith('.dart')) {
        const content = fs.readFileSync(fullPath, 'utf8');
        if (content.includes('no ID token received')) {
          console.log(`Match in: ${fullPath}`);
        }
      }
    }
  }
}

scanDir(__dirname);
