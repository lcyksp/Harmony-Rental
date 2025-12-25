// backend/utils/getHost.js
export function getHost(req) {
  // http / https
  const protocol = req.protocol || 'http';
  const host = req.get('host') || 'localhost:7000';
  return `${protocol}://${host}`;
}
