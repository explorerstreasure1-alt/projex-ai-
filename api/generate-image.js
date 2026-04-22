// AI Image Generation - Cloudflare / HuggingFace
export default async function handler(req, res) {
  // Add CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { prompt, provider = 'cloudflare' } = req.body;

  // Request validation
  if (!prompt || typeof prompt !== 'string') {
    return res.status(400).json({ error: 'Prompt is required and must be a string' });
  }

  if (prompt.length > 500) {
    return res.status(400).json({ error: 'Prompt is too long (max 500 characters)' });
  }

  if (!['cloudflare', 'huggingface'].includes(provider)) {
    return res.status(400).json({ error: 'Invalid provider. Use "cloudflare" or "huggingface"' });
  }

  try {
    let imageUrl;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 60000); // 60 second timeout for image generation

    if (provider === 'cloudflare') {
      if (!process.env.CLOUDFLARE_API_KEY || !process.env.CLOUDFLARE_ACCOUNT_ID) {
        console.warn('Cloudflare credentials not configured, using demo mode');
        // Demo mode: Use placeholder image service
        imageUrl = `https://placehold.co/512x512/1a1a2e/fff?text=${encodeURIComponent(prompt.substring(0, 30))}`;
        res.status(200).json({
          success: true,
          imageUrl,
          provider: 'demo',
          demo: true
        });
        return;
      }

      // Cloudflare Workers AI
      const response = await fetch(
        `https://api.cloudflare.com/client/v4/accounts/${process.env.CLOUDFLARE_ACCOUNT_ID}/ai/run/@cf/stabilityai/stable-diffusion-xl-base-1.0`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${process.env.CLOUDFLARE_API_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ prompt }),
          signal: controller.signal
        }
      );

      clearTimeout(timeout);

      if (!response.ok) {
        const error = await response.json();
        console.error('Cloudflare Error:', error);
        throw new Error(error.errors?.[0]?.message || 'Cloudflare generation failed');
      }

      const buffer = await response.arrayBuffer();
      const base64 = Buffer.from(buffer).toString('base64');
      imageUrl = `data:image/png;base64,${base64}`;
    } else {
      if (!process.env.HF_TOKEN) {
        console.warn('HuggingFace token not configured, using demo mode');
        // Demo mode: Use placeholder image service
        imageUrl = `https://placehold.co/512x512/1a1a2e/fff?text=${encodeURIComponent(prompt.substring(0, 30))}`;
        res.status(200).json({
          success: true,
          imageUrl,
          provider: 'demo',
          demo: true
        });
        return;
      }

      // HuggingFace Inference API
      const response = await fetch(
        'https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0',
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${process.env.HF_TOKEN}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ inputs: prompt }),
          signal: controller.signal
        }
      );

      clearTimeout(timeout);

      if (!response.ok) {
        const error = await response.text();
        console.error('HuggingFace Error:', error);
        throw new Error('HuggingFace generation failed');
      }

      const buffer = await response.arrayBuffer();
      const base64 = Buffer.from(buffer).toString('base64');
      imageUrl = `data:image/png;base64,${base64}`;
    }

    res.status(200).json({
      success: true,
      imageUrl,
      provider
    });
  } catch (error) {
    console.error('Image Generation Error:', error);

    if (error.name === 'AbortError') {
      return res.status(504).json({ error: 'Request timeout' });
    }

    res.status(500).json({
      success: false,
      error: error.message || 'Internal server error'
    });
  }
}
