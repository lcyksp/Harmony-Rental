// backend/utils/response.js
export function ok(data, message = 'success') {
  return { code: 200, data, message };
}

export function fail(message = 'error', code = 500, data = null) {
  return { code, data, message };
}
