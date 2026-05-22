const fs = require("node:fs");
const postcss = require("postcss");

const [inputPath, outputPath] = process.argv.slice(2);

if (!inputPath || !outputPath) {
  console.error("usage: postcss-waybar-style.js <input.css> <output.css>");
  process.exit(2);
}

const variables = new Map();

const waybarGtkCss = {
  postcssPlugin: "waybar-gtk-css",
  Once(root) {
    root.walkRules((rule) => {
      if (rule.selector !== ":root") {
        return;
      }

      rule.walkDecls((decl) => {
        if (decl.prop.startsWith("--")) {
          variables.set(decl.prop, decl.value);
        }
      });

      rule.remove();
    });

    root.walkDecls((decl) => {
      decl.value = decl.value.replace(
        /var\(\s*(--[A-Za-z0-9_-]+)\s*(?:,\s*([^)]+))?\)/g,
        (_match, name, fallback) => {
          if (variables.has(name)) {
            return variables.get(name);
          }

          if (fallback) {
            return fallback.trim();
          }

          throw decl.error(`Missing CSS custom property: ${name}`);
        },
      );
    });
  },
};

const css = fs.readFileSync(inputPath, "utf8");

postcss([waybarGtkCss])
  .process(css, {
    from: inputPath,
    to: outputPath,
    map: false,
  })
  .then((result) => {
    fs.writeFileSync(outputPath, result.css);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
