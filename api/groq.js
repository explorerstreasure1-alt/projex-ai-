// GROQ API Integration - Serverless Function
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

  const { prompt, model = 'llama-3.3-70b-versatile', system } = req.body;

  // Request validation
  if (!prompt || typeof prompt !== 'string') {
    return res.status(400).json({ error: 'Prompt is required and must be a string' });
  }

  if (prompt.length > 10000) {
    return res.status(400).json({ error: 'Prompt is too long (max 10000 characters)' });
  }

  if (!process.env.GROQ_API_KEY) {
    console.error('GROQ_API_KEY not configured');
    return res.status(500).json({ error: 'Server configuration error' });
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 30000); // 30 second timeout

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.GROQ_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model,
        messages: [
          ...(system ? [{ role: 'system', content: system }] : []),
          { role: 'user', content: prompt }
        ],
        temperature: 0.7,
        max_tokens: 4096
      }),
      signal: controller.signal
    });

    clearTimeout(timeout);

    if (!response.ok) {
      const error = await response.json();
      console.error('GROQ API Error:', error);
      throw new Error(error.error?.message || 'GROQ API error');
    }

    const data = await response.json();

    res.status(200).json({
      success: true,
      content: data.choices[0].message.content,
      usage: data.usage,
      model: data.model
    });
  } catch (error) {
    console.error('GROQ Error:', error);

    if (error.name === 'AbortError') {
      return res.status(504).json({ error: 'Request timeout' });
    }

    res.status(500).json({
      success: false,
      error: error.message || 'Internal server error'
    });
  }
}
