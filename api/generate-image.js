// AI Image Generation - Cloudflare / HuggingFace
export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { prompt, provider = 'cloudflare' } = req.body;

  if (!prompt) {
    return res.status(400).json({ error: 'Prompt is required' });
  }

  try {
    let imageUrl;

    if (provider === 'cloudflare') {
      // Cloudflare Workers AI
      const response = await fetch(
        `https://api.cloudflare.com/client/v4/accounts/${process.env.CLOUDFLARE_ACCOUNT_ID}/ai/run/@cf/stabilityai/stable-diffusion-xl-base-1.0`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${process.env.CLOUDFLARE_API_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ prompt })
        }
      );

      if (!response.ok) throw new Error('Cloudflare generation failed');
      
      const buffer = await response.arrayBuffer();
      const base64 = Buffer.from(buffer).toString('base64');
      imageUrl = `data:image/png;base64,${base64}`;
    } else {
      // HuggingFace Inference API
      const response = await fetch(
        'https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0',
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${process.env.HF_TOKEN}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ inputs: prompt })
        }
      );

      if (!response.ok) throw new Error('HuggingFace generation failed');
      
      const buffer = await response.arrayBuffer();
      const base64 = Buffer.from(buffer).toString('base64');
      imageUrl = `data:image/png;base64,${base64}`;
    }

    res.status(200).json({ imageUrl, provider });
  } catch (error) {
    console.error('Image Generation Error:', error);
    res.status(500).json({ error: error.message });
  }
}
