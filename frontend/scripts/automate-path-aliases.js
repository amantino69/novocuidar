const fs = require('fs');
const path = require('path');
const glob = require('glob');

const projectRoot = path.join(__dirname, '..');
const tsconfigPath = path.join(projectRoot, 'tsconfig.app.json');
const tsconfigFile = fs.readFileSync(tsconfigPath, 'utf8');
const tsconfig = JSON.parse(tsconfigFile);

const aliases = tsconfig.compilerOptions.paths;
const baseUrl = path.join(projectRoot, tsconfig.compilerOptions.baseUrl);

const aliasMap = {};
for (const alias in aliases) {
  if (aliases.hasOwnProperty(alias)) {
    const aliasPath = aliases[alias][0].replace('/*', '');
    const aliasName = alias.replace('/*', '');
    aliasMap[aliasName] = path.join(baseUrl, aliasPath);
  }
}

function processTsFiles() {
  const files = glob.sync('src/**/*.ts', { cwd: projectRoot });

  files.forEach(file => {
    const filePath = path.join(projectRoot, file);
    let content = fs.readFileSync(filePath, 'utf8');
    let changed = false;

    const importRegex = /import\s+{[^}]+}\s+from\s+['"]((?:\.\.\/)+[^'"]+)['"];/g;

    let match;
    while ((match = importRegex.exec(content)) !== null) {
      const relativePath = match[1];
      const absolutePath = path.resolve(path.dirname(filePath), relativePath);

      for (const aliasName in aliasMap) {
        if (aliasMap.hasOwnProperty(aliasName)) {
          const aliasAbsolutePath = aliasMap[aliasName];
          if (absolutePath.startsWith(aliasAbsolutePath)) {
            const newImportPath = path.join(aliasName, absolutePath.substring(aliasAbsolutePath.length)).replace(/\\/g, '/');
            const newImport = match[0].replace(relativePath, newImportPath);
            content = content.replace(match[0], newImport);
            changed = true;
            break;
          }
        }
      }
    }

    if (changed) {
      fs.writeFileSync(filePath, content, 'utf8');
      console.log(`Updated imports in: ${file}`);
    }
  });

  console.log('TypeScript path alias conversion complete.');
}

function processScssFiles() {
  const files = glob.sync('src/**/*.{scss,sass}', { cwd: projectRoot });

  files.forEach(file => {
    const filePath = path.join(projectRoot, file);
    let content = fs.readFileSync(filePath, 'utf8');
    let changed = false;

    // Regex para encontrar @import com caminhos relativos
    const importRegex = /@import\s+['"](\.\.?\/[^'"]+)['"];/g;

    let match;
    while ((match = importRegex.exec(content)) !== null) {
      const relativePath = match[1];
      const absolutePath = path.resolve(path.dirname(filePath), relativePath);

      for (const aliasName in aliasMap) {
        if (aliasMap.hasOwnProperty(aliasName)) {
          const aliasAbsolutePath = aliasMap[aliasName];
          if (absolutePath.startsWith(aliasAbsolutePath)) {
            const newImportPath = path.join(aliasName, absolutePath.substring(aliasAbsolutePath.length)).replace(/\\/g, '/');
            const newImport = match[0].replace(relativePath, newImportPath);
            content = content.replace(match[0], newImport);
            changed = true;
            break;
          }
        }
      }
    }

    if (changed) {
      fs.writeFileSync(filePath, content, 'utf8');
      console.log(`Updated imports in: ${file}`);
    }
  });

  console.log('SCSS path alias conversion complete.');
}

// Executa ambos os processos
processTsFiles();
processScssFiles();

console.log('All path alias conversions complete.');
