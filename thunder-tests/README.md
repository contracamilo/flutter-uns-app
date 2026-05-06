# Thunder Client — UniSalle Auth

Colección de Thunder Client para validar el backend Node.js antes de
integrar la app. Cumple el requerimiento del Issue #8 de mapear las
respuestas (200 OK, 401 Unauthorized, 422 Validation Error).

## Importar en VS Code

1. Instala la extensión **Thunder Client** (`rangav.vscode-thunder-client`).
2. Abre el panel de Thunder Client → **Collections** → menú `…` →
   **Import**. Selecciona `thunderCollection.json`.
3. Abre **Env** → menú `…` → **Import**. Selecciona
   `thunderEnvironment.json`. Marca **UniSalle Local** como activo.

## Endpoints incluidos

| Folder | Request | Esperado |
|--------|---------|----------|
| Auth   | POST `/auth/register` — 200 OK | crea usuario, guarda `token` y `userId` en el env |
| Auth   | POST `/auth/register` — 422    | valida que el backend devuelva `errors[]` |
| Auth   | POST `/auth/login` — 200 OK    | guarda `token` y `userId` para reutilizar |
| Auth   | POST `/auth/login` — 401       | credenciales incorrectas |
| Users  | GET `/users/me` — 200 OK       | usa Bearer del env |
| Users  | GET `/users/me` — 401          | sin token |

## Variables de entorno

| Variable      | Descripción                                              |
|---------------|----------------------------------------------------------|
| `baseUrl`     | URL del API (default: `http://localhost:3000/api`)       |
| `token`       | JWT capturado tras login/register (autocompletado)       |
| `userId`      | Id del usuario autenticado (autocompletado)              |
| `testEmail`   | Email de prueba                                          |
| `testPassword`| Password de prueba                                       |
