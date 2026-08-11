const ALLOWED = new Set([
  "gemini-2.5-flash:generateContent",
  "gemini-2.5-flash-image:generateContent",
]);

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response("Not found", { status: 404 });
    }

    const url = new URL(request.url);
    const match = url.pathname.match(/^\/v1beta\/models\/([^/]+)$/);
    if (!match || !ALLOWED.has(match[1])) {
      return new Response("Not found", { status: 404 });
    }

    const ip = request.headers.get("cf-connecting-ip") ?? "unknown";
    const { success } = await env.RATE_LIMITER.limit({ key: ip });
    if (!success) {
      return new Response(JSON.stringify({ error: "rate_limited" }), {
        status: 429,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body = await request.arrayBuffer();
    if (body.byteLength > 2_000_000) {
      return new Response("Payload too large", { status: 413 });
    }

    const upstream = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${match[1]}?key=${env.GEMINI_API_KEY}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body,
      }
    );

    return new Response(upstream.body, {
      status: upstream.status,
      headers: { "Content-Type": "application/json" },
    });
  },
};
