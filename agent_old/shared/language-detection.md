# Language Detection

Detect project language from build files, configs, and file extensions.

## Primary Language Detection

| Indicator | Language |
|-----------|----------|
| `package.json`, `tsconfig.json`, `.eslintrc` | **Node.js** |
| `pyproject.toml`, `requirements.txt`, `manage.py`, `setup.py` | **Python** |
| `CMakeLists.txt`, `Makefile`, `meson.build`, `*.c`/`*.h` | **C** |

---

## Frontend Framework Detection

Detect from `package.json` deps, config files, or file extensions.

| Indicator | Framework | Agent |
|-----------|-----------|-------|
| `react` in deps, `next.config.*`, `.jsx`/`.tsx` files | **React** | FrontendDeveloperReact |
| `vue` in deps, `nuxt.config.*`, `.vue` files | **Vue** | FrontendDeveloperVue |
| `angular.json`, `@angular/core` in deps | **Angular** | FrontendDeveloperAngular |
| None detected / other framework | **Generic** | FrontendDeveloper |

---

## Usage

Before delegating ANY coding, testing, or review task, detect the project language:

```markdown
1. Check for `package.json`, `tsconfig.json` -> Node.js
2. Check for `pyproject.toml`, `requirements.txt` -> Python
3. Check for `CMakeLists.txt`, `Makefile` -> C
4. If UI work: check for react/vue/angular in deps
```

Then route to the appropriate language-specific agent.
