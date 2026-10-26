module.exports = {
  actions: {
    async call({ url, method = 'POST', body }) {
      if (!/^https?:\/\//i.test(url)) throw new Error('a URL precisa começar com http:// ou https://');
      const isJson = body && /^\s*[[{]/.test(body);
      const res = await fetch(url, {
        method,
        headers: body ? { 'content-type': isJson ? 'application/json' : 'text/plain; charset=utf-8' } : undefined,
        body: method === 'GET' ? undefined : body || undefined,
        signal: AbortSignal.timeout(8000),
      });
      if (!res.ok) throw new Error(`o servidor respondeu ${res.status} ${res.statusText}`);
    },
  },
};
