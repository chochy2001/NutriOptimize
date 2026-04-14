# Guía de Contribución — NutriOptimize

## Reglas del Repositorio

**Solo Jorge Salgado Miranda puede hacer push directo a `main`.**

Todos los demás integrantes del equipo deben seguir este flujo:

### 1. Crear una rama desde main
```bash
git checkout main
git pull origin main
git checkout -b feat/mi-nueva-funcionalidad
```

### 2. Hacer commits con Conventional Commits
```bash
git commit -m "feat: descripción corta de la funcionalidad"
git commit -m "fix: descripción del bug corregido"
git commit -m "docs: actualización de documentación"
```

### 3. Subir la rama y crear un Pull Request
```bash
git push origin feat/mi-nueva-funcionalidad
gh pr create --title "feat: mi funcionalidad" --body "Descripción de los cambios"
```

### 4. Esperar revisión y aprobación
Jorge revisará el PR y hará merge a main.

## Convenciones

- **Idioma del código**: Inglés para nombres de variables/funciones, español para textos de UI
- **Commits**: Inglés, formato Conventional Commits
- **Nunca** incluir referencias a herramientas de generación de código
- **Nunca** commitear API keys o credenciales
- Usar `bun` (no npm) si se necesita alguna herramienta Node

## Setup del Proyecto

```bash
git clone git@github.com:chochy2001/NutriOptimize.git
cd NutriOptimize
open NutriOptimize.xcodeproj
# Cmd + R para correr en simulador
```

## Stack Técnico
- Swift 5.9+ / SwiftUI / iOS 17+
- SwiftData para persistencia local
- MVVM con protocolos
- XcodeGen para gestión del proyecto
